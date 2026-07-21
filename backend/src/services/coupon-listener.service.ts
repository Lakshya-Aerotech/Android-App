import * as admin from 'firebase-admin';
import { NotificationService } from './notification.service';

interface CachedCoupon {
  couponCode: string;
  assignedRetailerIds: string[];
}

export class CouponListenerService {
  private static couponCache = new Map<string, CachedCoupon>();

  /**
   * Initializes real-time listener on coupons collection changes.
   */
  static async initialize(): Promise<void> {
    console.log('[CouponListenerService] Initializing Firestore coupons listener...');

    try {
      // 1. Warm cache with current coupons
      const couponsSnapshot = await admin.firestore().collection('coupons').get();
      couponsSnapshot.forEach((doc) => {
        const data = doc.data();
        this.couponCache.set(doc.id, {
          couponCode: data.couponCode || '',
          assignedRetailerIds: data.assignedRetailerIds || [],
        });
      });
      console.log(`[CouponListenerService] Cached ${this.couponCache.size} coupons.`);

      // 2. Register onSnapshot listener
      admin.firestore().collection('coupons').onSnapshot(
        async (snapshot) => {
          for (const change of snapshot.docChanges()) {
            const couponId = change.doc.id;
            const data = change.doc.data();
            const couponCode = data.couponCode || '';
            const assignedRetailerIds: string[] = data.assignedRetailerIds || [];

            if (change.type === 'added') {
              if (!this.couponCache.has(couponId)) {
                this.couponCache.set(couponId, { couponCode, assignedRetailerIds });

                // Coupon Assigned (notify newly assigned retailers)
                for (const retailerId of assignedRetailerIds) {
                  await NotificationService.sendNotification({
                    recipientUid: retailerId,
                    title: 'New Coupon Assigned',
                    body: `You have been assigned the coupon: ${couponCode}.`,
                    type: 'COUPON_ASSIGNED',
                    additionalData: { couponCode },
                  }).catch((err) =>
                    console.error(`[CouponListenerService] Failed to notify retailer ${retailerId} on added coupon:`, err)
                  );
                }
              }
            } else if (change.type === 'modified') {
              const cached = this.couponCache.get(couponId);
              if (cached) {
                const oldRetailers = cached.assignedRetailerIds;

                // Update cache immediately
                this.couponCache.set(couponId, { couponCode, assignedRetailerIds });

                // Notify newly assigned retailers
                for (const retailerId of assignedRetailerIds) {
                  if (!oldRetailers.includes(retailerId)) {
                    await NotificationService.sendNotification({
                      recipientUid: retailerId,
                      title: 'New Coupon Assigned',
                      body: `You have been assigned the coupon: ${couponCode}.`,
                      type: 'COUPON_ASSIGNED',
                      additionalData: { couponCode },
                    }).catch((err) =>
                      console.error(`[CouponListenerService] Failed to notify retailer ${retailerId} on modified coupon:`, err)
                    );
                  }
                }
              } else {
                this.couponCache.set(couponId, { couponCode, assignedRetailerIds });
              }
            } else if (change.type === 'removed') {
              this.couponCache.delete(couponId);
            }
          }
        },
        (error) => {
          console.error('[CouponListenerService] Firestore coupon listener error:', error);
        }
      );

      // 3. Register scheduler for coupon expiration warning (check every 12 hours)
      this.startExpirationCheckScheduler();
    } catch (error) {
      console.error('[CouponListenerService] Initialization failed:', error);
    }
  }

  /**
   * Periodically check for coupons expiring soon (within 3 days) and alert their assigned retailers.
   */
  private static startExpirationCheckScheduler(): void {
    // Run once on startup
    this.checkExpiringCoupons();

    // Run every 12 hours
    setInterval(() => {
      this.checkExpiringCoupons();
    }, 12 * 60 * 60 * 1000);
  }

  private static async checkExpiringCoupons(): Promise<void> {
    console.log('[CouponListenerService] Running expiring coupons check...');
    try {
      const now = new Date();
      const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

      const couponsSnapshot = await admin
        .firestore()
        .collection('coupons')
        .where('isActive', '==', true)
        .where('validUntil', '>', admin.firestore.Timestamp.fromDate(now))
        .where('validUntil', '<=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .get();

      couponsSnapshot.forEach((doc) => {
        const data = doc.data();
        const couponCode = data.couponCode;
        const assignedRetailerIds: string[] = data.assignedRetailerIds || [];

        assignedRetailerIds.forEach((retailerId) => {
          NotificationService.sendNotification({
            recipientUid: retailerId,
            title: 'Coupon Expiring Soon',
            body: `Your assigned coupon (${couponCode}) will expire soon on ${data.validUntil.toDate().toLocaleDateString()}.`,
            type: 'COUPON_EXPIRING_SOON',
            additionalData: { couponCode },
          }).catch((err) =>
            console.error(`[CouponListenerService] Failed to send expiration notice to ${retailerId}:`, err)
          );
        });
      });
    } catch (error) {
      console.error('[CouponListenerService] Error checking expiring coupons:', error);
    }
  }
}
