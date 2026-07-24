import { Timestamp } from 'firebase-admin/firestore';

export enum PaymentStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
  REFUNDED = 'REFUNDED',
}

export enum PaymentMode {
  PHONEPE = 'PHONEPE',
  UPI = 'UPI',
  CASH = 'CASH',
  UNKNOWN = 'UNKNOWN',
}

export enum PaymentGateway {
  PHONEPE = 'PHONEPE',
}

export interface PaymentDocument {
  paymentId: string;
  bookingId: string;
  userId: string;
  merchantTransactionId: string;
  transactionId: string | null;
  amount: number;
  currency: string;
  status: PaymentStatus;
  paymentMode: PaymentMode;
  gateway: PaymentGateway;
  gatewayResponse: Record<string, unknown> | null;
  createdAt: Date | Timestamp;
  updatedAt: Date | Timestamp;
  completedAt: Date | Timestamp | null;
  failureReason: string | null;
  metadata: Record<string, unknown> | null;
}

export interface CreatePaymentDTO {
  bookingId: string;
  userId: string;
  amount: number;
  currency?: string;
  paymentMode?: PaymentMode;
  gateway?: PaymentGateway;
  merchantTransactionId?: string;
  metadata?: Record<string, unknown>;
}

export interface UpdatePaymentStatusDTO {
  paymentId: string;
  status: PaymentStatus;
  transactionId?: string | null;
  failureReason?: string | null;
  gatewayResponse?: Record<string, unknown> | null;
}
