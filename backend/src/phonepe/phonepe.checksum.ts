import crypto from 'crypto';
import { phonePeConfig } from './phonepe.config';
import { ChecksumResult } from './phonepe.types';

export class PhonePeChecksumUtil {
  /**
   * Encodes a JSON payload object to a Base64 string.
   */
  static encodePayload<T extends Record<string, unknown>>(payload: T): string {
    const jsonString = JSON.stringify(payload);
    return Buffer.from(jsonString).toString('base64');
  }

  /**
   * Decodes a Base64 encoded payload string to a JSON object.
   */
  static decodePayload<T>(base64Payload: string): T {
    const jsonString = Buffer.from(base64Payload, 'base64').toString('utf-8');
    return JSON.parse(jsonString) as T;
  }

  /**
   * Calculates SHA-256 hash formatted as lowercase hex string.
   */
  private static sha256(input: string): string {
    return crypto.createHash('sha256').update(input).digest('hex');
  }

  /**
   * Generates Base64 payload and X-VERIFY header for POST requests (Pay / Refund API).
   * Formula: SHA256(base64Payload + apiEndpoint + saltKey) + "###" + saltIndex
   */
  static generatePayChecksum<T extends Record<string, unknown>>(
    payload: T,
    apiEndpoint: string
  ): ChecksumResult {
    const base64Payload = this.encodePayload(payload);
    const stringToHash = `${base64Payload}${apiEndpoint}${phonePeConfig.saltKey}`;
    const sha256Hash = this.sha256(stringToHash);
    const checksum = `${sha256Hash}###${phonePeConfig.saltIndex}`;

    return {
      base64Payload,
      checksum,
      xVerifyHeader: checksum,
    };
  }

  /**
   * Generates X-VERIFY header for GET requests (Status Check API).
   * Formula: SHA256(apiEndpoint + saltKey) + "###" + saltIndex
   */
  static generateStatusChecksum(apiEndpoint: string): string {
    const stringToHash = `${apiEndpoint}${phonePeConfig.saltKey}`;
    const sha256Hash = this.sha256(stringToHash);
    return `${sha256Hash}###${phonePeConfig.saltIndex}`;
  }

  /**
   * Verifies incoming PhonePe Webhook callback X-VERIFY signature.
   * Formula: SHA256(base64ResponseBody + saltKey) + "###" + saltIndex === receivedXVerify
   */
  static verifyWebhookSignature(base64ResponseBody: string, receivedXVerify: string): boolean {
    if (!base64ResponseBody || !receivedXVerify) {
      return false;
    }
    const stringToHash = `${base64ResponseBody}${phonePeConfig.saltKey}`;
    const sha256Hash = this.sha256(stringToHash);
    const expectedChecksum = `${sha256Hash}###${phonePeConfig.saltIndex}`;

    const expectedBuffer = Buffer.from(expectedChecksum, 'utf-8');
    const receivedBuffer = Buffer.from(receivedXVerify, 'utf-8');
    if (expectedBuffer.length !== receivedBuffer.length) {
      return false;
    }
    return crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
  }
}
