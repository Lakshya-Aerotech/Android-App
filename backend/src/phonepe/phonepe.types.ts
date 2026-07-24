export enum PhonePePaymentInstrumentType {
  PAY_PAGE = 'PAY_PAGE',
  UPI_INTENT = 'UPI_INTENT',
  UPI_COLLECT = 'UPI_COLLECT',
}

export interface PhonePePaymentInstrument {
  type: PhonePePaymentInstrumentType | string;
  targetApp?: string;
  vpa?: string;
}

export interface PhonePePayRequestPayload {
  merchantId: string;
  merchantTransactionId: string;
  merchantUserId: string;
  amount: number;
  redirectUrl: string;
  redirectMode: 'REDIRECT' | 'POST';
  callbackUrl: string;
  mobileNumber?: string;
  paymentInstrument: PhonePePaymentInstrument;
}

export interface PhonePeRedirectInfo {
  url: string;
  method: 'GET' | 'POST';
}

export interface PhonePeInstrumentResponse {
  type: string;
  redirectInfo?: PhonePeRedirectInfo;
  intentUrl?: string;
}

export interface PhonePePayResponseData {
  merchantId: string;
  merchantTransactionId: string;
  instrumentResponse: PhonePeInstrumentResponse;
}

export interface PhonePePayResponse {
  success: boolean;
  code: string;
  message: string;
  data: PhonePePayResponseData;
}

export interface PhonePePaymentOption {
  type: string;
  amount: number;
  utr?: string;
}

export interface PhonePeStatusResponseData {
  merchantId: string;
  merchantTransactionId: string;
  transactionId: string;
  amount: number;
  paymentState: 'COMPLETED' | 'FAILED' | 'PENDING' | string;
  responseCode: string;
  responseCodeDescription?: string;
  paymentOption?: PhonePePaymentOption;
}

export interface PhonePeStatusResponse {
  success: boolean;
  code: string;
  message: string;
  data: PhonePeStatusResponseData;
}

export interface PhonePeWebhookPayload {
  response: string; // Base64 encoded payload string
}

export interface PhonePeDecodedWebhookResponse {
  success: boolean;
  code: string;
  message: string;
  data: PhonePeStatusResponseData;
}

export interface PhonePeErrorResponse {
  success: boolean;
  code: string;
  message: string;
  data?: Record<string, unknown>;
}

export interface ChecksumResult {
  base64Payload: string;
  checksum: string;
  xVerifyHeader: string;
}
