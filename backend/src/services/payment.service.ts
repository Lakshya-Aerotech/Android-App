import crypto from 'crypto';
import * as admin from 'firebase-admin';
import { PaymentRepository } from '../repositories/payment.repository';
import { PaymentValidator } from '../validators/payment.validator';
import { PaymentDocument, PaymentStatus, CreatePaymentDTO, PaymentGateway, PaymentMode } from '../models/payment.model';

export class PaymentService {
  /**
   * Generates a unique Merchant Transaction / Order ID.
   * Format: ORDER_<TIMESTAMP>_<8_RANDOM_HEX>
   */
  static generateMerchantTransactionId(prefix: string = 'ORDER'): string {
    const timestamp = Date.now();
    const randomHex = crypto.randomBytes(4).toString('hex').toUpperCase();
    return `${prefix}_${timestamp}_${randomHex}`;
  }

  /**
   * Validates duplicate transactions by checking if a merchantTransactionId / order_id already exists in Firestore.
   * Throws an Error if a duplicate is found.
   */
  static async validateDuplicateTransaction(merchantTransactionId: string): Promise<void> {
    const isAvailable = await PaymentRepository.preventDuplicateMerchantTransactionId(merchantTransactionId);
    if (!isAvailable) {
      throw new Error(`Duplicate Transaction Error: Order ID '${merchantTransactionId}' already exists.`);
    }
  }

  /**
   * Validates booking ownership, status, and calculates exact amount from Firestore database.
   * Never trusts payment amount coming directly from untrusted mobile clients.
   */
  static async validateAndCalculateBookingAmount(
    bookingId: string,
    userId: string,
    requestedAmount?: number
  ): Promise<{ bookingData: any; calculatedAmount: number }> {
    let bookingDoc = await admin.firestore().collection('bookings').doc(bookingId).get();
    let bookingData: any = bookingDoc.exists ? bookingDoc.data() : null;

    if (!bookingData) {
      const snapshot = await admin
        .firestore()
        .collection('bookings')
        .where('bookingId', '==', bookingId)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        bookingData = snapshot.docs[0].data();
      }
    }

    if (!bookingData) {
      throw new Error(`Booking Verification Error: Booking '${bookingId}' not found.`);
    }
    
    // Authorization Check: Ensure user owns this booking
    const bookingOwnerId = bookingData.farmerUid || bookingData.userId || bookingData.farmerId;
    if (bookingOwnerId && bookingOwnerId !== userId) {
      throw new Error(`Authorization Error: User '${userId}' is not authorized to initiate payment for booking '${bookingId}'.`);
    }

    // Calculate server-side verified amount
    let calculatedAmount = bookingData.totalPrice || bookingData.estimatedPrice || bookingData.amount || requestedAmount || 0;
    if (typeof calculatedAmount === 'string') {
      calculatedAmount = parseFloat(calculatedAmount);
    }

    if (!calculatedAmount || calculatedAmount <= 0) {
      throw new Error(`Payment Validation Error: Invalid calculated amount ₹${calculatedAmount} for booking '${bookingId}'.`);
    }

    return { bookingData, calculatedAmount };
  }

  /**
   * Creates a new Pending Payment record in Firestore.
   */
  static async createPendingPayment(data: CreatePaymentDTO): Promise<PaymentDocument> {
    // 1. Validate payload inputs
    const validation = PaymentValidator.validateCreatePayment(data);
    if (!validation.isValid) {
      throw new Error(`Validation Error: ${validation.errors.join(' ')}`);
    }

    // 2. Generate or ensure unique merchantTransactionId / order_id
    const merchantTxnId = data.merchantTransactionId || this.generateMerchantTransactionId();

    // 3. Ensure no duplicate transaction exists
    await this.validateDuplicateTransaction(merchantTxnId);

    // 4. Set gateway default to CASHFREE
    const paymentDTO: CreatePaymentDTO = {
      ...data,
      gateway: data.gateway || PaymentGateway.CASHFREE,
      paymentMode: data.paymentMode || PaymentMode.CASHFREE,
    };

    // 5. Delegate to repository
    return await PaymentRepository.createPayment(merchantTxnId, paymentDTO);
  }

  /**
   * Retrieves a payment by document ID.
   */
  static async getPayment(paymentId: string): Promise<PaymentDocument | null> {
    if (!paymentId || paymentId.trim() === '') {
      throw new Error('Payment ID is required.');
    }
    return await PaymentRepository.findPaymentById(paymentId);
  }

  /**
   * Retrieves a payment by merchantTransactionId / order_id.
   */
  static async getPaymentByMerchantTransactionId(merchantTransactionId: string): Promise<PaymentDocument | null> {
    const validation = PaymentValidator.validateMerchantTransactionId(merchantTransactionId);
    if (!validation.isValid) {
      throw new Error(`Validation Error: ${validation.errors.join(' ')}`);
    }
    return await PaymentRepository.findByMerchantTransactionId(merchantTransactionId);
  }

  /**
   * Updates payment status.
   */
  static async updatePaymentStatus(
    paymentId: string,
    status: PaymentStatus,
    failureReason?: string | null
  ): Promise<PaymentDocument | null> {
    if (!paymentId || paymentId.trim() === '') {
      throw new Error('Payment ID is required.');
    }

    return await PaymentRepository.updateStatus(paymentId, status, failureReason);
  }

  /**
   * Lists payments by User ID.
   */
  static async getPaymentsByUser(userId: string): Promise<PaymentDocument[]> {
    if (!userId || userId.trim() === '') {
      throw new Error('User ID is required.');
    }
    return await PaymentRepository.listPaymentsByUser(userId);
  }

  /**
   * Lists payments by Booking ID.
   */
  static async getPaymentsByBooking(bookingId: string): Promise<PaymentDocument[]> {
    if (!bookingId || bookingId.trim() === '') {
      throw new Error('Booking ID is required.');
    }
    return await PaymentRepository.listPaymentsByBooking(bookingId);
  }

  /**
   * Processes and finalizes payment completion and updates booking document atomically.
   */
  static async processPaymentResult(
    merchantTransactionId: string,
    status: PaymentStatus,
    transactionId: string | null,
    gatewayResponse: Record<string, unknown> | null,
    failureReason: string | null = null
  ): Promise<{ payment: PaymentDocument; alreadyProcessed: boolean } | null> {
    const validation = PaymentValidator.validateMerchantTransactionId(merchantTransactionId);
    if (!validation.isValid) {
      throw new Error(`Validation Error: ${validation.errors.join(' ')}`);
    }

    return await PaymentRepository.processPaymentCompletionTransaction(
      merchantTransactionId,
      status,
      transactionId,
      gatewayResponse,
      failureReason
    );
  }
}
