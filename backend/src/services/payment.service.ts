import crypto from 'crypto';
import { PaymentRepository } from '../repositories/payment.repository';
import { PaymentValidator } from '../validators/payment.validator';
import { PaymentDocument, PaymentStatus, CreatePaymentDTO } from '../models/payment.model';

export class PaymentService {
  /**
   * Generates a unique Merchant Transaction ID.
   * Format: MT_<TIMESTAMP>_<8_RANDOM_HEX>
   */
  static generateMerchantTransactionId(prefix: string = 'MT'): string {
    const timestamp = Date.now();
    const randomHex = crypto.randomBytes(4).toString('hex').toUpperCase();
    return `${prefix}_${timestamp}_${randomHex}`;
  }

  /**
   * Validates duplicate transactions by checking if a merchantTransactionId already exists in Firestore.
   * Throws an Error if a duplicate is found.
   */
  static async validateDuplicateTransaction(merchantTransactionId: string): Promise<void> {
    const isAvailable = await PaymentRepository.preventDuplicateMerchantTransactionId(merchantTransactionId);
    if (!isAvailable) {
      throw new Error(`Duplicate Transaction Error: Merchant Transaction ID '${merchantTransactionId}' already exists.`);
    }
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

    // 2. Generate or ensure unique merchantTransactionId
    const merchantTxnId = data.merchantTransactionId || this.generateMerchantTransactionId();

    // 3. Ensure no duplicate transaction exists
    await this.validateDuplicateTransaction(merchantTxnId);

    // 4. Delegate to repository
    return await PaymentRepository.createPayment(merchantTxnId, data);
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
   * Retrieves a payment by merchantTransactionId.
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
