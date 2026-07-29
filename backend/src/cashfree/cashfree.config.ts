import { config } from '../config';

export interface CashfreeConfig {
  appId: string;
  secretKey: string;
  webhookSecret: string;
  apiVersion: string;
  baseUrl: string;
  returnUrl: string;
  environment: 'SANDBOX' | 'PRODUCTION';
  timeout: number;
}

/**
 * Reusable strongly-typed Cashfree configuration wrapper.
 * Dynamically evaluates properties from centralized config module.
 */
export const cashfreeConfig: CashfreeConfig = {
  get appId() {
    return (config.cashfree.appId || '').trim().replace(/^["']|["']$/g, '');
  },
  get secretKey() {
    return (config.cashfree.secretKey || '').trim().replace(/^["']|["']$/g, '');
  },
  get webhookSecret() {
    return config.cashfree.webhookSecret || config.cashfree.secretKey;
  },
  get apiVersion() {
    return config.cashfree.apiVersion || '2023-08-01';
  },
  get baseUrl() {
    if (config.cashfree.environment.toUpperCase() === 'PRODUCTION') {
      return 'https://api.cashfree.com/pg';
    }
    return config.cashfree.baseUrl || 'https://sandbox.cashfree.com/pg';
  },
  get returnUrl() {
    return config.cashfree.returnUrl;
  },
  get environment() {
    return (config.cashfree.environment.toUpperCase() === 'PRODUCTION'
      ? 'PRODUCTION'
      : 'SANDBOX') as 'SANDBOX' | 'PRODUCTION';
  },
  get timeout() {
    return config.cashfree.timeout || 10000;
  },
};

export default cashfreeConfig;
