import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export interface EnvConfig {
  port: number;
  nodeEnv: string;
  phonePe: {
    merchantId: string;
    saltKey: string;
    saltIndex: string;
    baseUrl: string;
    callbackUrl: string;
    timeout: number;
  };
  firebase: {
    projectId: string;
    clientEmail: string;
    privateKey: string;
  };
}

const getEnvVar = (key: string, defaultValue: string = ''): string => {
  return process.env[key] || defaultValue;
};

export const config: EnvConfig = {
  port: parseInt(getEnvVar('PORT', '3000'), 10),
  nodeEnv: getEnvVar('NODE_ENV', 'development'),
  phonePe: {
    merchantId: getEnvVar('PHONEPE_MERCHANT_ID'),
    saltKey: getEnvVar('PHONEPE_SALT_KEY'),
    saltIndex: getEnvVar('PHONEPE_SALT_INDEX', '1'),
    baseUrl: getEnvVar('PHONEPE_BASE_URL'),
    callbackUrl: getEnvVar('PHONEPE_CALLBACK_URL'),
    timeout: parseInt(getEnvVar('PHONEPE_TIMEOUT', '10000'), 10),
  },
  firebase: {
    projectId: getEnvVar('FIREBASE_PROJECT_ID'),
    clientEmail: getEnvVar('FIREBASE_CLIENT_EMAIL'),
    privateKey: getEnvVar('FIREBASE_PRIVATE_KEY') ? getEnvVar('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n') : '',
  },
};

/**
 * Validates environment variables on application startup.
 */
function validateStartupEnv(cfg: EnvConfig): void {
  if (cfg.nodeEnv === 'production') {
    const missing: string[] = [];
    if (!cfg.phonePe.merchantId) missing.push('PHONEPE_MERCHANT_ID');
    if (!cfg.phonePe.saltKey) missing.push('PHONEPE_SALT_KEY');
    if (!cfg.phonePe.baseUrl) missing.push('PHONEPE_BASE_URL');
    if (!cfg.phonePe.callbackUrl) missing.push('PHONEPE_CALLBACK_URL');

    if (missing.length > 0) {
      throw new Error(
        `[CRITICAL STARTUP FAILURE] Production environment variables missing: ${missing.join(', ')}. Server execution halted.`
      );
    }
  }
}

validateStartupEnv(config);

export default config;
