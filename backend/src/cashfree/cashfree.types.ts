export interface CashfreeCustomerDetails {
  customer_id: string;
  customer_phone: string;
  customer_email?: string;
  customer_name?: string;
}

export interface CashfreeOrderMeta {
  return_url?: string;
  notify_url?: string;
  payment_methods?: string;
}

export interface CashfreeCreateOrderPayload {
  order_id: string;
  order_amount: number;
  order_currency: string;
  customer_details: CashfreeCustomerDetails;
  order_meta?: CashfreeOrderMeta;
  order_note?: string;
}

export interface CashfreeCreateOrderResponse {
  cf_order_id: string;
  order_id: string;
  payment_session_id: string;
  order_status: string;
  order_amount: number;
  order_currency: string;
  entity: string;
  created_at: string;
}

export interface CashfreeGetOrderResponse {
  cf_order_id: string;
  order_id: string;
  order_amount: number;
  order_currency: string;
  order_status: string; // "PAID" | "ACTIVE" | "EXPIRED" | "TERMINATED"
  payment_session_id?: string;
  entity: string;
  created_at: string;
}

export interface CashfreeWebhookPayload {
  data: {
    order: {
      order_id: string;
      order_amount: number;
      order_currency: string;
      order_tags?: Record<string, string>;
    };
    payment: {
      cf_payment_id: string;
      payment_status: string; // "SUCCESS" | "FAILED" | "CANCELLED" | "USER_DROPPED"
      payment_amount: number;
      payment_currency: string;
      payment_message?: string;
      payment_time?: string;
      bank_reference?: string;
      payment_group?: string;
    };
    customer_details?: CashfreeCustomerDetails;
  };
  event_time: string;
  type: string; // "PAYMENT_SUCCESS_WEBHOOK" | "PAYMENT_FAILED_WEBHOOK" | etc.
}

export interface CashfreeRefundPayload {
  refund_id: string;
  refund_amount: number;
  refund_currency?: string;
  refund_note?: string;
}

export interface CashfreeRefundResponse {
  cf_refund_id: string;
  refund_id: string;
  order_id: string;
  cf_payment_id: string;
  refund_amount: number;
  refund_status: string;
  entity: string;
  created_at: string;
}
