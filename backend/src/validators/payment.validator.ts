import { CreatePaymentDTO } from '../models/payment.model';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export class PaymentValidator {
  /**
   * Validates payload for creating a new pending payment.
   */
  static validateCreatePayment(payload: CreatePaymentDTO): ValidationResult {
    const errors: string[] = [];

    // 1. Validate bookingId
    if (!payload.bookingId || typeof payload.bookingId !== 'string' || payload.bookingId.trim() === '') {
      errors.push('Missing or invalid bookingId: Must be a non-empty string.');
    }

    // 2. Validate userId
    if (!payload.userId || typeof payload.userId !== 'string' || payload.userId.trim() === '') {
      errors.push('Missing or invalid userId: Must be a non-empty string.');
    }

    // 3. Validate amount (Reject zero or negative amounts)
    if (payload.amount === undefined || payload.amount === null || typeof payload.amount !== 'number' || isNaN(payload.amount)) {
      errors.push('Missing or invalid amount: Must be a valid numeric value.');
    } else if (payload.amount <= 0) {
      errors.push('Invalid amount: Amount must be greater than zero.');
    }

    // 4. Validate merchantTransactionId if explicitly passed
    if (payload.merchantTransactionId !== undefined && payload.merchantTransactionId !== null) {
      if (typeof payload.merchantTransactionId !== 'string' || payload.merchantTransactionId.trim() === '') {
        errors.push('Invalid merchantTransactionId: Must be a non-empty string when provided.');
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validates a merchant transaction ID format.
   */
  static validateMerchantTransactionId(merchantTransactionId: string): ValidationResult {
    const errors: string[] = [];
    if (!merchantTransactionId || typeof merchantTransactionId !== 'string' || merchantTransactionId.trim() === '') {
      errors.push('Missing or invalid merchantTransactionId: Must be a non-empty string.');
    }
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
}
