import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config, HTTP_STATUS, RESPONSE_MESSAGES } from './config';
import './firebase'; // Singleton Firebase initialization
import { errorHandler, requestIdMiddleware } from './middleware';
import { Logger } from './utils/logger';
import { NotificationService } from './services/notification.service';
import { WorkflowListenerService } from './services/workflow-listener.service';
import { UserListenerService } from './services/user-listener.service';
import { CouponListenerService } from './services/coupon-listener.service';

import paymentRoutes from './routes/payment.routes';

// Initialize the real-time background listeners
WorkflowListenerService.initialize();
UserListenerService.initialize();
CouponListenerService.initialize();

const app = express();

// Security and request tracking middleware
app.use(requestIdMiddleware);
app.use(helmet());
app.use(cors());
app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/**
 * Health check endpoint for system diagnostics.
 */
app.get('/health', (req: Request, res: Response) => {
  return res.status(HTTP_STATUS.OK).json({
    success: true,
    message: RESPONSE_MESSAGES.HEALTH_CHECK_OK,
    requestId: req.id,
  });
});

// Register payment API routes
app.use('/api/payment', paymentRoutes);

/**
 * API POST endpoint to send push notification.
 */
app.post('/api/send-notification', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { recipientUid, title, body, type, bookingId, additionalData } = req.body;

    // Validate required parameters
    if (!recipientUid || !title || !body || !type) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'Missing required fields: recipientUid, title, body, and type are required.',
        requestId: req.id,
      });
    }

    const result = await NotificationService.sendNotification({
      recipientUid,
      title,
      body,
      type,
      bookingId,
      additionalData,
    });

    return res.status(HTTP_STATUS.OK).json(result);
  } catch (error: any) {
    next(error);
  }
});

// Register global error handler middleware
app.use(errorHandler);

app.listen(config.port, '0.0.0.0', () => {
  Logger.info(`[Server] Backend service running on port ${config.port} (${config.nodeEnv} mode)`);
  
  // Log PhonePe configuration for troubleshooting (masking secrets)
  const maskedSaltKey = config.phonePe.saltKey ? `${config.phonePe.saltKey.slice(0, 4)}...${config.phonePe.saltKey.slice(-4)}` : 'NOT_CONFIGURED';
  Logger.info(`[PhonePe Startup Config]
    Environment: ${config.nodeEnv}
    Merchant ID: ${config.phonePe.merchantId}
    Salt Key: ${maskedSaltKey}
    Salt Index: ${config.phonePe.saltIndex}
    API Base URL: ${config.phonePe.baseUrl}
    Callback URL: ${config.phonePe.callbackUrl}
    Redirect URL: ${config.phonePe.callbackUrl.replace('/webhook', '/redirect')}
  `);
});

export default app;
