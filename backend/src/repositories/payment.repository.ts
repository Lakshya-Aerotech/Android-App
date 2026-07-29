import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../firebase';
import {
  PaymentDocument,
  PaymentStatus,
  PaymentMode,
  PaymentGateway,
  CreatePaymentDTO,
} from '../models/payment.model';

export class PaymentRepository {
  private static collectionName = 'payments';

  /**
   * Creates a new Payment document in Firestore.
   */
  static async createPayment(
    merchantTxnId: string,
    data: CreatePaymentDTO
  ): Promise<PaymentDocument> {
    const docRef = db.collection(this.collectionName).doc();
    const paymentId = docRef.id;

    const now = FieldValue.serverTimestamp();

    const paymentData = {
      paymentId,
      bookingId: data.bookingId,
      userId: data.userId,
      merchantTransactionId: merchantTxnId,
      transactionId: null,
      amount: data.amount,
      currency: data.currency || 'INR',
      status: PaymentStatus.PENDING,
      paymentMode: data.paymentMode || PaymentMode.PHONEPE,
      gateway: data.gateway || PaymentGateway.PHONEPE,
      gatewayResponse: null,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      failureReason: null,
      metadata: data.metadata || null,
    };

    await docRef.set(paymentData);

    // Return structured object representation
    return {
      ...paymentData,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as unknown as PaymentDocument;
  }

  /**
   * Finds a payment document by document ID (paymentId).
   */
  static async findPaymentById(paymentId: string): Promise<PaymentDocument | null> {
    const doc = await db.collection(this.collectionName).doc(paymentId).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as PaymentDocument;
  }

  /**
   * Finds a payment document by merchantTransactionId.
   */
  static async findByMerchantTransactionId(
    merchantTransactionId: string
  ): Promise<PaymentDocument | null> {
    const snapshot = await db
      .collection(this.collectionName)
      .where('merchantTransactionId', '==', merchantTransactionId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    return snapshot.docs[0].data() as PaymentDocument;
  }

  /**
   * Checks if a merchant transaction ID already exists to prevent duplicates.
   * Returns true if available (no duplicate found), false if already exists.
   */
  static async preventDuplicateMerchantTransactionId(
    merchantTransactionId: string
  ): Promise<boolean> {
    const existing = await this.findByMerchantTransactionId(merchantTransactionId);
    return existing === null;
  }

  /**
   * Updates payment status, failure reason, and completedAt timestamp.
   */
  static async updateStatus(
    paymentId: string,
    status: PaymentStatus,
    failureReason?: string | null,
    completedAt?: Date | null
  ): Promise<PaymentDocument | null> {
    const docRef = db.collection(this.collectionName).doc(paymentId);
    const doc = await docRef.get();
    if (!doc.exists) {
      return null;
    }

    const updates: Record<string, any> = {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (failureReason !== undefined) {
      updates.failureReason = failureReason;
    }

    if (completedAt !== undefined) {
      updates.completedAt = completedAt ? Timestamp.fromDate(completedAt) : null;
    } else if (status === PaymentStatus.SUCCESS || status === PaymentStatus.FAILED || status === PaymentStatus.CANCELLED) {
      updates.completedAt = FieldValue.serverTimestamp();
    }

    await docRef.update(updates);

    const updatedDoc = await docRef.get();
    return updatedDoc.data() as PaymentDocument;
  }

  /**
   * Updates raw gateway response and gateway transaction ID.
   */
  static async updateGatewayResponse(
    paymentId: string,
    gatewayResponse: Record<string, unknown>,
    transactionId?: string
  ): Promise<PaymentDocument | null> {
    const docRef = db.collection(this.collectionName).doc(paymentId);
    const doc = await docRef.get();
    if (!doc.exists) {
      return null;
    }

    const updates: Record<string, any> = {
      gatewayResponse,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (transactionId) {
      updates.transactionId = transactionId;
    }

    await docRef.update(updates);

    const updatedDoc = await docRef.get();
    return updatedDoc.data() as PaymentDocument;
  }

  /**
   * Lists all payments associated with a specific user.
   */
  static async listPaymentsByUser(userId: string): Promise<PaymentDocument[]> {
    const snapshot = await db
      .collection(this.collectionName)
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs.map((doc: any) => doc.data() as PaymentDocument);
  }

  /**
   * Lists all payments associated with a specific booking.
   */
  static async listPaymentsByBooking(bookingId: string): Promise<PaymentDocument[]> {
    const snapshot = await db
      .collection(this.collectionName)
      .where('bookingId', '==', bookingId)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs.map((doc: any) => doc.data() as PaymentDocument);
  }

  /**
   * Atomically completes payment and updates related booking using a Firestore transaction.
   * Ensures idempotency: if payment is already completed/SUCCESS, skips mutation.
   */
  static async processPaymentCompletionTransaction(
    merchantTransactionId: string,
    status: PaymentStatus,
    transactionId: string | null,
    gatewayResponse: Record<string, unknown> | null,
    failureReason: string | null = null
  ): Promise<{ payment: PaymentDocument; alreadyProcessed: boolean } | null> {
    return await db.runTransaction(async (transaction: any) => {
      const paymentQuery = db
        .collection(this.collectionName)
        .where('merchantTransactionId', '==', merchantTransactionId)
        .limit(1);

      const querySnapshot = await transaction.get(paymentQuery);
      if (querySnapshot.empty) {
        console.warn(`[PaymentRepository] Transaction aborted: No payment found for merchantTxnId ${merchantTransactionId}`);
        return null;
      }

      const paymentDocRef = querySnapshot.docs[0].ref;
      const paymentData = querySnapshot.docs[0].data() as PaymentDocument;

      // 1. EXECUTE ALL READS FIRST (Firestore Transaction Rule)
      let bookingDocRef: FirebaseFirestore.DocumentReference | null = null;
      let bookingDocExists = false;

      if (paymentData.bookingId) {
        bookingDocRef = db.collection('bookings').doc(paymentData.bookingId);
        const bookingDoc = await transaction.get(bookingDocRef);
        bookingDocExists = bookingDoc.exists;

        if (!bookingDocExists) {
          const bookingQuery = db
            .collection('bookings')
            .where('bookingId', '==', paymentData.bookingId)
            .limit(1);
          const bookingQuerySnap = await transaction.get(bookingQuery);
          if (!bookingQuerySnap.empty) {
            bookingDocRef = bookingQuerySnap.docs[0].ref;
            bookingDocExists = true;
          }
        }
      }

      // Idempotency Check: If payment is already SUCCESS, return early without writing
      if (paymentData.status === PaymentStatus.SUCCESS) {
        console.log(`[PaymentRepository] Idempotency Check: Payment ${merchantTransactionId} is already SUCCESS. Skipping update.`);
        return { payment: paymentData, alreadyProcessed: true };
      }

      // 2. EXECUTE ALL WRITES AFTER READS
      const now = FieldValue.serverTimestamp();

      const paymentUpdates: Record<string, any> = {
        status,
        transactionId: transactionId || paymentData.transactionId,
        gatewayResponse: gatewayResponse || paymentData.gatewayResponse,
        updatedAt: now,
        completedAt: now,
      };

      if (failureReason) {
        paymentUpdates.failureReason = failureReason;
      }

      transaction.update(paymentDocRef, paymentUpdates);

      if (bookingDocRef && bookingDocExists) {
        const bookingUpdates: Record<string, any> = {
          paymentStatus: status,
          paymentId: paymentData.paymentId,
          merchantTransactionId: paymentData.merchantTransactionId,
          transactionId: transactionId || paymentData.transactionId || '',
          paymentCompletedAt: now,
        };

        if (status === PaymentStatus.SUCCESS) {
          bookingUpdates.status = 'pending'; // Submit booking for operations/admin approval!
        }

        transaction.update(bookingDocRef, bookingUpdates);
        console.log(`[PaymentRepository] Atomic update prepared for booking doc ${paymentData.bookingId}`);
      }

      const updatedPayment: PaymentDocument = {
        ...paymentData,
        status,
        transactionId: transactionId || paymentData.transactionId,
        gatewayResponse: gatewayResponse || paymentData.gatewayResponse,
        failureReason: failureReason || paymentData.failureReason,
        updatedAt: new Date(),
        completedAt: new Date(),
      };

      return { payment: updatedPayment, alreadyProcessed: false };
    });
  }
}
