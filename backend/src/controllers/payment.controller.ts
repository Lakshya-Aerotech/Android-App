import { Request, Response, NextFunction } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../firebase';
import { HTTP_STATUS } from '../config/constants';
import { cashfreeConfig } from '../cashfree/cashfree.config';
import { CashfreeService } from '../cashfree/cashfree.service';
import { PaymentService } from '../services/payment.service';
import { PaymentValidator } from '../validators/payment.validator';
import { PaymentStatus, PaymentGateway, PaymentMode } from '../models/payment.model';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { CashfreeCreateOrderPayload } from '../cashfree/cashfree.types';

/**
 * Maps Cashfree gateway status to internal PaymentStatus enum.
 */
function mapCashfreeStateToPaymentStatus(state?: string): PaymentStatus {
  if (!state) return PaymentStatus.FAILED;
  const upper = state.toUpperCase();
  if (upper === 'PAID' || upper === 'SUCCESS' || upper === 'COMPLETED') {
    return PaymentStatus.SUCCESS;
  }
  if (upper === 'ACTIVE' || upper === 'PENDING') {
    return PaymentStatus.PENDING;
  }
  if (upper === 'USER_DROPPED' || upper === 'CANCELLED') {
    return PaymentStatus.CANCELLED;
  }
  return PaymentStatus.FAILED;
}

