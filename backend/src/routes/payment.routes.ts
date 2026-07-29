import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import { requireAuth, requireRole } from '../middleware/auth.middleware';
import {
  createPaymentRateLimiter,
  statusCheckRateLimiter,
  webhookRateLimiter,
} from '../middleware/rate-limit.middleware';

const router = Router();

/**
 * @route POST /api/payment/create-order
 * @route POST /api/payment/create
 * @desc Authenticated endpoint: Validates booking ownership, calculates amount, creates Cashfree order
 */
router.post('/create-order', requireAuth, createPaymentRateLimiter, PaymentController.createPayment);
router.post('/create', requireAuth, createPaymentRateLimiter, PaymentController.createPayment);

/**
 * @route GET /api/payment/status/:orderId
 * @route GET /api/payment/status/:merchantTransactionId
 * @route POST /api/payment/verify
 * @desc Authenticated endpoint: Checks payment status directly with Cashfree Gateway and reconciles Firestore
 */
router.get('/status/:orderId', requireAuth, statusCheckRateLimiter, PaymentController.checkStatus);
router.post('/verify', requireAuth, statusCheckRateLimiter, PaymentController.checkStatus);

/**
 * @route POST /api/payment/confirm-cash
 * @desc Authenticated Admin & Operations endpoint to confirm cash collection for a booking
 */
router.post('/confirm-cash', requireAuth, requireRole(['admin', 'operations']), PaymentController.confirmCashPayment);

/**
 * @route POST /api/payment/webhook
 * @desc Receives and verifies payment status webhooks from Cashfree Gateway
 */
router.post('/webhook', webhookRateLimiter, PaymentController.handleWebhook);

/**
 * @route GET /api/payment/redirect
 * @route POST /api/payment/redirect
 * @route GET /api/payment/mock-checkout
 * @route GET /api/payment/cashfree-checkout
 * @desc Handles browser return redirect, SDK runner & interactive mock simulator for Cashfree
 */
router.get('/redirect', PaymentController.handleRedirect);
router.post('/redirect', PaymentController.handleRedirect);
router.get('/mock-checkout', PaymentController.handleMockCheckout);
router.get('/cashfree-checkout', PaymentController.handleCashfreeCheckout);

export default router;
