import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS } from '../config/constants';
import { phonePeConfig } from '../phonepe/phonepe.config';
import { PaymentService } from '../services/payment.service';
import { PhonePeService } from '../phonepe/phonepe.service';
import { PaymentValidator } from '../validators/payment.validator';
import { PaymentStatus } from '../models/payment.model';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { config } from '../config';
import {
  PhonePePayRequestPayload,
  PhonePePaymentInstrumentType,
  PhonePeDecodedWebhookResponse,
} from '../phonepe/phonepe.types';

/**
 * Maps PhonePe gateway response codes / payment state to internal PaymentStatus enum.
 */
function mapPhonePeStateToPaymentStatus(codeOrState?: string): PaymentStatus {
  if (!codeOrState) return PaymentStatus.FAILED;
  const upper = codeOrState.toUpperCase();
  if (upper === 'PAYMENT_SUCCESS' || upper === 'COMPLETED' || upper === 'SUCCESS') {
    return PaymentStatus.SUCCESS;
  }
  if (upper === 'PAYMENT_PENDING' || upper === 'PENDING') {
    return PaymentStatus.PENDING;
  }
  if (upper === 'PAYMENT_DECLINED' || upper === 'CANCELLED' || upper === 'PAYMENT_CANCELLED') {
    return PaymentStatus.CANCELLED;
  }
  return PaymentStatus.FAILED;
}

