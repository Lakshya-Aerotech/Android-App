import * as admin from 'firebase-admin';

export interface NotificationPayload {
  recipientUid: string;
  title: string;
  body: string;
  type: string;
  bookingId?: string;
  additionalData?: Record<string, string>;
}

export interface NotificationResult {
  success: boolean;
  sentCount: number;
  failedCount: number;
  errors?: any[];
}

export class NotificationService {
  /**
   * Sends a push notification to all registered FCM devices of a specific user.
   * Cleans up any invalid tokens from Firestore automatically.
   */
  static async sendNotification(payload: NotificationPayload): Promise<NotificationResult> {
    try {
      const { recipientUid, title, body, type, bookingId, additionalData } = payload;

      // 1. Fetch user document from Firestore to get fcmTokens
      const userDoc = await admin.firestore().collection('users').doc(recipientUid).get();
      if (!userDoc.exists) {
        throw new Error(`User with UID ${recipientUid} does not exist.`);
      }

      const userData = userDoc.data();
      const fcmTokens: string[] = userData?.fcmTokens || [];

      if (fcmTokens.length === 0) {
        console.log(`[NotificationService] User ${recipientUid} has no registered FCM tokens. Skipping send.`);
        return { success: true, sentCount: 0, failedCount: 0 };
      }

      // 2. Prepare the multicast message payload
      const message: admin.messaging.MulticastMessage = {
        tokens: fcmTokens,
        notification: {
          title,
          body,
        },
        data: {
          type,
          ...(bookingId ? { bookingId } : {}),
          ...additionalData,
        },
        android: {
          notification: {
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      // 3. Send message via Firebase Admin SDK
      console.log(`[NotificationService] Sending notification to user ${recipientUid} on ${fcmTokens.length} devices...`);
      const response = await admin.messaging().sendEachForMulticast(message);

      const failedTokens: string[] = [];
      const errors: any[] = [];

      // 4. Cleanup invalid/stale tokens
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            errors.push(error);
            const errorCode = error?.code;
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              failedTokens.push(fcmTokens[idx]);
            }
          }
        });

        if (failedTokens.length > 0) {
          console.log(`[NotificationService] Cleaning up ${failedTokens.length} invalid tokens for user ${recipientUid}...`);
          await admin
            .firestore()
            .collection('users')
            .doc(recipientUid)
            .update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
            });
        }
      }

      return {
        success: true,
        sentCount: response.successCount,
        failedCount: response.failureCount,
        errors: errors.length > 0 ? errors : undefined,
      };
    } catch (error: any) {
      console.error('[NotificationService] Error sending notification:', error);
      throw error;
    }
  }
}
