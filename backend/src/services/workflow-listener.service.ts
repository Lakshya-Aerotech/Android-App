import * as admin from 'firebase-admin';
import { NotificationService } from './notification.service';

interface CachedBooking {
  status: string;
  assignedPilotId?: string;
  paymentStatus?: string;
  hasPhotos: boolean;
  hasNotes: boolean;
  bookingDate: string;
  preferredTime: string;
}

export class WorkflowListenerService {
  private static bookingCache = new Map<string, CachedBooking>();

  /**
   * Initializes real-time listener on bookings collection changes.
   */
  static async initialize(): Promise<void> {
    console.log('[WorkflowListenerService] Initializing Firestore bookings listener...');

    try {
      // 1. Warm cache with current bookings status to prevent duplicate notifications for historical data
      const bookingsSnapshot = await admin.firestore().collection('bookings').get();
      bookingsSnapshot.forEach((doc) => {
        const data = doc.data();
        const missionPhotos = data.missionPhotos || [];
        const missionNotes = data.missionNotes || '';
        const bookingDateStr = data.bookingDate ? data.bookingDate.toDate().toISOString().slice(0, 10) : '';
        const preferredTimeStr = data.preferredTime || '';

        this.bookingCache.set(doc.id, {
          status: data.status || '',
          assignedPilotId: data.assignedPilotId || undefined,
          paymentStatus: data.paymentStatus || undefined,
          hasPhotos: missionPhotos.length > 0,
          hasNotes: missionNotes.trim().length > 0,
          bookingDate: bookingDateStr,
          preferredTime: preferredTimeStr,
        });
      });
      console.log(`[WorkflowListenerService] Cached ${this.bookingCache.size} bookings.`);

      // 2. Register onSnapshot listener
      admin.firestore().collection('bookings').onSnapshot(
        async (snapshot) => {
          for (const change of snapshot.docChanges()) {
            const bookingId = change.doc.id;
            const data = change.doc.data();
            const newStatus = data.status || '';
            const newPilotId = data.assignedPilotId || undefined;
            const newPaymentStatus = data.paymentStatus || undefined;
            const missionPhotos = data.missionPhotos || [];
            const missionNotes = data.missionNotes || '';
            const newHasPhotos = missionPhotos.length > 0;
            const newHasNotes = missionNotes.trim().length > 0;
            const newBookingDateStr = data.bookingDate ? data.bookingDate.toDate().toISOString().slice(0, 10) : '';
            const newPreferredTimeStr = data.preferredTime || '';

            if (change.type === 'added') {
              // If it's a new document not in our initial cache
              if (!this.bookingCache.has(bookingId)) {
                this.bookingCache.set(bookingId, {
                  status: newStatus,
                  assignedPilotId: newPilotId,
                  paymentStatus: newPaymentStatus,
                  hasPhotos: newHasPhotos,
                  hasNotes: newHasNotes,
                  bookingDate: newBookingDateStr,
                  preferredTime: newPreferredTimeStr,
                });

                // Service Booking Request Created & Requires Approval
                if (newStatus === 'pending') {
                  // Notify Operations
                  await this.notifyOperations(
                    'Service Booking Request Created',
                    `A new booking request (${bookingId}) has been created and is awaiting review.`,
                    'BOOKING_CREATED',
                    bookingId
                  );
                  // Notify Admins
                  await this.notifyAdmins(
                    'Booking Requires Approval',
                    `Booking request (${bookingId}) requires administrator/operations review.`,
                    'BOOKING_APPROVAL_REQUIRED',
                    bookingId
                  );
                  // Notify Creator Retailer
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'New Booking Created',
                      body: `A new booking request (${bookingId}) has been created for your farmer.`,
                      type: 'BOOKING_CREATED',
                      bookingId,
                    });
                  }
                }
              }
            } else if (change.type === 'modified') {
              const cached = this.bookingCache.get(bookingId);
              if (cached) {
                const oldStatus = cached.status;
                const oldPilotId = cached.assignedPilotId;
                const oldPaymentStatus = cached.paymentStatus;
                const oldHasPhotos = cached.hasPhotos;
                const oldHasNotes = cached.hasNotes;
                const oldBookingDateStr = cached.bookingDate;
                const oldPreferredTimeStr = cached.preferredTime;

                // Update cache immediately
                this.bookingCache.set(bookingId, {
                  status: newStatus,
                  assignedPilotId: newPilotId,
                  paymentStatus: newPaymentStatus,
                  hasPhotos: newHasPhotos,
                  hasNotes: newHasNotes,
                  bookingDate: newBookingDateStr,
                  preferredTime: newPreferredTimeStr,
                });

                // --- 1. Service Booking Flow Transitions ---

                // Booking Accepted (pending -> reviewed)
                if (oldStatus === 'pending' && newStatus === 'reviewed') {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Booking Accepted',
                      body: `Your booking request (${bookingId}) has been approved and is being scheduled.`,
                      type: 'BOOKING_ACCEPTED',
                      bookingId,
                    });
                  }
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'Booking Approved',
                      body: `The booking request (${bookingId}) you created has been approved.`,
                      type: 'BOOKING_APPROVED',
                      bookingId,
                    });
                  }
                }

                // Booking Rejected / Cancelled (any active -> cancelled)
                if (oldStatus !== 'cancelled' && newStatus === 'cancelled') {
                  const isRejection = oldStatus === 'pending';
                  const title = isRejection ? 'Booking Rejected' : 'Booking Cancelled';
                  const type = isRejection ? 'BOOKING_REJECTED' : 'BOOKING_CANCELLED';

                  // Notify Farmer
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title,
                      body: isRejection
                        ? `Your booking request (${bookingId}) was declined by the administrator.`
                        : `Your booking request (${bookingId}) has been cancelled.`,
                      type,
                      bookingId,
                    });
                  }
                  // Notify Creator Retailer
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title,
                      body: isRejection
                        ? `The booking request (${bookingId}) you created has been rejected.`
                        : `The service booking (${bookingId}) has been cancelled.`,
                      type,
                      bookingId,
                    });
                  }
                  // Notify Admins
                  await this.notifyAdmins(
                    title,
                    `Service booking (${bookingId}) has been ${isRejection ? 'rejected' : 'cancelled'}.`,
                    type,
                    bookingId
                  );
                }

                // Drone Pilot Assigned (assignedPilotId goes from empty to non-empty)
                if (!oldPilotId && newPilotId) {
                  // Notify Pilot
                  await NotificationService.sendNotification({
                    recipientUid: newPilotId,
                    title: 'New Pilot Assignment',
                    body: `You have been assigned to execute service booking (${bookingId}).`,
                    type: 'PILOT_ASSIGNED',
                    bookingId,
                  });

                  // Notify Creator Retailer
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'Pilot Assigned to Booking',
                      body: `A pilot has been successfully assigned to booking (${bookingId}).`,
                      type: 'PILOT_ASSIGNED',
                      bookingId,
                    });
                  }
                }

                // Pilot Accepted Assignment (pilotAssigned -> accepted)
                if (oldStatus === 'pilotAssigned' && newStatus === 'accepted') {
                  await this.notifyOperations(
                    'Pilot Accepted Assignment',
                    `Pilot ${data.assignedPilotName || 'assigned'} has accepted assignment for booking (${bookingId}).`,
                    'PILOT_ACCEPTED',
                    bookingId
                  );
                }

                // Pilot Rejected Assignment (pilotAssigned -> reviewed/pending without pilot ID)
                if (oldStatus === 'pilotAssigned' && !newPilotId && (newStatus === 'reviewed' || newStatus === 'pending')) {
                  await this.notifyOperations(
                    'Pilot Rejected Assignment',
                    `Pilot has declined the assignment for booking (${bookingId}).`,
                    'PILOT_REJECTED',
                    bookingId
                  );
                }

                // --- 2. Booking Progress Transitions ---

                // Pilot Started Journey (status becomes enRoute)
                if (oldStatus !== 'enRoute' && newStatus === 'enRoute') {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Pilot En Route',
                      body: `Drone pilot ${data.assignedPilotName || 'assigned'} is on the way to your farm.`,
                      type: 'PILOT_EN_ROUTE',
                      bookingId,
                    });
                  }
                }

                // Pilot Arrived at Farm (status becomes arrived)
                if (oldStatus !== 'arrived' && newStatus === 'arrived') {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Pilot Arrived',
                      body: `Drone pilot ${data.assignedPilotName || 'assigned'} has arrived at your farm.`,
                      type: 'PILOT_ARRIVED',
                      bookingId,
                    });
                  }
                }

                // Operation Started (status becomes inProgress)
                if (oldStatus !== 'inProgress' && newStatus === 'inProgress') {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Operation Started',
                      body: `Drone spraying operations have started for your booking (${bookingId}).`,
                      type: 'OPERATION_STARTED',
                      bookingId,
                    });
                  }
                }

                // Operation Completed (status becomes completed)
                if (oldStatus !== 'completed' && newStatus === 'completed') {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Operation Completed',
                      body: `Spraying operations have been completed by the pilot. Please confirm completion.`,
                      type: 'OPERATION_COMPLETED',
                      bookingId,
                    });
                  }
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'Spray Completed',
                      body: `Spraying operations have been completed by the pilot for booking (${bookingId}).`,
                      type: 'OPERATION_COMPLETED',
                      bookingId,
                    });
                  }
                }

                // Report Uploaded (missionPhotos or missionNotes goes from empty to non-empty)
                const isReportUploaded = (!oldHasPhotos && newHasPhotos) || (!oldHasNotes && newHasNotes);
                if (isReportUploaded) {
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Mission Report Uploaded',
                      body: `The pilot has uploaded the mission report and flight logs for booking (${bookingId}).`,
                      type: 'REPORT_UPLOADED',
                      bookingId,
                    });
                  }
                  // Notify Admins
                  await this.notifyAdmins(
                    'Mission Report Uploaded',
                    `The pilot has uploaded the mission report for booking (${bookingId}).`,
                    'REPORT_UPLOADED',
                    bookingId
                  );
                  // Notify Operations
                  await this.notifyOperations(
                    'Mission Report Uploaded',
                    `The pilot has uploaded the mission report for booking (${bookingId}).`,
                    'REPORT_UPLOADED',
                    bookingId
                  );
                }

                // Booking Completed (status becomes closed or farmerConfirmed)
                const wasCompleted = oldStatus !== 'closed' && oldStatus !== 'farmerConfirmed';
                const isCompletedNow = newStatus === 'closed' || newStatus === 'farmerConfirmed';
                if (wasCompleted && isCompletedNow) {
                  // Notify Farmer
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Booking Completed',
                      body: `Your service booking (${bookingId}) is now completed and closed.`,
                      type: 'BOOKING_COMPLETED',
                      bookingId,
                    });
                  }
                  // Notify Operations
                  await this.notifyOperations(
                    'Booking Completed',
                    `Service booking (${bookingId}) has been successfully completed.`,
                    'BOOKING_COMPLETED',
                    bookingId
                  );
                }

                // Payment Successful (paymentStatus becomes Paid)
                if (oldPaymentStatus !== 'Paid' && newPaymentStatus === 'Paid') {
                  // Notify Farmer
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Payment Successful',
                      body: `Payment of ₹${data.payableAmount || '0'} for booking (${bookingId}) has been successfully processed.`,
                      type: 'PAYMENT_SUCCESSFUL',
                      bookingId,
                    });
                  }
                  // Notify Creator Retailer
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'Payment Completed',
                      body: `Payment of ₹${data.payableAmount || '0'} for booking (${bookingId}) has been successfully processed.`,
                      type: 'PAYMENT_SUCCESSFUL',
                      bookingId,
                    });
                  }
                  // Notify Operations
                  await this.notifyOperations(
                    'Payment Successful',
                    `Payment of ₹${data.payableAmount || '0'} for booking (${bookingId}) has been successfully verified.`,
                    'PAYMENT_SUCCESSFUL',
                    bookingId
                  );
                  // Notify Admins
                  await this.notifyAdmins(
                    'Payment Successful',
                    `Payment of ₹${data.payableAmount || '0'} for booking (${bookingId}) has been successfully processed.`,
                    'PAYMENT_SUCCESSFUL',
                    bookingId
                  );
                }

                // Payment Failed (paymentStatus transitions to Failed or Deposit Rejected)
                const wasNotFailed = oldPaymentStatus !== 'Failed' && oldPaymentStatus !== 'Deposit Rejected';
                const isFailedNow = newPaymentStatus === 'Failed' || newPaymentStatus === 'Deposit Rejected';
                if (wasNotFailed && isFailedNow) {
                  // Notify Admins
                  await this.notifyAdmins(
                    'Payment Failed',
                    `Payment failed for booking (${bookingId}) with status: ${newPaymentStatus}.`,
                    'PAYMENT_FAILED',
                    bookingId
                  );
                }

                // --- 3. Booking Rescheduled Transition ---
                const isRescheduled = (oldBookingDateStr && newBookingDateStr && oldBookingDateStr !== newBookingDateStr) ||
                                      (oldPreferredTimeStr && newPreferredTimeStr && oldPreferredTimeStr !== newPreferredTimeStr);

                if (isRescheduled) {
                  const formattedDate = data.bookingDate ? new Date(data.bookingDate.toDate()).toLocaleDateString() : '';
                  const formattedTime = newPreferredTimeStr;

                  // Notify Farmer
                  if (data.farmerUid) {
                    await NotificationService.sendNotification({
                      recipientUid: data.farmerUid,
                      title: 'Booking Rescheduled',
                      body: `Your service booking (${bookingId}) has been rescheduled to ${formattedDate} at ${formattedTime}.`,
                      type: 'BOOKING_RESCHEDULED',
                      bookingId,
                    });
                  }
                  // Notify Creator Retailer
                  if (data.createdByRetailerId) {
                    await NotificationService.sendNotification({
                      recipientUid: data.createdByRetailerId,
                      title: 'Booking Rescheduled',
                      body: `Service booking (${bookingId}) has been rescheduled to ${formattedDate} at ${formattedTime}.`,
                      type: 'BOOKING_RESCHEDULED',
                      bookingId,
                    });
                  }
                  // Notify Assigned Pilot
                  if (newPilotId) {
                    await NotificationService.sendNotification({
                      recipientUid: newPilotId,
                      title: 'Booking Rescheduled',
                      body: `The service booking (${bookingId}) you are assigned to has been rescheduled to ${formattedDate} at ${formattedTime}.`,
                      type: 'BOOKING_RESCHEDULED',
                      bookingId,
                    });
                  }
                }
              } else {
                // If it wasn't in cache, add it now
                this.bookingCache.set(bookingId, {
                  status: newStatus,
                  assignedPilotId: newPilotId,
                  paymentStatus: newPaymentStatus,
                  hasPhotos: newHasPhotos,
                  hasNotes: newHasNotes,
                  bookingDate: newBookingDateStr,
                  preferredTime: newPreferredTimeStr,
                });
              }
            } else if (change.type === 'removed') {
              this.bookingCache.delete(bookingId);
            }
          }
        },
        (error) => {
          console.error('[WorkflowListenerService] Firestore listener error:', error);
        }
      );
    } catch (error) {
      console.error('[WorkflowListenerService] Initialization failed:', error);
    }
  }

  /**
   * Helper method to broadcast a notification to all operations staff.
   */
  private static async notifyOperations(title: string, body: string, type: string, bookingId: string): Promise<void> {
    try {
      const opsUsers = await admin.firestore().collection('users').where('role', '==', 'operations').get();
      const promises: Promise<any>[] = [];
      opsUsers.forEach((doc) => {
        promises.push(
          NotificationService.sendNotification({
            recipientUid: doc.data().uid || doc.id,
            title,
            body,
            type,
            bookingId,
          }).catch((err) =>
            console.error(`[WorkflowListenerService] Failed to send ops notification to ${doc.id}:`, err)
          )
        );
      });
      await Promise.all(promises);
    } catch (error) {
      console.error('[WorkflowListenerService] Error notifying operations team:', error);
    }
  }

  /**
   * Helper method to broadcast a notification to all admins.
   */
  private static async notifyAdmins(title: string, body: string, type: string, bookingId?: string): Promise<void> {
    try {
      const adminUsers = await admin.firestore().collection('users').where('role', '==', 'admin').get();
      const promises: Promise<any>[] = [];
      adminUsers.forEach((doc) => {
        promises.push(
          NotificationService.sendNotification({
            recipientUid: doc.data().uid || doc.id,
            title,
            body,
            type,
            bookingId,
          }).catch((err) =>
            console.error(`[WorkflowListenerService] Failed to send admin notification to ${doc.id}:`, err)
          )
        );
      });
      await Promise.all(promises);
    } catch (error) {
      console.error('[WorkflowListenerService] Error notifying admin team:', error);
    }
  }
}