export class PaymentController {
  /**
   * POST /api/payment/create
   * Initiates a new payment transaction with PhonePe PG.
   */
  static async createPayment(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const { bookingId } = req.body;
      const authenticatedUser = req.user!;

      // Booking ownership and payable amount are validated from Firestore.
      const authorizedPayment = await PaymentService.createPendingPaymentForBooking(
        bookingId,
        authenticatedUser.uid,
        authenticatedUser.role
      );
      const pendingPayment = authorizedPayment.payment;

      // 3. Prepare PhonePe API Pay Request Payload (Amount in paise)
      const phonePePayload: PhonePePayRequestPayload = {
        merchantId: phonePeConfig.merchantId,
        merchantTransactionId: pendingPayment.merchantTransactionId,
        merchantUserId: authenticatedUser.uid,
        amount: Math.round(authorizedPayment.amount * 100),
        redirectUrl: `${phonePeConfig.callbackUrl.replace('/webhook', '/redirect')}?merchantTransactionId=${pendingPayment.merchantTransactionId}`,
        redirectMode: 'REDIRECT',
        callbackUrl: phonePeConfig.callbackUrl,
        mobileNumber: authorizedPayment.mobileNumber,
        paymentInstrument: {
          type: PhonePePaymentInstrumentType.PAY_PAGE,
        },
      };

      // 4. Initiate PhonePe gateway transaction
      let phonePeResponse;
      try {
        phonePeResponse = await PhonePeService.initiatePayTransaction(phonePePayload);
      } catch (gatewayError) {
        await PaymentService.processPaymentResult(
          pendingPayment.merchantTransactionId,
          PaymentStatus.FAILED,
          null,
          null,
          'Payment gateway initiation failed.'
        );
        throw gatewayError;
      }

      // 5. Extract payment URL and redirect info
      const redirectInfo = phonePeResponse.data?.instrumentResponse?.redirectInfo;
      const paymentUrl = redirectInfo?.url || phonePeResponse.data?.instrumentResponse?.intentUrl || '';
      if (!paymentUrl) {
        await PaymentService.processPaymentResult(
          pendingPayment.merchantTransactionId,
          PaymentStatus.FAILED,
          null,
          null,
          'Payment gateway did not provide a checkout URL.'
        );
        return res.status(HTTP_STATUS.BAD_GATEWAY).json({
          success: false,
          message: 'Payment gateway did not provide a checkout URL. Please try again.',
          data: null,
          requestId: req.id,
        });
      }

      // 6. Return standardized JSON response
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Payment initiated successfully.',
        data: {
          success: true,
          merchantTransactionId: pendingPayment.merchantTransactionId,
          paymentUrl,
          paymentToken: paymentUrl,
          status: PaymentStatus.PENDING,
        },
      });
    } catch (error: any) {
      if (error.response?.data) {
        console.error('[PaymentController] PhonePe request failed:', error.response.data.code || error.message);
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Payment gateway request failed. Please try again.',
          data: null,
          requestId: req.id,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/payment/status/:merchantTransactionId
   * Queries PhonePe API for status of a transaction and reconciles with Firestore if pending.
   */
  static async checkStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const { merchantTransactionId } = req.params;

      // 1. Validate transaction ID parameter
      const validation = PaymentValidator.validateMerchantTransactionId(merchantTransactionId);
      if (!validation.isValid) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: validation.errors.join(' '),
          data: null,
        });
      }

      const localPayment = await PaymentService.getPaymentByMerchantTransactionId(merchantTransactionId);
      if (!localPayment) {
        return res.status(HTTP_STATUS.NOT_FOUND).json({
          success: false,
          message: 'Payment transaction not found.',
          data: null,
        });
      }

      const mayManagePayment =
        req.user?.uid === localPayment.userId ||
        req.user?.role === 'admin' ||
        req.user?.role === 'operations';
      if (!mayManagePayment) {
        return res.status(HTTP_STATUS.FORBIDDEN).json({
          success: false,
          message: 'You are not allowed to access this payment.',
          data: null,
        });
      }

      if (localPayment.status === PaymentStatus.SUCCESS ||
          localPayment.status === PaymentStatus.REFUNDED) {
        return res.status(HTTP_STATUS.OK).json({
          success: true,
          message: 'Transaction status retrieved successfully.',
          data: {
            merchantTransactionId,
            paymentState: localPayment.status,
            transactionId: localPayment.transactionId,
          },
        });
      }

      // 2. Query PhonePe API for current status
      const statusResponse = await PhonePeService.checkTransactionStatus(
        phonePeConfig.merchantId,
        merchantTransactionId
      );

      // 3. Validate the gateway response before reconciling local state.
      let verifiedStatus: PaymentStatus = localPayment.status;
      let verifiedTransactionId = localPayment.transactionId;
      const gatewayData = statusResponse.data;
      if (gatewayData?.merchantId !== phonePeConfig.merchantId ||
          gatewayData?.merchantTransactionId !== merchantTransactionId ||
          (!config.paymentMocksEnabled &&
           Number(gatewayData?.amount) !== Math.round(localPayment.amount * 100))) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Gateway response did not match the payment record.',
          data: null,
        });
      }

      const gatewayState = gatewayData.paymentState || statusResponse.code;
      const mappedStatus = mapPhonePeStateToPaymentStatus(gatewayState);
      if (localPayment.status === PaymentStatus.PENDING ||
          mappedStatus === PaymentStatus.SUCCESS) {
        verifiedStatus = mappedStatus;
        verifiedTransactionId = statusResponse.data?.transactionId || null;

        if (mappedStatus !== PaymentStatus.PENDING && mappedStatus !== localPayment.status) {
          console.log(`[PaymentReconciliation] Synchronizing Firestore for ${merchantTransactionId}. Gateway status: ${mappedStatus}`);
          await PaymentService.processPaymentResult(
            merchantTransactionId,
            mappedStatus,
            statusResponse.data?.transactionId || null,
            statusResponse.data as unknown as Record<string, unknown>,
            statusResponse.data?.responseCodeDescription || statusResponse.message || null
          );
        }
      }

      // 4. Return only the normalized fields required by the app.
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Transaction status retrieved successfully.',
        data: {
          merchantTransactionId,
          paymentState: verifiedStatus,
          transactionId: verifiedTransactionId,
        },
      });
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * POST /api/payment/webhook
   * Receives incoming webhook notification from PhonePe PG, verifies signature,
   * updates Firestore payment document and booking payment fields atomically.
   */
  static async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      console.log('[PhonePeWebhook] Webhook callback received from PhonePe');

      const receivedXVerify = (req.headers['x-verify'] as string) || '';
      const base64ResponseBody = req.body.response || '';

      if (!base64ResponseBody || !receivedXVerify) {
        console.warn('[PhonePeWebhook] Missing payload or X-VERIFY header');
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Missing required webhook response payload or X-VERIFY header.',
          data: null,
        });
      }

      // 1. Verify PhonePe webhook signature
      const isValidSignature = PhonePeService.verifyWebhookSignature(base64ResponseBody, receivedXVerify);
      if (!isValidSignature) {
        console.error('[PhonePeWebhook] Webhook signature verification failed');
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Invalid webhook signature verification failed.',
          data: null,
        });
      }

      console.log('[PhonePeWebhook] Webhook signature verified successfully');

      // 2. Decode payload
      const decodedPayload = PhonePeService.decodeWebhookPayload<PhonePeDecodedWebhookResponse>(base64ResponseBody);
      const merchantTxnId = decodedPayload.data?.merchantTransactionId;
      const gatewayTxnId = decodedPayload.data?.transactionId || null;
      const responseCode = decodedPayload.code || decodedPayload.data?.responseCode;
      const mappedStatus = mapPhonePeStateToPaymentStatus(responseCode);

      if (!merchantTxnId) {
        console.error('[PhonePeWebhook] Decoded payload missing merchantTransactionId');
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Decoded webhook payload missing merchantTransactionId.',
          data: null,
        });
      }

      // 3. Check if payment exists in Firestore
      const existingPayment = await PaymentService.getPaymentByMerchantTransactionId(merchantTxnId);
      if (!existingPayment) {
        console.warn(`[PhonePeWebhook] Payment record not found in system for merchantTxnId ${merchantTxnId}`);
        return res.status(HTTP_STATUS.NOT_FOUND).json({
          success: false,
          message: `Payment transaction '${merchantTxnId}' not found in system.`,
          data: null,
        });
      }

      const webhookMerchantId = decodedPayload.data?.merchantId;
      if (webhookMerchantId !== phonePeConfig.merchantId) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Webhook merchant does not match the configured merchant.',
          data: null,
        });
      }

      const webhookAmount = Number(decodedPayload.data?.amount);
      const expectedAmountInPaise = Math.round(existingPayment.amount * 100);
      if (!Number.isFinite(webhookAmount) || webhookAmount !== expectedAmountInPaise) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Webhook amount does not match the payment record.',
          data: null,
        });
      }

      // 4. Idempotency Check: If payment is already SUCCESS, return HTTP 200 immediately
      if (existingPayment.status === PaymentStatus.SUCCESS) {
        console.log(`[PhonePeWebhook] Idempotent response: Payment ${merchantTxnId} is already SUCCESS.`);
        return res.status(HTTP_STATUS.OK).json({
          success: true,
          message: 'Webhook processed (Already in SUCCESS state).',
          data: null,
        });
      }

      // 5. Process atomic update for Payment and Booking documents in Firestore
      const result = await PaymentService.processPaymentResult(
        merchantTxnId,
        mappedStatus,
        gatewayTxnId,
        decodedPayload.data as unknown as Record<string, unknown>,
        decodedPayload.message || decodedPayload.data?.responseCodeDescription || null
      );

      if (result?.alreadyProcessed) {
        console.log(`[PhonePeWebhook] Duplicate webhook callback skipped for ${merchantTxnId}`);
      } else {
        console.log(`[PhonePeWebhook] Successfully updated Payment and Booking for ${merchantTxnId} to status ${mappedStatus}`);
      }

      // 6. Return HTTP 200
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Webhook processed successfully.',
        data: null,
      });
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * GET/POST /api/payment/redirect
   * Handles browser redirect from PhonePe check-out page. Renders a clean success/failure webpage
   * which is captured by the Flutter app's webview to transition screens.
   */
  static async handleRedirect(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      res.setHeader('Content-Type', 'text/html');
      return res.status(HTTP_STATUS.OK).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Status</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px 20px; background-color: #f7f9fa; margin: 0; display: flex; align-items: center; justify-content: center; height: 80vh; }
            .card { max-width: 420px; width: 100%; background: white; padding: 40px 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); box-sizing: border-box; }
            .icon-circle { width: 72px; height: 72px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px auto; }
            .status-circle { background-color: #e8f0fe; color: #1a73e8; }
            h1 { font-size: 24px; margin: 0 0 12px 0; color: #1a1f36; }
            p { font-size: 16px; line-height: 24px; color: #4f566b; margin: 0 0 24px 0; }
            .details { background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: left; margin-bottom: 24px; font-size: 14px; border: 1px solid #e3e8ee; }
            .details-row { display: flex; justify-content: space-between; margin-bottom: 8px; }
            .details-row:last-child { margin-bottom: 0; }
            .details-label { color: #697386; }
            .details-value { font-weight: 600; color: #3c4257; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon-circle status-circle">
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="9"></circle>
                <path d="M12 7v5l3 2"></path>
              </svg>
            </div>
            <h1>Verifying payment</h1>
            <p>Return to the app while we securely verify the payment with the gateway.</p>
            <p style="font-size: 13px; color: #8792a2; margin: 24px 0 0 0;">Do not make another payment until verification finishes.</p>
          </div>
        </body>
        </html>
      `);
    } catch (error: any) {
      next(error);
    }
  }
}
