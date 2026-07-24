import { config } from '../config';

export interface PhonePeConfig {
  merchantId: string;
  saltKey: string;
  saltIndex: string;
  baseUrl: string;
  callbackUrl: string;
  environment: string;
  timeout: number;
}

/**
 * Reusable strongly-typed PhonePe configuration wrapper.
 * Dynamically evaluates properties from the centralized config module.
 */
export const phonePeConfig: PhonePeConfig = {
  get merchantId() {
    return config.phonePe.merchantId;
  },
  get saltKey() {
    return config.phonePe.saltKey;
  },
  get saltIndex() {
    return config.phonePe.saltIndex;
  },
  get baseUrl() {
    return config.phonePe.baseUrl;
  },
  get callbackUrl() {
    return config.phonePe.callbackUrl;
  },
  get environment() {
    return config.nodeEnv;
  },
  get timeout() {
    return config.phonePe.timeout;
  },
};

export default phonePeConfig;
