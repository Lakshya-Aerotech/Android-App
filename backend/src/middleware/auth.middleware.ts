import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { HTTP_STATUS } from '../config';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    role: string;
    name?: string;
  };
}

export async function requireAuth(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    if (process.env.NODE_ENV === 'development') {
      req.user = {
        uid: (req.body.userId as string) || (req.body.farmerUid as string) || 'USER_FARMER_501',
        email: 'dev@lakshya.app',
        role: 'farmer',
        name: 'Development Test User',
      };
      return next();
    }
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      error: 'Unauthorized: Missing or invalid authorization header.',
    });
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    console.log('--- [AuthMiddleware] REQUIRE AUTH VERIFICATION ---');
    console.log(`Authenticated UID: ${uid}`);
    console.log(`Email: ${decodedToken.email}`);
    console.log(`Collection Query: users where('uid', '==', '${uid}')`);

    // Fetch user details from Firestore by uid field to handle both cases
    let userData: any = null;
    let userDocId: string | null = null;

    const usersSnapshot = await admin
      .firestore()
      .collection('users')
      .where('uid', '==', uid)
      .get();

    if (!usersSnapshot.empty) {
      const doc = usersSnapshot.docs[0];
      userData = doc.data();
      userDocId = doc.id;
      console.log(`User Document Found in query: Yes (Doc ID: ${userDocId})`);
    } else {
      console.log(`User Document Found in query: No. Performing fallback search by Doc ID...`);
      // Fallback: check if doc ID is uid directly
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      if (userDoc.exists) {
        userData = userDoc.data();
        userDocId = userDoc.id;
        console.log(`User Document Found by fallback Doc ID: Yes`);
      } else {
        console.log(`User Document Found by fallback Doc ID: No`);
      }
    }

    if (!userData) {
      console.warn(`[AuthMiddleware] User document not found in Firestore for authenticated UID: ${uid}`);
      console.log('--------------------------------------------------');
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        error: `Unauthorized: User document not found in Firestore for UID ${uid}.`,
      });
    }

    console.log(`Role: ${userData.role}`);
    console.log(`Name: ${userData.name}`);
    console.log('--------------------------------------------------');

    req.user = {
      uid,
      email: decodedToken.email,
      role: userData?.role || 'unknown',
      name: userData?.name || '',
    };

    next();
  } catch (error: any) {
    console.error(`[AuthMiddleware] Token verification failed: ${error?.message || error}`);
    console.error(error?.stack || '');
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      error: 'Unauthorized: Token verification failed.',
    });
  }
}

export function requireRole(roles: string[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      console.warn('[AuthMiddleware] requireRole - Unauthorized: No user on request');
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({
        success: false,
        error: 'Unauthorized: Authentication required.',
      });
    }

    console.log('--- [AuthMiddleware] REQUIRE ROLE VERIFICATION ---');
    console.log(`User UID: ${req.user.uid}`);
    console.log(`User Role: ${req.user.role}`);
    console.log(`Required Roles: [${roles.join(', ')}]`);

    if (!roles.includes(req.user.role)) {
      console.warn(`Authorization result: FORBIDDEN`);
      console.log('--------------------------------------------------');
      return res.status(HTTP_STATUS.FORBIDDEN).json({
        success: false,
        error: `Forbidden: Access restricted to roles: [${roles.join(', ')}]`,
      });
    }

    console.log(`Authorization result: SUCCESS`);
    console.log('--------------------------------------------------');
    next();
  };
}
