import * as admin from 'firebase-admin';
import crypto from 'crypto';

export interface NotificationPayload {
  recipientUid?: string;
  recipientRole?: string;
  priority?: string;
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
   * Sends a push notification to all registered FCM devices of targeted users (either by UID or role).
   * Cleans up any invalid tokens from Firestore automatically.
   */
  static async sendNotification(payload: NotificationPayload): Promise<NotificationResult> {
    try {
      const { recipientUid, recipientRole: payloadRecipientRole, priority, title, body, type, bookingId, additionalData } = payload;

      let fcmTokens: string[] = [];
      let targetRole = payloadRecipientRole || '';
      let targetUid = recipientUid || '';
      const failedTokensToClean: { userDocId: string; tokens: string[] }[] = [];

      const eventId = crypto
        .createHash('sha256')
        .update(JSON.stringify({
          recipientUid: recipientUid || '',
          recipientRole: payloadRecipientRole || '',
          title,
          body,
          type,
          bookingId: bookingId || '',
          additionalData: additionalData || {},
        }))
        .digest('hex');
      const eventRef = admin.firestore().collection('notification_events').doc(eventId);
      const claimed = await admin.firestore().runTransaction(async (transaction) => {
        const existing = await transaction.get(eventRef);
        if (existing.exists) return false;
        transaction.create(eventRef, {
          type,
          bookingId: bookingId || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (!claimed) return { success: true, sentCount: 0, failedCount: 0 };

      // 1. Fetch tokens and set recipient details depending on input
      if (recipientUid) {
        const userDoc = await admin.firestore().collection('users').doc(recipientUid).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          const tokens = userData?.fcmTokens || [];
          fcmTokens = [...tokens];
          if (!targetRole) {
            targetRole = userData?.role || 'unknown';
          }
          failedTokensToClean.push({ userDocId: userDoc.id, tokens });
        }
      } else if (payloadRecipientRole) {
        // Broadcast to a specific role (e.g. operations, admin)
        const usersSnapshot = await admin
          .firestore()
          .collection('users')
          .where('role', '==', payloadRecipientRole)
          .get();

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          const tokens: string[] = userData?.fcmTokens || [];
          if (tokens.length > 0) {
            fcmTokens.push(...tokens);
            failedTokensToClean.push({ userDocId: doc.id, tokens });
          }
        });
      }

      console.log(`[NotificationService] Creating ${type} notification for ${targetUid ? 'user' : `role ${targetRole}`}.`);

      // 2. Write to Firestore 'notifications' collection
      const notificationData = {
        recipientId: targetUid,
        recipientUid: targetUid, // for backward compatibility/Flutter code
        recipientRole: targetRole,
        priority: priority || '',
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
        console.log(`[NotificationService] Firestore Write SUCCESS for recipientUid: ${targetUid}, recipientRole: ${targetRole}`);
      } catch (fsError) {
        console.error(`[NotificationService] Firestore Write FAILURE:`, fsError);
      }

      const uniqueTokens = Array.from(new Set(fcmTokens)).filter(t => t && t.trim() !== '');

      if (uniqueTokens.length === 0) {
        console.log(`[NotificationService] FCM Send SKIPPED: No registered FCM tokens found.`);
        return { success: true, sentCount: 0, failedCount: 0 };
      }

      // 3. Prepare the multicast message payload
      const message: admin.messaging.MulticastMessage = {
        tokens: uniqueTokens,
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
      const errors: any[] = [];
      const invalidTokens: string[] = [];
      let sentCount = 0;
      let failedCount = 0;

      for (let offset = 0; offset < uniqueTokens.length; offset += 500) {
        const tokenChunk = uniqueTokens.slice(offset, offset + 500);
        const response = await admin.messaging().sendEachForMulticast({
          ...message,
          tokens: tokenChunk,
        });
        sentCount += response.successCount;
        failedCount += response.failureCount;
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            errors.push(error);
            const errorCode = error?.code;
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(tokenChunk[idx]);
            }
          }
        });
      }

      console.log(`[NotificationService] ${type} result: ${sentCount} sent, ${failedCount} failed.`);

      if (invalidTokens.length > 0) {
        for (const clean of failedTokensToClean) {
          const tokensToRemove = clean.tokens.filter(t => invalidTokens.includes(t));
          if (tokensToRemove.length > 0) {
            await admin
              .firestore()
              .collection('users')
              .doc(clean.userDocId)
              .update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
              })
              .catch(err => console.error(`[NotificationService] Failed token cleanup for ${clean.userDocId}:`, err));
          }
        }
      }

      return {
        success: true,
        sentCount,
        failedCount,
        errors: errors.length > 0 ? errors : undefined,
      };
    } catch (error: any) {
      console.error('[NotificationService] Error sending notification:', error);
      throw error;
    }
  }
}
