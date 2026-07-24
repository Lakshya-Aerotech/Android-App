import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS, RESPONSE_MESSAGES } from '../config/constants';
import { Logger } from '../utils/logger';
import * as admin from 'firebase-admin';
import { NotificationService } from '../services/notification.service';

/**
 * Helper to broadcast system errors to all Admins.
 */
async function notifyAdminsOfSystemError(errorMsg: string): Promise<void> {
  try {
    const adminUsers = await admin.firestore().collection('users').where('role', '==', 'admin').get();
    const promises: Promise<any>[] = [];
    adminUsers.forEach((doc: any) => {
      promises.push(
        NotificationService.sendNotification({
          recipientUid: doc.data().uid || doc.id,
          title: 'System Error Alert',
          body: `A system exception has occurred: ${errorMsg}`,
          type: 'SYSTEM_ERROR',
        }).catch((err) =>
          Logger.error(`[System Error Helper] Failed to send admin notification to ${doc.id}`, { error: err })
        )
      );
    });
    await Promise.all(promises);
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
    notifyAdminsOfSystemError(errorMsg).catch(console.error);
  }

  return res.status(statusCode).json({
    success: false,
    message: errorMsg,
    data: null,
    requestId: req.id,
  });
}
