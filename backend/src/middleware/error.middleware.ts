import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS, RESPONSE_MESSAGES } from '../config/constants';
import { Logger } from '../utils/logger';
import * as admin from 'firebase-admin';
import { NotificationService } from '../services/notification.service';

/**
 * Helper to broadcast system errors to all Admins.
 */
async function notifyAdminsOfSystemError(requestId: string | undefined): Promise<void> {
  try {
    await NotificationService.sendNotification({
      recipientRole: 'admin',
      title: 'System Error Alert',
      body: `A server error occurred. Reference: ${requestId || 'unavailable'}`,
      type: 'SYSTEM_ERROR',
    });
  } catch (error) {
    Logger.error('[System Error Helper] Error notifying admin team', { error });
  }
}

/**
 * Global Express Error Handling Middleware.
 * Formats all uncaught errors into a consistent API response structure.
 */
export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): Response {
  const errorMsg = err.message || err.toString() || RESPONSE_MESSAGES.UNHANDLED_EXCEPTION;
  const statusCode = err.status || err.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR;

  Logger.error(`[Unhandled System Error] ${errorMsg}`, {
    requestId: req.id,
    endpoint: req.originalUrl,
    method: req.method,
    statusCode,
    error: err,
  });

  // Asynchronously notify admins of system exceptions for server-level 500 errors
  if (statusCode >= 500) {
    notifyAdminsOfSystemError(req.id).catch(console.error);
  }

  const responseMessage = statusCode >= 500
    ? RESPONSE_MESSAGES.INTERNAL_SERVER_ERROR
    : errorMsg;

  return res.status(statusCode).json({
    success: false,
    message: responseMessage,
    data: null,
    requestId: req.id,
  });
}
