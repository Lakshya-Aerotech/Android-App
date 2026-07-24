import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosError } from 'axios';
import { phonePeConfig } from './phonepe.config';

export class PhonePeHttpClient {
  private static instance: AxiosInstance;

  /**
   * Safe log sanitizer to strip or mask credentials before logging.
   */
  private static sanitizeLog(obj: unknown): string {
    try {
      const logStr = JSON.stringify(obj, (key, value) => {
        const lowerKey = key.toLowerCase();
        if (
          lowerKey.includes('salt') ||
          lowerKey.includes('secret') ||
          lowerKey.includes('key') ||
          lowerKey.includes('authorization') ||
          lowerKey.includes('x-verify')
        ) {
          return '[REDACTED]';
        }
        return value;
      });
      return logStr;
    } catch {
      return '[Unparseable Data]';
    }
  }

  /**
   * Initializes or returns the singleton Axios instance configured for PhonePe API calls.
   */
  public static getClient(): AxiosInstance {
    if (!this.instance) {
      this.instance = axios.create({
        baseURL: phonePeConfig.baseUrl,
        timeout: phonePeConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
      });

      // Request Interceptor for logging
      this.instance.interceptors.request.use(
        (config: InternalAxiosRequestConfig) => {
          const sanitizedHeaders = this.sanitizeLog(config.headers);
          const sanitizedData = this.sanitizeLog(config.data);
          console.log(`[PhonePeHttpClient] [OUTGOING REQUEST] ${config.method?.toUpperCase()} ${config.url}
            Headers: ${sanitizedHeaders}
            Payload: ${sanitizedData}`);
          return config;
        },
        (error: AxiosError) => {
          console.error('[PhonePeHttpClient] [REQUEST SETUP ERROR]:', error.message);
          return Promise.reject(error);
        }
      );

      // Response Interceptor for logging
      this.instance.interceptors.response.use(
        (response: AxiosResponse) => {
          console.log(`[PhonePeHttpClient] [INCOMING RESPONSE] ${response.status} ${response.config.url}
            Response Data: ${this.sanitizeLog(response.data)}`);
          return response;
        },
        (error: AxiosError) => {
          if (error.code === 'ECONNABORTED') {
            console.error(`[PhonePeHttpClient] [TIMEOUT ERROR] Request timed out after ${phonePeConfig.timeout}ms on ${error.config?.url}`);
          } else if (error.response) {
            console.error(`[PhonePeHttpClient] [HTTP ERROR RESPONSE] Status: ${error.response.status} on ${error.config?.url}
              Data: ${this.sanitizeLog(error.response.data)}`);
          } else {
            console.error(`[PhonePeHttpClient] [NETWORK ERROR] ${error.message}`);
          }
          return Promise.reject(error);
        }
      );
    }

    return this.instance;
  }
}
