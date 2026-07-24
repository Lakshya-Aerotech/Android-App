import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import {
  createPaymentRateLimiter,
  statusCheckRateLimiter,
  webhookRateLimiter,
} from '../middleware/rate-limit.middleware';

const router = Router();

/**
 * @route POST /api/payment/create
 * @desc Initiates a pending payment transaction with PhonePe
 */
router.post('/create', createPaymentRateLimiter, PaymentController.createPayment);

/**
 * @route GET /api/payment/status/:merchantTransactionId
 * @desc Checks payment status directly with PhonePe Gateway and reconciles Firestore
 */
router.get('/status/:merchantTransactionId', statusCheckRateLimiter, PaymentController.checkStatus);

/**
 * @route POST /api/payment/webhook
 * @desc Receives and verifies payment status webhooks from PhonePe
 */
router.post('/webhook', webhookRateLimiter, PaymentController.handleWebhook);

export default router;
