import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios';
import { cashfreeConfig } from './cashfree.config';

export class CashfreeHttpClient {
  private static instance: AxiosInstance | null = null;

  public static getClient(): AxiosInstance {
    if (!this.instance) {
      this.instance = axios.create({
        baseURL: cashfreeConfig.baseUrl,
        timeout: cashfreeConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          'x-api-version': cashfreeConfig.apiVersion,
        },
      });

      // Request interceptor to attach authentication headers dynamically & log outbound requests
      this.instance.interceptors.request.use(
        (config: InternalAxiosRequestConfig) => {
          config.headers['x-client-id'] = cashfreeConfig.appId;
          config.headers['x-client-secret'] = cashfreeConfig.secretKey;
          config.headers['x-api-version'] = cashfreeConfig.apiVersion;

          const appIdVal = cashfreeConfig.appId;
          const maskedAppId = appIdVal.length > 6 
            ? `${appIdVal.slice(0, 4)}...${appIdVal.slice(-4)} (Len: ${appIdVal.length})` 
            : (appIdVal || 'EMPTY');

          console.log(`[CashfreeHttpClient] Outbound Request: ${config.method?.toUpperCase()} ${config.baseURL}${config.url} | AppID: ${maskedAppId} | API-Ver: ${cashfreeConfig.apiVersion}`);
          return config;
        },
        (error) => {
          console.error('[CashfreeHttpClient] Request Interceptor Error:', error);
          return Promise.reject(error);
        }
      );

      // Response interceptor
      this.instance.interceptors.response.use(
        (response: AxiosResponse) => {
          console.log(`[CashfreeHttpClient] Response Status: ${response.status} from ${response.config.url}`);
          return response;
        },
        (error) => {
          if (error.response) {
            console.error(`[CashfreeHttpClient] Error Status: ${error.response.status} | Data:`, JSON.stringify(error.response.data));
          } else {
            console.error(`[CashfreeHttpClient] Network/Gateway Error: ${error.message}`);
          }
          return Promise.reject(error);
        }
      );
    }

    return this.instance;
  }
}

export default CashfreeHttpClient;
