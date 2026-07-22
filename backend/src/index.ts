import express, { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { NotificationService } from './services/notification.service';
import { WorkflowListenerService } from './services/workflow-listener.service';
import { UserListenerService } from './services/user-listener.service';
import { CouponListenerService } from './services/coupon-listener.service';

// Initialize Firebase Admin SDK
// This automatically picks up application default credentials or credentials from local environment
admin.initializeApp();

// Initialize the real-time listeners
WorkflowListenerService.initialize();
UserListenerService.initialize();
CouponListenerService.initialize();

const app = express();
app.use(express.json());

/**
 * Helper to broadcast system errors to all Admins.
 */
async function notifyAdminsOfSystemError(errorMsg: string): Promise<void> {
  try {
    const adminUsers = await admin.firestore().collection('users').where('role', '==', 'admin').get();
    const promises: Promise<any>[] = [];
    adminUsers.forEach((doc) => {
      promises.push(
        NotificationService.sendNotification({
          recipientUid: doc.data().uid || doc.id,
          title: 'System Error Alert',
          body: `A system exception has occurred: ${errorMsg}`,
          type: 'SYSTEM_ERROR',
        }).catch((err) =>
          console.error(`[System Error Helper] Failed to send admin notification to ${doc.id}:`, err)
        )
      );
    });
    await Promise.all(promises);
  } catch (error) {
    console.error('[System Error Helper] Error notifying admin team:', error);
  }
}

/**
 * API POST endpoint to send notification.
 */
app.post('/api/send-notification', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { recipientUid, title, body, type, bookingId, additionalData } = req.body;

    // Validate required parameters
    if (!recipientUid || !title || !body || !type) {
      return res.status(400).json({
        error: 'Missing required fields: recipientUid, title, body, and type are required.',
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

    return res.status(200).json(result);
  } catch (error: any) {
    next(error);
  }
});

/**
 * Catch-all Express Error Handler Middleware to intercept system errors.
 */
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('[Unhandled System Error]:', err);
  const errorMsg = err.message || err.toString() || 'Unknown system exception.';
  
  // Asynchronously notify admins of the system exception
  notifyAdminsOfSystemError(errorMsg).catch(console.error);

  return res.status(500).json({
    error: errorMsg || 'An internal server error occurred.',
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[Server] Notification service running on port ${PORT}`);
});
