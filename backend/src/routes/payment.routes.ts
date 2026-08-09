import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import {
  createPaymentRateLimiter,
  statusCheckRateLimiter,
  webhookRateLimiter,
} from '../middleware/rate-limit.middleware';
import { requireAuth } from '../middleware/auth.middleware';
import { requireAppCheck } from '../middleware/app-check.middleware';

const router = Router();

/**
 * @route POST /api/payment/create
 * @desc Initiates a pending payment transaction with PhonePe
 */
router.post('/create', requireAppCheck, requireAuth, createPaymentRateLimiter, PaymentController.createPayment);

/**
 * @route GET /api/payment/status/:merchantTransactionId
 * @desc Checks payment status directly with PhonePe Gateway and reconciles Firestore
 */
router.get('/status/:merchantTransactionId', requireAppCheck, requireAuth, statusCheckRateLimiter, PaymentController.checkStatus);

/**
 * @route POST /api/payment/webhook
 * @desc Receives and verifies payment status webhooks from PhonePe
 */
router.post('/webhook', webhookRateLimiter, PaymentController.handleWebhook);

/**
 * @route GET /api/payment/redirect
 * @route POST /api/payment/redirect
 * @desc Handles browser redirect from PhonePe payment page
 */
router.get('/redirect', PaymentController.handleRedirect);
router.post('/redirect', PaymentController.handleRedirect);

export default router;
