import * as admin from 'firebase-admin';
import { config } from '../config/env.config';

/**
 * Singleton Firebase Admin SDK initialization module.
 * Ensures Firebase Admin app is initialized exactly once.
 */
if (admin.apps.length === 0) {
  if (config.firebase.projectId && config.firebase.clientEmail && config.firebase.privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.firebase.projectId,
        clientEmail: config.firebase.clientEmail,
        privateKey: config.firebase.privateKey,
      }),
    });
  } else {
    // Fallback: Default application credentials with configured project ID
    admin.initializeApp({
      projectId: config.firebase.projectId || 'lakshya-aerotech',
    });
  }
}

export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
export const messaging = admin.messaging();

export default admin;
