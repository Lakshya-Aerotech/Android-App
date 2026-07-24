import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS } from '../config/constants';
import { phonePeConfig } from '../phonepe/phonepe.config';
import { PaymentService } from '../services/payment.service';
import { PhonePeService } from '../phonepe/phonepe.service';
import { PaymentValidator } from '../validators/payment.validator';
import { PaymentStatus } from '../models/payment.model';
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
  static async createPayment(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const { bookingId, userId, amount, mobileNumber } = req.body;

      // 1. Validate incoming request payload
      const validation = PaymentValidator.validateCreatePayment({ bookingId, userId, amount });
      if (!validation.isValid) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: validation.errors.join(' '),
          data: null,
        });
      }

      // 2. Create Pending Payment document via PaymentService
      const pendingPayment = await PaymentService.createPendingPayment({
        bookingId,
        userId,
        amount,
      });

      // 3. Prepare PhonePe API Pay Request Payload (Amount in paise)
      const phonePePayload: PhonePePayRequestPayload = {
        merchantId: phonePeConfig.merchantId,
        merchantTransactionId: pendingPayment.merchantTransactionId,
        merchantUserId: userId,
        amount: Math.round(amount * 100),
        redirectUrl: phonePeConfig.callbackUrl,
        redirectMode: 'REDIRECT',
        callbackUrl: phonePeConfig.callbackUrl,
        mobileNumber: mobileNumber || '9999999999',
        paymentInstrument: {
          type: PhonePePaymentInstrumentType.PAY_PAGE,
        },
      };

      // 4. Initiate PhonePe gateway transaction
      const phonePeResponse = await PhonePeService.initiatePayTransaction(phonePePayload);

      // 5. Extract payment URL and redirect info
      const redirectInfo = phonePeResponse.data?.instrumentResponse?.redirectInfo;
      const paymentUrl = redirectInfo?.url || phonePeResponse.data?.instrumentResponse?.intentUrl || '';

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
        console.error('[PaymentController] PhonePe API Error Response:', error.response.data);
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: error.response.data.message || error.response.data.code || 'PhonePe gateway request failed.',
          data: error.response.data,
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
  static async checkStatus(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
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

      // 2. Query PhonePe API for current status
      const statusResponse = await PhonePeService.checkTransactionStatus(
        phonePeConfig.merchantId,
        merchantTransactionId
      );

      // 3. Reconciliation check against Firestore state
      const localPayment = await PaymentService.getPaymentByMerchantTransactionId(merchantTransactionId);
      if (localPayment && localPayment.status === PaymentStatus.PENDING) {
        const gatewayState = statusResponse.data?.paymentState || statusResponse.code;
        const mappedStatus = mapPhonePeStateToPaymentStatus(gatewayState);

        if (mappedStatus !== PaymentStatus.PENDING) {
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

      // 4. Return gateway response
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Transaction status retrieved successfully.',
        data: statusResponse,
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
}
