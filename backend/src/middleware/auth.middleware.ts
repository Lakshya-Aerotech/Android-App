import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { HTTP_STATUS } from '../config';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    docId: string;
    email?: string;
    role: string;
    name?: string;
  };
}

async function authenticate(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
  requireActiveAccount: boolean
) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      error: 'Unauthorized: Missing or invalid authorization header.',
    });
  }

  try {
    const token = authHeader.slice('Bearer '.length);
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();
    const userData = userDoc.exists ? userDoc.data() : null;

    if (!userData) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        error: 'Unauthorized: User profile is not provisioned.',
      });
    }

    if (
      requireActiveAccount &&
      (userData.isActive === false || userData.accountStatus === 'suspended')
    ) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        error: 'Forbidden: User account is inactive or suspended.',
      });
    }

    req.user = {
      uid: decodedToken.uid,
      docId: userDoc.id,
      email: decodedToken.email,
      role: userData.role || 'unknown',
      name: userData.name || '',
    };
    next();
  } catch (_) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      error: 'Unauthorized: Token verification failed.',
    });
  }
}

export async function requireAuth(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  return authenticate(req, res, next, true);
}

export async function requireAccountIdentity(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  return authenticate(req, res, next, false);
}

export function requireRole(roles: string[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        error: 'Unauthorized: Authentication required.',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        error: `Forbidden: Access restricted to roles: [${roles.join(', ')}]`,
      });
    }

    next();
  };
}
