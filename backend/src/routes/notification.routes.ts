import { Router, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { AuthenticatedRequest, requireAuth, requireRole } from '../middleware/auth.middleware';
import { HTTP_STATUS } from '../config';

const router = Router();

router.post('/send', requireAuth, requireRole(['operations', 'admin']), async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { title, message, recipientRoles, recipientUserIds } = req.body;

    // 1. Validation
    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'Title is required.',
      });
    }
    if (title.trim().length > 100) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'Title maximum length is 100 characters.',
      });
    }
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'Message is required.',
      });
    }
    if (message.trim().length > 500) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'Message maximum length is 500 characters.',
      });
    }

    const rolesList = recipientRoles || [];
    const userIdsList = recipientUserIds || [];

    if (rolesList.length === 0 && userIdsList.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'At least one recipient group (role) or specific user must be selected.',
      });
    }

    // 2. Resolve recipients from Firestore users collection
    const resolvedUids = new Set<string>();

    // 2a. If recipientUserIds are specified, add them
    for (const uid of userIdsList) {
      if (uid && typeof uid === 'string') {
        resolvedUids.add(uid.trim());
      }
    }

    // 2b. If recipientRoles are specified, query users matching those roles
    if (rolesList.length > 0) {
      let queryRoles = [...rolesList];
      if (rolesList.includes('everyone')) {
        queryRoles = ['farmer', 'retailer', 'pilot', 'external_pilot', 'operations'];
      }

      // Query firestore in batches or directly if we use an 'in' query
      // Firestore 'in' query is limited to 30 elements, but here queryRoles has at most 5 elements, so it is safe.
      const usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('role', 'in', queryRoles)
        .get();

      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        if (userData?.uid) {
          resolvedUids.add(userData.uid);
        } else if (doc.id) {
          resolvedUids.add(doc.id);
        }
      });
    }

    const targetUids = Array.from(resolvedUids);

    if (targetUids.length === 0) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        error: 'No valid recipient users found for the selected target.',
      });
    }

    const sender = req.user!;

    // 4. Save the master Custom Notification history document
    const customNotificationRef = admin.firestore().collection('custom_notifications').doc();
    const customNotificationData = {
      id: customNotificationRef.id,
      title: title.trim(),
      message: message.trim(),
      body: message.trim(),
      senderId: sender.uid,
      senderName: sender.name || 'Operations User',
      senderRole: sender.role,
      recipientRoles: rolesList,
      recipientUserIds: userIdsList,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      notificationType: 'CUSTOM',
      type: 'CUSTOM',
      status: 'sending',
      recipientCount: targetUids.length,
    };
    await customNotificationRef.set(customNotificationData);

    // 5. Send notifications in chunked batches of 500
    const chunkSize = 500;
    let totalSent = 0;
    let totalFailed = 0;

    for (let i = 0; i < targetUids.length; i += chunkSize) {
      const chunk = targetUids.slice(i, i + chunkSize);
      
      const userDocsSnapshot = await admin
        .firestore()
        .collection('users')
        .where('uid', 'in', chunk)
        .get();

      const userTokensMap = new Map<string, string[]>();
      const userDocMap = new Map<string, admin.firestore.QueryDocumentSnapshot>();

      userDocsSnapshot.forEach(doc => {
        const userData = doc.data();
        const uid = userData?.uid || doc.id;
        userDocMap.set(uid, doc);
        if (userData?.fcmTokens) {
          userTokensMap.set(uid, userData.fcmTokens);
        }
      });

      const batch = admin.firestore().batch();
      const allTokens: string[] = [];

      for (const recipientUid of chunk) {
        const userDoc = userDocMap.get(recipientUid);
        const userData = userDoc?.data();
        const recipientRole = userData?.role || 'unknown';

        const notifRef = admin.firestore().collection('notifications').doc();
        const notificationData = {
          recipientId: recipientUid,
          recipientUid: recipientUid,
          recipientRole: recipientRole,
          priority: 'high',
          title: title.trim(),
          body: message.trim(),
          message: message.trim(),
          type: 'CUSTOM',
          isRead: false,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          senderId: sender.uid,
          senderName: sender.name || 'Operations User',
          senderRole: sender.role,
        };
        batch.set(notifRef, notificationData);

        const tokens = userTokensMap.get(recipientUid) || [];
        allTokens.push(...tokens);
      }

      await batch.commit();

      const uniqueTokens = Array.from(new Set(allTokens)).filter(t => t && t.trim() !== '');
      if (uniqueTokens.length > 0) {
        const fcmMessage: admin.messaging.MulticastMessage = {
          tokens: uniqueTokens,
          notification: {
            title: title.trim(),
            body: message.trim(),
          },
          data: {
            type: 'CUSTOM',
            notificationType: 'CUSTOM',
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

        try {
          const fcmResponse = await admin.messaging().sendEachForMulticast(fcmMessage);
          totalSent += fcmResponse.successCount;
          totalFailed += fcmResponse.failureCount;

          if (fcmResponse.failureCount > 0) {
            const invalidTokens: string[] = [];
            fcmResponse.responses.forEach((resp, idx) => {
              if (!resp.success) {
                const errorCode = resp.error?.code;
                if (
                  errorCode === 'messaging/invalid-registration-token' ||
                  errorCode === 'messaging/registration-token-not-registered'
                ) {
                  invalidTokens.push(uniqueTokens[idx]);
                }
              }
            });

            if (invalidTokens.length > 0) {
              for (const doc of userDocsSnapshot.docs) {
                const userData = doc.data();
                const tokens = userData?.fcmTokens || [];
                const tokensToRemove = tokens.filter((t: string) => invalidTokens.includes(t));
                if (tokensToRemove.length > 0) {
                  await doc.ref.update({
                    fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
                  }).catch(err => console.error(`Failed token cleanup for user ${doc.id}:`, err));
                }
              }
            }
          }
        } catch (fcmErr) {
          console.error('[NotificationRoutes] FCM sendEachForMulticast error:', fcmErr);
          totalFailed += uniqueTokens.length;
        }
      }
    }

    // 6. Update master history status
    await customNotificationRef.update({
      status: 'sent',
      sentCount: totalSent,
      failedCount: totalFailed,
    });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Custom notifications sent successfully.',
      recipientCount: targetUids.length,
      sentCount: totalSent,
      failedCount: totalFailed,
    });

  } catch (error: any) {
    next(error);
  }
});

router.get('/history', requireAuth, requireRole(['operations', 'admin']), async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const historySnapshot = await admin
      .firestore()
      .collection('custom_notifications')
      .orderBy('createdAt', 'desc')
      .get();

    const history: any[] = [];
    historySnapshot.forEach(doc => {
      const data = doc.data();
      history.push({
        id: doc.id,
        ...data,
        timestamp: data.timestamp ? data.timestamp.toDate() : null,
        createdAt: data.createdAt ? data.createdAt.toDate() : null,
      });
    });

    return res.status(HTTP_STATUS.OK).json({
      success: true,
      history,
    });
  } catch (error: any) {
    next(error);
  }
});

export default router;
