import dotenv from 'dotenv';
import path from 'path';

dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config({ path: path.resolve(process.cwd(), 'backend/.env') });

export interface EnvConfig {
  port: number;
  nodeEnv: string;
  cashfree: {
    appId: string;
    secretKey: string;
    webhookSecret: string;
    apiVersion: string;
    baseUrl: string;
    returnUrl: string;
    environment: string;
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
  cashfree: {
    appId: getEnvVar('CASHFREE_APP_ID', 'TEST_APP_ID'),
    secretKey: getEnvVar('CASHFREE_SECRET_KEY', 'TEST_SECRET_KEY'),
    webhookSecret: getEnvVar('CASHFREE_WEBHOOK_SECRET', ''),
    apiVersion: getEnvVar('CASHFREE_API_VERSION', '2023-08-01'),
    baseUrl: getEnvVar('CASHFREE_BASE_URL', 'https://sandbox.cashfree.com/pg'),
    returnUrl: getEnvVar('CASHFREE_RETURN_URL', 'http://localhost:3000/api/payment/redirect'),
    environment: getEnvVar('CASHFREE_ENV', 'SANDBOX'),
    timeout: parseInt(getEnvVar('CASHFREE_TIMEOUT', '10000'), 10),
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
    if (!cfg.cashfree.appId || cfg.cashfree.appId === 'TEST_APP_ID') missing.push('CASHFREE_APP_ID');
    if (!cfg.cashfree.secretKey || cfg.cashfree.secretKey === 'TEST_SECRET_KEY') missing.push('CASHFREE_SECRET_KEY');

    if (missing.length > 0) {
      throw new Error(
        `[CRITICAL STARTUP FAILURE] Production environment variables missing: ${missing.join(', ')}. Server execution halted.`
      );
    }
  }
}

validateStartupEnv(config);

export default config;
