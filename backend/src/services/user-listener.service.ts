import * as admin from 'firebase-admin';
import { NotificationService } from './notification.service';

interface CachedUser {
  role: string;
  approvalStatus: string;
}

export class UserListenerService {
  private static userCache = new Map<string, CachedUser>();

  /**
   * Initializes real-time listener on users collection changes.
   */
  static async initialize(): Promise<void> {
    console.log('[UserListenerService] Initializing Firestore users listener...');

    try {
      // 1. Warm cache with current users
      const usersSnapshot = await admin.firestore().collection('users').get();
      usersSnapshot.forEach((doc) => {
        const data = doc.data();
        this.userCache.set(doc.id, {
          role: data.role || '',
          approvalStatus: data.approvalStatus || '',
        });
      });
      console.log(`[UserListenerService] Cached ${this.userCache.size} users.`);

      // 2. Register onSnapshot listener
      admin.firestore().collection('users').onSnapshot(
        async (snapshot) => {
          for (const change of snapshot.docChanges()) {
            const userId = change.doc.id;
            const data = change.doc.data();
            const role = data.role || '';
            const approvalStatus = data.approvalStatus || '';

            if (change.type === 'added') {
              if (!this.userCache.has(userId)) {
                this.userCache.set(userId, { role, approvalStatus });

                // Notify Admins on New registrations
                if (role === 'farmer') {
                  await this.notifyAdmins(
                    'New Farmer Registered',
                    `A new farmer (${data.name || userId}) has registered on the platform.`,
                    'NEW_FARMER_REGISTERED'
                  );
                } else if (role === 'retailer') {
                  await this.notifyAdmins(
                    'New Retailer Registered',
                    `A new retailer (${data.name || userId}) has registered and requires manual approval.`,
                    'NEW_RETAILER_REGISTERED'
                  );
                } else if (role === 'pilot' || role === 'externalPilot') {
                  await this.notifyAdmins(
                    'New Pilot Registered',
                    `A new pilot (${data.name || userId}) has registered on the platform.`,
                    'NEW_PILOT_REGISTERED'
                  );
                }
              }
            } else if (change.type === 'modified') {
              const cached = this.userCache.get(userId);
              if (cached) {
                const oldApprovalStatus = cached.approvalStatus;

                // Update cache immediately
                this.userCache.set(userId, { role, approvalStatus });

                // Check Retailer Approval and Rejection
                if (role === 'retailer') {
                  // Retailer Approval (pending -> approved)
                  if (oldApprovalStatus !== 'approved' && approvalStatus === 'approved') {
                    await NotificationService.sendNotification({
                      recipientUid: userId,
                      title: 'Retailer Account Approved',
                      body: 'Your registration request has been approved. You now have full access to the retailer platform.',
                      type: 'RETAILER_APPROVED',
                    });
                  }

                  // Retailer Rejection (pending -> rejected)
                  if (oldApprovalStatus !== 'rejected' && approvalStatus === 'rejected') {
                    await NotificationService.sendNotification({
                      recipientUid: userId,
                      title: 'Retailer Registration Rejected',
                      body: 'Your registration request was declined by the administrator.',
                      type: 'RETAILER_REJECTED',
                    });
                  }
                }
              } else {
                this.userCache.set(userId, { role, approvalStatus });
              }
            } else if (change.type === 'removed') {
              this.userCache.delete(userId);
            }
          }
        },
        (error) => {
          console.error('[UserListenerService] Firestore user listener error:', error);
        }
      );
    } catch (error) {
      console.error('[UserListenerService] Initialization failed:', error);
    }
  }

  /**
   * Helper method to broadcast a notification to all admins.
   */
  private static async notifyAdmins(title: string, body: string, type: string): Promise<void> {
    try {
      const adminUsers = await admin.firestore().collection('users').where('role', '==', 'admin').get();
      const promises: Promise<any>[] = [];
      adminUsers.forEach((doc) => {
        promises.push(
          NotificationService.sendNotification({
            recipientUid: doc.id,
            title,
            body,
            type,
          }).catch((err) =>
            console.error(`[UserListenerService] Failed to send admin notification to ${doc.id}:`, err)
          )
        );
      });
      await Promise.all(promises);
    } catch (error) {
      console.error('[UserListenerService] Error notifying admin team:', error);
    }
  }
}
