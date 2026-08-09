import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosError } from 'axios';
import { phonePeConfig } from './phonepe.config';

export class PhonePeHttpClient {
  private static instance: AxiosInstance;

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
          console.log(
            `[PhonePeHttpClient] [OUTGOING REQUEST] ${config.method?.toUpperCase()} ${config.url}`
          );
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
          console.log(
            `[PhonePeHttpClient] [INCOMING RESPONSE] ${response.status} ${response.config.url}`
          );
          return response;
        },
        (error: AxiosError) => {
          if (error.code === 'ECONNABORTED') {
            console.error(`[PhonePeHttpClient] [TIMEOUT ERROR] Request timed out after ${phonePeConfig.timeout}ms on ${error.config?.url}`);
          } else if (error.response) {
            console.error(
              `[PhonePeHttpClient] [HTTP ERROR RESPONSE] Status: ${error.response.status} on ${error.config?.url}`
            );
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
