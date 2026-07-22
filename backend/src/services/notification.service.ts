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

      // 1. Fetch user document from Firestore by uid field to handle both uid-as-docId and auto-generated docId cases.
      const usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('uid', '==', recipientUid)
        .get();

      let userData: any = null;
      let fcmTokens: string[] = [];
      let recipientRole = 'unknown';
      let userDocId = 'unknown';

      if (!usersSnapshot.empty) {
        const userDoc = usersSnapshot.docs[0];
        userData = userDoc.data();
        fcmTokens = userData?.fcmTokens || [];
        recipientRole = userData?.role || 'unknown';
        userDocId = userDoc.id;
      } else {
        // Fallback: check if recipientUid matches the document ID directly (just in case)
        const userDoc = await admin.firestore().collection('users').doc(recipientUid).get();
        if (userDoc.exists) {
          userData = userDoc.data();
          fcmTokens = userData?.fcmTokens || [];
          recipientRole = userData?.role || 'unknown';
          userDocId = userDoc.id;
        } else {
          throw new Error(`User with UID/DocId ${recipientUid} does not exist.`);
        }
      }

      console.log(`[NotificationService] Notification Creation Started:
        Recipient User ID (UID): ${recipientUid}
        Recipient User Document ID: ${userDocId}
        Recipient Role: ${recipientRole}
        Title: "${title}"
        Body: "${body}"
        Type: "${type}"`);

      // 2. Write to Firestore 'notifications' collection
      const notificationData = {
        recipientId: recipientUid,
        recipientUid: recipientUid, // for backward compatibility/Flutter code
        recipientRole: recipientRole,
        title,
        body,
        message: body, // for backward compatibility/Flutter code
        type,
        referenceId: bookingId || additionalData?.bookingId || '',
        bookingId: bookingId || additionalData?.bookingId || '', // for backward compatibility/Flutter code
        isRead: false,
        read: false, // for backward compatibility/Flutter code
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          ...(bookingId ? { bookingId } : {}),
          ...additionalData,
        },
      };

      try {
        await admin.firestore().collection('notifications').add(notificationData);
        console.log(`[NotificationService] Firestore Write SUCCESS for recipient ${recipientUid}`);
      } catch (fsError) {
        console.error(`[NotificationService] Firestore Write FAILURE for recipient ${recipientUid}:`, fsError);
      }

      if (fcmTokens.length === 0) {
        console.log(`[NotificationService] FCM Send SKIPPED: Recipient ${recipientUid} has no registered FCM tokens.`);
        return { success: true, sentCount: 0, failedCount: 0 };
      }

      // 3. Prepare the multicast message payload
      const message: admin.messaging.MulticastMessage = {
        tokens: fcmTokens,
        notification: {
          title,
          body,
        },
        data: {
          type,
          notificationType: type,
          ...(bookingId ? { bookingId, referenceId: bookingId } : {}),
          ...additionalData,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
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

      // 4. Send message via Firebase Admin SDK
      console.log(`[NotificationService] FCM Send Attempt:
        Recipient User ID (UID): ${recipientUid}
        Retrieved FCM Tokens: ${JSON.stringify(fcmTokens)}
        Notification Payload: ${JSON.stringify(message)}`);
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[NotificationService] FCM Send RESULT:
        Success Count: ${response.successCount}
        Failure Count: ${response.failureCount}`);

      const failedTokens: string[] = [];
      const errors: any[] = [];

      // 5. Cleanup invalid/stale tokens
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            errors.push(error);
            console.error(`[NotificationService] Send Failure to Token: ${fcmTokens[idx]}, Error:`, error);
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
          console.log(`[NotificationService] Cleaning up ${failedTokens.length} invalid tokens for user ${userDocId}...`);
          await admin
            .firestore()
            .collection('users')
            .doc(userDocId)
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
