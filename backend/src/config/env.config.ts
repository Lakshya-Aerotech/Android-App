import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export interface EnvConfig {
  port: number;
  nodeEnv: string;
  corsAllowedOrigins: string[];
  paymentMocksEnabled: boolean;
  enforceAppCheck: boolean;
  bookingRatePerAcre: number;
  phonePe: {
    merchantId: string;
    saltKey: string;
    saltIndex: string;
    baseUrl: string;
    callbackUrl: string;
    timeout: number;
  };
  firebase: {
    useApplicationDefaultCredentials: boolean;
    projectId: string;
    clientEmail: string;
    privateKey: string;
    storageBucket: string;
  };
}

const getEnvVar = (key: string, defaultValue: string = ''): string => {
  return process.env[key] || defaultValue;
};

const getBooleanEnvVar = (key: string, defaultValue = false): boolean => {
  const value = process.env[key];
  if (value === undefined) return defaultValue;
  return value.toLowerCase() === 'true';
};

export const config: EnvConfig = {
  port: parseInt(getEnvVar('PORT', '3000'), 10),
  nodeEnv: getEnvVar('NODE_ENV', 'development'),
  corsAllowedOrigins: getEnvVar(
    'CORS_ALLOWED_ORIGINS',
    'http://localhost:3000,http://localhost:8080'
  )
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  paymentMocksEnabled: getBooleanEnvVar('ENABLE_PAYMENT_MOCKS', false),
  enforceAppCheck: getBooleanEnvVar('ENFORCE_APP_CHECK', false),
  bookingRatePerAcre: parseFloat(getEnvVar('BOOKING_RATE_PER_ACRE', '800')),
  phonePe: {
    merchantId: getEnvVar('PHONEPE_MERCHANT_ID'),
    saltKey: getEnvVar('PHONEPE_SALT_KEY'),
    saltIndex: getEnvVar('PHONEPE_SALT_INDEX', '1'),
    baseUrl: getEnvVar('PHONEPE_BASE_URL'),
    callbackUrl: getEnvVar('PHONEPE_CALLBACK_URL'),
    timeout: parseInt(getEnvVar('PHONEPE_TIMEOUT', '10000'), 10),
  },
  firebase: {
    useApplicationDefaultCredentials: getBooleanEnvVar(
      'FIREBASE_USE_APPLICATION_DEFAULT',
      false
    ),
    projectId: getEnvVar('FIREBASE_PROJECT_ID'),
    clientEmail: getEnvVar('FIREBASE_CLIENT_EMAIL'),
    privateKey: getEnvVar('FIREBASE_PRIVATE_KEY') ? getEnvVar('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n') : '',
    storageBucket: getEnvVar('FIREBASE_STORAGE_BUCKET'),
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
    if (!process.env.CORS_ALLOWED_ORIGINS) missing.push('CORS_ALLOWED_ORIGINS');
    if (!process.env.BOOKING_RATE_PER_ACRE) missing.push('BOOKING_RATE_PER_ACRE');
    if (!cfg.enforceAppCheck) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] ENFORCE_APP_CHECK must be true in production.'
      );
    }
    if (!cfg.firebase.useApplicationDefaultCredentials &&
        !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      if (!cfg.firebase.projectId) missing.push('FIREBASE_PROJECT_ID');
      if (!cfg.firebase.clientEmail) missing.push('FIREBASE_CLIENT_EMAIL');
      if (!cfg.firebase.privateKey) missing.push('FIREBASE_PRIVATE_KEY');
    }
    if (!cfg.firebase.storageBucket) missing.push('FIREBASE_STORAGE_BUCKET');
    if (cfg.paymentMocksEnabled) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] ENABLE_PAYMENT_MOCKS must be false in production.'
      );
    }

    if (missing.length > 0) {
      throw new Error(
        `[CRITICAL STARTUP FAILURE] Production environment variables missing: ${missing.join(', ')}. Server execution halted.`
      );
    }
    if (!cfg.phonePe.baseUrl.startsWith('https://') ||
        !cfg.phonePe.callbackUrl.startsWith('https://')) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] Production PhonePe URLs must use HTTPS.'
      );
    }
    if (!new URL(cfg.phonePe.callbackUrl).pathname.endsWith('/api/payment/webhook')) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] PHONEPE_CALLBACK_URL must end with /api/payment/webhook.'
      );
    }
    if (cfg.corsAllowedOrigins.some((origin) => !origin.startsWith('https://'))) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] Production CORS origins must use HTTPS.'
      );
    }
    if (!Number.isFinite(cfg.bookingRatePerAcre) || cfg.bookingRatePerAcre <= 0) {
      throw new Error(
        '[CRITICAL STARTUP FAILURE] BOOKING_RATE_PER_ACRE must be a positive number.'
      );
    }
  }
}

validateStartupEnv(config);

export default config;
