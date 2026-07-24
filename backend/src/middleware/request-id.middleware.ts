import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import { Logger } from '../utils/logger';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      id?: string;
      startTime?: number;
    }
  }
}

export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId = (req.headers['x-request-id'] as string) || crypto.randomUUID();
  req.id = requestId;
  req.startTime = Date.now();

  res.setHeader('X-Request-ID', requestId);

  // Log incoming request
  Logger.info(`Incoming HTTP Request: ${req.method} ${req.originalUrl}`, {
    requestId,
    endpoint: req.originalUrl,
    method: req.method,
  });

  // Intercept response finish event for execution time logging
  res.on('finish', () => {
    const executionTimeMs = req.startTime ? Date.now() - req.startTime : 0;
    Logger.info(`Completed HTTP Request: ${req.method} ${req.originalUrl} ${res.statusCode}`, {
      requestId,
      endpoint: req.originalUrl,
      method: req.method,
      statusCode: res.statusCode,
      executionTimeMs,
    });
  });

  next();
}
