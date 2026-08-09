import rateLimit from 'express-rate-limit';
import { HTTP_STATUS } from '../config/constants';

/**
 * Rate limiter for Payment Creation API (POST /api/payment/create).
 * Standard limit: 20 requests per 15 minutes per IP.
 */
export const createPaymentRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many payment creation attempts. Please try again after 15 minutes.',
    data: null,
  },
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});

/**
 * Rate limiter for Payment Status API (GET /api/payment/status/:id).
 * Standard limit: 60 requests per 15 minutes per IP.
 */
export const statusCheckRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many status check requests. Please slow down.',
    data: null,
  },
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});

/**
 * Rate limiter for PhonePe Webhook API (POST /api/payment/webhook).
 * Standard limit: 120 requests per 15 minutes per IP.
 */
export const webhookRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many webhook calls.',
    data: null,
  },
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});

export const accountMutationRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});

export const bookingCreationRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});

export const notificationSendRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
});
