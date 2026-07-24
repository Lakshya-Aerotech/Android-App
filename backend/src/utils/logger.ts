export interface LogMeta {
  requestId?: string;
  endpoint?: string;
  method?: string;
  statusCode?: number;
  executionTimeMs?: number;
  [key: string]: unknown;
}

export class Logger {
  /**
   * Sanitizes objects to redact sensitive secrets before logging.
   */
  private static sanitize(data: unknown): unknown {
    if (!data) return data;
    if (typeof data !== 'object') return data;

    try {
      const sanitized = JSON.parse(JSON.stringify(data));
      const redactKeys = ['saltkey', 'saltindex', 'authorization', 'x-verify', 'privatekey', 'clientemail'];

      const walk = (obj: any) => {
        if (!obj || typeof obj !== 'object') return;
        for (const key of Object.keys(obj)) {
          if (redactKeys.includes(key.toLowerCase())) {
            obj[key] = '[REDACTED]';
          } else if (typeof obj[key] === 'object') {
            walk(obj[key]);
          }
        }
      };

      walk(sanitized);
      return sanitized;
    } catch {
      return '[Unparseable Data]';
    }
  }

  private static format(level: string, message: string, meta: LogMeta = {}): string {
    const sanitizedMeta = this.sanitize(meta);
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      message,
      ...(typeof sanitizedMeta === 'object' && sanitizedMeta !== null ? sanitizedMeta : { meta: sanitizedMeta }),
    });
  }

  static info(message: string, meta?: LogMeta): void {
    console.log(this.format('INFO', message, meta));
  }

  static warn(message: string, meta?: LogMeta): void {
    console.warn(this.format('WARN', message, meta));
  }

  static error(message: string, meta?: LogMeta): void {
    console.error(this.format('ERROR', message, meta));
  }

  static debug(message: string, meta?: LogMeta): void {
    console.debug(this.format('DEBUG', message, meta));
  }
}
