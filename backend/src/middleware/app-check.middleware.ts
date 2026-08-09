import { NextFunction, Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { config } from '../config';

export async function requireAppCheck(
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (!config.enforceAppCheck) {
    next();
    return;
  }

  const token = req.header('X-Firebase-AppCheck');
  if (!token) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Missing App Check token.',
    });
  }

  try {
    await admin.appCheck().verifyToken(token);
    next();
  } catch (_) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: Invalid App Check token.',
    });
  }
}