export class PaymentController {
  /**
   * POST /api/payment/create-order (or /api/payment/create)
   * Creates a Cashfree payment order and pending Firestore payment document.
   */
  static async createPayment(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const authReq = req as AuthenticatedRequest;
      const userId = authReq.user?.uid || req.body.userId;
      const { bookingId, amount, mobileNumber, customerEmail, customerName } = req.body;

      if (!userId) {
        return res.status(HTTP_STATUS.UNAUTHORIZED).json({
          success: false,
          message: 'Unauthorized: User authentication required.',
          data: null,
        });
      }

      // 1. Validate basic input payload
      const validation = PaymentValidator.validateCreatePayment({ bookingId, userId, amount });
      if (!validation.isValid) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: validation.errors.join(' '),
          data: null,
        });
      }

      // 2. Security Validation: Verify booking ownership and calculate exact amount from Firestore
      const { calculatedAmount } = await PaymentService.validateAndCalculateBookingAmount(
        bookingId,
        userId,
        amount
      );

      // 3. Create Pending Payment document in Firestore
      const pendingPayment = await PaymentService.createPendingPayment({
        bookingId,
        userId,
        amount: calculatedAmount,
        gateway: PaymentGateway.CASHFREE,
        paymentMode: PaymentMode.CASHFREE,
      });

      const rawHost = req.headers.host || '192.168.1.3:3000';
      const host = rawHost.replace(/^https?:\/\//i, '');
      const dynamicReturnUrl = `http://${host}/api/payment/redirect?order_id={order_id}`;

      // 4. Prepare Cashfree Create Order Payload
      const orderPayload: CashfreeCreateOrderPayload = {
        order_id: pendingPayment.merchantTransactionId,
        order_amount: calculatedAmount,
        order_currency: 'INR',
        customer_details: {
          customer_id: userId.replace(/[^a-zA-Z0-9_-]/g, '_'),
          customer_phone: (mobileNumber || '9999999999').replace(/[^0-9]/g, '').slice(-10) || '9999999999',
          customer_email: customerEmail || `${userId.toLowerCase()}@lakshya.app`,
          customer_name: customerName || authReq.user?.name || 'Valued Customer',
        },
        order_meta: {
          return_url: dynamicReturnUrl,
        },
        order_note: `Lakshya Aerotech Drone Spraying Booking ${bookingId}`,
      };

      // 5. Initiate Cashfree gateway order
      const cfOrder = await CashfreeService.createOrder(orderPayload);

      // 6. Construct Cashfree Payment URL via Official Cashfree JS SDK v3 Runner
      let paymentUrl = `http://${host}/api/payment/cashfree-checkout?session_id=${cfOrder.payment_session_id}&env=${cashfreeConfig.environment}`;

      if (
        cashfreeConfig.appId === 'TEST_APP_ID' ||
        cashfreeConfig.secretKey === 'TEST_SECRET_KEY' ||
        !cashfreeConfig.appId ||
        cfOrder.payment_session_id.startsWith('session_mock_')
      ) {
        paymentUrl = `http://${host}/api/payment/mock-checkout?order_id=${pendingPayment.merchantTransactionId}&amount=${calculatedAmount}`;
      }

      // 7. Return standardized JSON response with payment_session_id for Flutter SDK / Webview
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Cashfree order created successfully.',
        data: {
          success: true,
          payment_session_id: cfOrder.payment_session_id,
          order_id: pendingPayment.merchantTransactionId,
          merchantTransactionId: pendingPayment.merchantTransactionId,
          cf_order_id: cfOrder.cf_order_id,
          paymentUrl,
          status: PaymentStatus.PENDING,
          environment: cashfreeConfig.environment,
        },
      });
    } catch (error: any) {
      if (error.response?.data) {
        console.error('[PaymentController] Cashfree API Error Response:', error.response.data);
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: error.response.data.message || error.response.data.code || 'Cashfree gateway request failed.',
          data: error.response.data,
          requestId: req.id,
        });
      }
      next(error);
    }
  }

  /**
   * GET /api/payment/status/:orderId
   * POST /api/payment/verify
   * Queries Cashfree API for status of an order and reconciles with Firestore.
   */
  static async checkStatus(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const orderId = req.params.orderId || req.params.merchantTransactionId || req.body.orderId || req.body.order_id;

      // 1. Validate order ID parameter
      const validation = PaymentValidator.validateMerchantTransactionId(orderId);
      if (!validation.isValid) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: validation.errors.join(' '),
          data: null,
        });
      }

      // 2. Query Cashfree API for current order status
      const cfOrder = await CashfreeService.getOrderStatus(orderId);

      // 3. Reconciliation check against Firestore state
      const localPayment = await PaymentService.getPaymentByMerchantTransactionId(orderId);
      if (localPayment && localPayment.status === PaymentStatus.PENDING) {
        const mappedStatus = mapCashfreeStateToPaymentStatus(cfOrder.order_status);

        if (mappedStatus !== PaymentStatus.PENDING) {
          console.log(`[PaymentReconciliation] Synchronizing Firestore for Order ${orderId}. Gateway status: ${mappedStatus}`);
          await PaymentService.processPaymentResult(
            orderId,
            mappedStatus,
            cfOrder.cf_order_id || null,
            cfOrder as unknown as Record<string, unknown>,
            cfOrder.order_status !== 'PAID' ? `Order status: ${cfOrder.order_status}` : null
          );
        }
      }

      // 4. Return gateway response
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: 'Cashfree order status retrieved successfully.',
        data: {
          order_id: cfOrder.order_id,
          cf_order_id: cfOrder.cf_order_id,
          order_status: cfOrder.order_status,
          order_amount: cfOrder.order_amount,
          status: mapCashfreeStateToPaymentStatus(cfOrder.order_status),
        },
      });
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * POST /api/payment/webhook
   * Receives incoming webhook notifications from Cashfree PG, verifies signature,
   * updates Firestore payment document and booking payment fields atomically.
   */
  static async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      console.log('[CashfreeWebhook] Webhook callback received from Cashfree');

      const signature = (req.headers['x-webhook-signature'] as string) || (req.headers['x-verify'] as string) || '';
      const timestamp = (req.headers['x-webhook-timestamp'] as string) || '';
      const rawBody = JSON.stringify(req.body);

      // 1. Verify Cashfree webhook signature
      const isValidSignature = CashfreeService.verifyWebhookSignature(rawBody, timestamp, signature);
      if (!isValidSignature) {
        console.error('[CashfreeWebhook] Webhook signature verification failed');
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Invalid webhook signature.',
          data: null,
        });
      }

      console.log('[CashfreeWebhook] Webhook signature verified successfully');

      // 2. Extract order payload from webhook
      const webhookPayload = req.body;
      const orderId = webhookPayload.data?.order?.order_id || webhookPayload.order_id;
      const cfPaymentId = webhookPayload.data?.payment?.cf_payment_id || webhookPayload.cf_payment_id || null;
      const paymentStatusStr = webhookPayload.data?.payment?.payment_status || webhookPayload.txStatus || webhookPayload.data?.order?.order_status;
      const mappedStatus = mapCashfreeStateToPaymentStatus(paymentStatusStr);

      if (!orderId) {
        console.error('[CashfreeWebhook] Payload missing order_id');
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Webhook payload missing order_id.',
          data: null,
        });
      }

      // 3. Check if payment exists in Firestore
      const existingPayment = await PaymentService.getPaymentByMerchantTransactionId(orderId);
      if (!existingPayment) {
        console.warn(`[CashfreeWebhook] Payment record not found in system for order ${orderId}`);
        return res.status(HTTP_STATUS.NOT_FOUND).json({
          success: false,
          message: `Payment transaction '${orderId}' not found in system.`,
          data: null,
        });
      }

      // 4. Idempotency Check: If payment is already SUCCESS, return HTTP 200 immediately
      if (existingPayment.status === PaymentStatus.SUCCESS) {
        console.log(`[CashfreeWebhook] Idempotent response: Payment ${orderId} is already in SUCCESS state.`);
        return res.status(HTTP_STATUS.OK).json({
          success: true,
          message: 'Webhook processed (Already in SUCCESS state).',
          data: null,
        });
      }

      // 5. Process atomic update for Payment and Booking documents in Firestore
      const result = await PaymentService.processPaymentResult(
        orderId,
        mappedStatus,
        cfPaymentId,
        webhookPayload as Record<string, unknown>,
        mappedStatus !== PaymentStatus.SUCCESS ? `Cashfree status: ${paymentStatusStr}` : null
      );

      if (result?.alreadyProcessed) {
        console.log(`[CashfreeWebhook] Duplicate webhook callback skipped for ${orderId}`);
      } else {
        console.log(`[CashfreeWebhook] Successfully updated Payment and Booking for ${orderId} to status ${mappedStatus}`);
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
   * Handles browser return redirect from Cashfree checkout page.
   */
  static async handleRedirect(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const orderId = (req.query.order_id as string) || (req.query.merchantTransactionId as string) || '';

      console.log(`[CashfreeRedirect] Redirect hit for Order ID: ${orderId}`);

      let isSuccess = false;
      if (orderId) {
        try {
          const cfOrder = await CashfreeService.getOrderStatus(orderId);
          isSuccess = cfOrder.order_status === 'PAID';
          if (isSuccess) {
            console.log(`[CashfreeRedirect] Order ${orderId} is PAID. Updating Firestore status to SUCCESS and booking status to pending...`);
            await PaymentService.processPaymentResult(
              orderId,
              PaymentStatus.SUCCESS,
              cfOrder.cf_order_id ? String(cfOrder.cf_order_id) : `CF_${Date.now()}`,
              { gateway: 'CASHFREE', raw: cfOrder }
            );
          }
        } catch (e) {
          console.error(`[CashfreeRedirect] Error processing payment result for ${orderId}:`, e);
          isSuccess = false;
        }
      }

      res.setHeader('Content-Type', 'text/html');
      return res.status(HTTP_STATUS.OK).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Cashfree Payment Status</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px 20px; background-color: #f7f9fa; margin: 0; display: flex; align-items: center; justify-content: center; height: 80vh; }
            .card { max-width: 420px; width: 100%; background: white; padding: 40px 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); box-sizing: border-box; }
            .icon-circle { width: 72px; height: 72px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px auto; }
            .success-circle { background-color: #e8f5e9; color: #4caf50; }
            .error-circle { background-color: #ffebee; color: #f44336; }
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
            <div class="icon-circle ${isSuccess ? 'success-circle' : 'error-circle'}">
              ${isSuccess ? `
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              ` : `
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              `}
            </div>
            <h1>Payment ${isSuccess ? 'Successful' : 'Processing / Pending'}</h1>
            <p>${isSuccess ? 'Your payment has been successfully processed by Cashfree.' : 'Your payment status is being verified.'}</p>
            
            ${orderId ? `
              <div class="details">
                <div class="details-row">
                  <span class="details-label">Order ID:</span>
                  <span class="details-value">${orderId}</span>
                </div>
              </div>
            ` : ''}

            <p style="font-size: 13px; color: #8792a2; margin: 24px 0 0 0;">You can close this window to return to the app.</p>
          </div>
        </body>
        </html>
      `);
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * POST /api/payment/confirm-cash
   * Authenticated Admin / Operations endpoint to confirm cash payment collection for a booking.
   */
  static async confirmCashPayment(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const authReq = req as AuthenticatedRequest;
      const userRole = authReq.user?.role;
      const operatorUid = authReq.user?.uid || 'UNKNOWN_OPERATOR';

      if (userRole !== 'admin' && userRole !== 'operations' && userRole !== 'pilot' && userRole !== 'externalPilot') {
        return res.status(HTTP_STATUS.FORBIDDEN).json({
          success: false,
          message: 'Forbidden: Only Administrator, Operations, or Pilot roles can confirm cash payments.',
          data: null,
        });
      }

      const { bookingId, remarks } = req.body;
      if (!bookingId) {
        return res.status(HTTP_STATUS.BAD_REQUEST).json({
          success: false,
          message: 'Booking ID is required.',
          data: null,
        });
      }

      const bookingRef = db.collection('bookings').doc(bookingId);
      
      const result = await db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
          throw new Error(`Booking '${bookingId}' not found.`);
        }

        const bookingData = bookingDoc.data() || {};
        if (bookingData.paymentStatus === PaymentStatus.SUCCESS || bookingData.paymentStatus === 'PAID') {
          return { alreadyPaid: true, bookingData };
        }

        const now = FieldValue.serverTimestamp();
        const paymentDocRef = db.collection('payments').doc();
        const paymentId = paymentDocRef.id;
        const merchantTransactionId = `CASH_${Date.now()}_${bookingId}`;
        const amount = bookingData.payableAmount || bookingData.totalPrice || bookingData.amount || 0;

        // 1. Create Payment Document for Cash Transaction
        transaction.set(paymentDocRef, {
          paymentId,
          bookingId,
          userId: bookingData.farmerUid || bookingData.userId || '',
          merchantTransactionId,
          transactionId: `CASH_TXN_${Date.now()}`,
          amount,
          currency: 'INR',
          status: PaymentStatus.SUCCESS,
          paymentMode: PaymentMode.CASH,
          gateway: PaymentGateway.CASHFREE,
          gatewayResponse: { confirmedBy: operatorUid, remarks: remarks || 'Cash collected by staff' },
          createdAt: now,
          updatedAt: now,
          completedAt: now,
          failureReason: null,
          metadata: { cashCollectedBy: operatorUid },
        });

        // 2. Update Booking Document
        transaction.update(bookingRef, {
          paymentStatus: PaymentStatus.SUCCESS,
          paymentMethod: PaymentMode.CASH,
          paymentId,
          cashCollected: true,
          cashCollectedBy: operatorUid,
          cashCollectedAt: now,
          paymentCompletedAt: now,
          updatedAt: now,
        });

        return { alreadyPaid: false, amount };
      });

      return res.status(HTTP_STATUS.OK).json({
        success: true,
        message: result.alreadyPaid ? 'Cash payment already confirmed.' : 'Cash payment confirmed successfully.',
        data: result,
      });
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * GET /api/payment/mock-checkout
   * Interactive Cashfree Payment Gateway Simulator for local development & mock testing.
   */
  static async handleMockCheckout(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const orderId = (req.query.order_id as string) || '';
      const amount = (req.query.amount as string) || '500';

      const action = (req.query.action as string) || '';
      if (action === 'success' && orderId) {
        await PaymentService.processPaymentResult(
          orderId,
          PaymentStatus.SUCCESS,
          `CF_MOCK_PAY_${Date.now()}`,
          { gateway: 'CASHFREE_MOCK', mode: 'UPI' }
        );
        res.setHeader('Content-Type', 'text/html');
        return res.status(HTTP_STATUS.OK).send(`
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Cashfree Payment Success</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px 20px; background-color: #e8f5e9; margin: 0; display: flex; align-items: center; justify-content: center; height: 80vh; }
              .card { max-width: 420px; width: 100%; background: white; padding: 40px 30px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); box-sizing: border-box; }
              .icon-circle { width: 72px; height: 72px; border-radius: 50%; background-color: #e8f5e9; color: #4caf50; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px auto; }
              h1 { font-size: 24px; color: #1a1f36; margin: 0 0 12px 0; }
              p { color: #4f566b; line-height: 24px; margin-bottom: 24px; }
            </style>
          </head>
          <body>
            <div class="card">
              <div class="icon-circle">
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              <h1>Payment Successful</h1>
              <p>Your payment of ₹${amount} was successfully verified by Cashfree Gateway.</p>
            </div>
            <script>
              setTimeout(() => {
                window.location.href = "/api/payment/redirect?status=SUCCESS&order_id=${orderId}";
              }, 1200);
            </script>
          </body>
          </html>
        `);
      } else if (action === 'cancel' && orderId) {
        await PaymentService.processPaymentResult(
          orderId,
          PaymentStatus.CANCELLED,
          null,
          { gateway: 'CASHFREE_MOCK', mode: 'CANCELLED' },
          'User cancelled payment'
        );
        res.setHeader('Content-Type', 'text/html');
        return res.status(HTTP_STATUS.OK).send(`
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Cashfree Payment Cancelled</title>
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px 20px; background-color: #ffebee; margin: 0; display: flex; align-items: center; justify-content: center; height: 80vh; }
              .card { max-width: 420px; width: 100%; background: white; padding: 40px 30px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); box-sizing: border-box; }
              .icon-circle { width: 72px; height: 72px; border-radius: 50%; background-color: #ffebee; color: #f44336; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px auto; }
              h1 { font-size: 24px; color: #1a1f36; margin: 0 0 12px 0; }
              p { color: #4f566b; line-height: 24px; margin-bottom: 24px; }
            </style>
          </head>
          <body>
            <div class="card">
              <div class="icon-circle">
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </div>
              <h1>Payment Cancelled</h1>
              <p>Payment transaction was cancelled by user.</p>
            </div>
            <script>
              setTimeout(() => {
                window.location.href = "/api/payment/redirect?status=CANCELLED&order_id=${orderId}";
              }, 1200);
            </script>
          </body>
          </html>
        `);
      }

      res.setHeader('Content-Type', 'text/html');
      return res.status(HTTP_STATUS.OK).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Cashfree Gateway Simulator</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 24px 16px; background-color: #f4f6f8; margin: 0; display: flex; align-items: center; justify-content: center; min-height: 90vh; }
            .card { max-width: 400px; width: 100%; background: white; padding: 32px 24px; border-radius: 16px; box-shadow: 0 4px 24px rgba(0,0,0,0.1); box-sizing: border-box; text-align: center; }
            .logo-badge { background: #7b2cbf; color: white; padding: 8px 16px; border-radius: 20px; font-weight: bold; font-size: 14px; display: inline-block; margin-bottom: 20px; }
            h2 { margin: 0 0 8px 0; color: #1a1f36; font-size: 22px; }
            .amount { font-size: 32px; font-weight: 800; color: #101828; margin: 16px 0 24px 0; }
            .btn { display: block; width: 100%; padding: 16px; margin-bottom: 12px; border-radius: 12px; font-size: 16px; font-weight: 700; text-decoration: none; border: none; cursor: pointer; box-sizing: border-box; }
            .btn-success { background-color: #00c853; color: white; }
            .btn-cancel { background-color: #f44336; color: white; }
            .info-box { background: #f8f9fa; padding: 12px; border-radius: 8px; font-size: 13px; color: #666; margin-bottom: 20px; border: 1px solid #e0e0e0; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="logo-badge">Cashfree Payments (Dev Sandbox)</div>
            <h2>Drone Spraying Booking</h2>
            <div class="amount">₹${amount}</div>
            
            <div class="info-box">
              <strong>Order ID:</strong> ${orderId}
            </div>

            <a href="/api/payment/mock-checkout?order_id=${orderId}&amount=${amount}&action=success" class="btn btn-success">
              ✓ SIMULATE SUCCESSFUL PAYMENT (UPI)
            </a>
            
            <a href="/api/payment/mock-checkout?order_id=${orderId}&amount=${amount}&action=cancel" class="btn btn-cancel">
              ✕ CANCEL / FAIL PAYMENT
            </a>
          </div>
        </body>
        </html>
      `);
    } catch (error: any) {
      next(error);
    }
  }

  /**
   * GET /api/payment/cashfree-checkout
   * Official Cashfree Web Checkout SDK v3 Runner for mobile WebViews & browsers.
   */
  static async handleCashfreeCheckout(req: Request, res: Response, next: NextFunction): Promise<Response | void> {
    try {
      const sessionId = (req.query.session_id as string) || '';
      const env = (req.query.env as string)?.toUpperCase() === 'PRODUCTION' ? 'production' : 'sandbox';

      res.setHeader('Content-Type', 'text/html');
      return res.status(HTTP_STATUS.OK).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Cashfree Secure Checkout</title>
          <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
          <style>
            body { margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #f8f9fa; display: flex; align-items: center; justify-content: center; height: 100vh; }
            .loading-box { text-align: center; background: white; padding: 32px 24px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); max-width: 320px; width: 90%; }
            .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #7b2cbf; border-radius: 50%; width: 36px; height: 36px; animation: spin 1s linear infinite; margin: 0 auto 16px auto; }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            h3 { margin: 0 0 8px 0; color: #1a1f36; font-size: 18px; }
            p { margin: 0; color: #697386; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="loading-box">
            <div class="spinner"></div>
            <h3>Connecting to Cashfree</h3>
            <p>Loading secure payment checkout...</p>
          </div>
          <script>
            document.addEventListener("DOMContentLoaded", function() {
              try {
                const cashfree = Cashfree({
                  mode: "${env}"
                });
                cashfree.checkout({
                  paymentSessionId: "${sessionId}",
                  redirectTarget: "_self"
                });
              } catch (e) {
                console.error("Cashfree SDK Initialization Error:", e);
              }
            });
          </script>
        </body>
        </html>
      `);
    } catch (error: any) {
      next(error);
    }
  }
}
