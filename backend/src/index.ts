import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config, HTTP_STATUS, RESPONSE_MESSAGES } from './config';
import './firebase'; // Singleton Firebase initialization
import { errorHandler, requestIdMiddleware } from './middleware';
import { Logger } from './utils/logger';
import { WorkflowListenerService } from './services/workflow-listener.service';
import { UserListenerService } from './services/user-listener.service';
import { CouponListenerService } from './services/coupon-listener.service';

import paymentRoutes from './routes/payment.routes';
import notificationRoutes from './routes/notification.routes';
import userRoutes from './routes/user.routes';
import bookingRoutes from './routes/booking.routes';

// Initialize the real-time background listeners
WorkflowListenerService.initialize();
UserListenerService.initialize();
CouponListenerService.initialize();

const app = express();
if (config.nodeEnv === 'production') app.set('trust proxy', 1);

// Security and request tracking middleware
app.use(requestIdMiddleware);
app.use(helmet());
const allowedOrigins = new Set(config.corsAllowedOrigins);
app.use(
  cors({
    origin(origin, callback) {
      // Native mobile clients do not send an Origin header.
      if (!origin || allowedOrigins.has(origin)) {
        callback(null, true);
        return;
      }
      callback(Object.assign(new Error('Origin is not allowed by CORS policy.'), {
        statusCode: HTTP_STATUS.FORBIDDEN,
      }));
    },
  })
);
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
app.use('/api/notifications', notificationRoutes);
app.use('/api/users', userRoutes);
app.use('/api/bookings', bookingRoutes);

// Register global error handler middleware
app.use(errorHandler);

app.listen(config.port, '0.0.0.0', () => {
  Logger.info(`[Server] Backend service running on port ${config.port} (${config.nodeEnv} mode)`);
  
  Logger.info(`[PhonePe] Gateway configuration loaded for ${config.nodeEnv}.`);
});

export default app;
