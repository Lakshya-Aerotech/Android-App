import crypto from 'crypto';
import { NextFunction, Response, Router } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { auth, db, storage } from '../firebase';
import {
  AuthenticatedRequest,
  requireAccountIdentity,
  requireAuth,
  requireRole,
} from '../middleware/auth.middleware';
import { requireAppCheck } from '../middleware/app-check.middleware';
import { accountMutationRateLimiter } from '../middleware/rate-limit.middleware';

const router = Router();
const employeeRoles = new Set(['pilot', 'externalPilot', 'operations', 'admin']);

async function deleteMatchingDocuments(collection: string, field: string, value: string) {
  while (true) {
    const snapshot = await db.collection(collection).where(field, '==', value).limit(400).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();
  }
}

async function anonymizeMatchingDocuments(
  collection: string,
  field: string,
  value: string,
  updates: Record<string, unknown>
) {
  while (true) {
    const snapshot = await db.collection(collection).where(field, '==', value).limit(400).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((document) =>
      batch.update(document.ref, { ...updates, updatedAt: FieldValue.serverTimestamp() })
    );
    await batch.commit();
  }
}

async function hasActiveBookings(field: string, uid: string): Promise<boolean> {
  const snapshot = await db.collection('bookings').where(field, '==', uid).get();
  return snapshot.docs.some((document) => {
    const status = String(document.data().status || '');
    return status !== 'closed' && status !== 'cancelled';
  });
}

router.post(
  '/employees',
  requireAppCheck,
  requireAuth,
  requireRole(['admin']),
  accountMutationRateLimiter,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    let createdUid: string | null = null;
    try {
      const name = String(req.body.name || '').trim();
      const email = String(req.body.email || '').trim().toLowerCase();
      const phoneNumber = String(req.body.phoneNumber || '').trim();
      const role = String(req.body.role || '').trim();
      const preferredLanguage = String(req.body.preferredLanguage || 'en').trim();
      const isActive = req.body.isActive !== false;

      if (!name || !email || !email.includes('@') || !employeeRoles.has(role)) {
        return res.status(400).json({
          success: false,
          error: 'A valid name, email, and employee role are required.',
        });
      }

      try {
        await auth.getUserByEmail(email);
        return res.status(409).json({
          success: false,
          error: 'An authentication account already exists for this email.',
        });
      } catch (error: any) {
        if (error?.code !== 'auth/user-not-found') throw error;
      }

      const temporaryPassword = crypto.randomBytes(32).toString('base64url');
      const authUser = await auth.createUser({
        email,
        password: temporaryPassword,
        displayName: name,
        disabled: !isActive,
        emailVerified: false,
      });
      createdUid = authUser.uid;

      await db.collection('users').doc(authUser.uid).set({
        uid: authUser.uid,
        name,
        email,
        phoneNumber,
        role,
        preferredLanguage,
        isActive,
        accountStatus: isActive ? 'active' : 'suspended',
        approvalStatus: 'approved',
        profileCompleted: true,
        mustChangePassword: true,
        authCreated: true,
        fcmTokens: [],
        createdBy: req.user!.uid,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return res.status(201).json({
        success: true,
        data: { uid: authUser.uid, email },
      });
    } catch (error) {
      if (createdUid) {
        await auth.deleteUser(createdUid).catch(() => undefined);
      }
      next(error);
    }
  }
);

router.patch(
  '/employees/:documentId',
  requireAppCheck,
  requireAuth,
  requireRole(['admin']),
  accountMutationRateLimiter,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const documentRef = db.collection('users').doc(req.params.documentId);
      const snapshot = await documentRef.get();
      if (!snapshot.exists) {
        return res.status(404).json({ success: false, error: 'Employee was not found.' });
      }

      const existing = snapshot.data() || {};
      if (!employeeRoles.has(String(existing.role || ''))) {
        return res.status(400).json({ success: false, error: 'User is not an employee account.' });
      }

      const uid = String(existing.uid || snapshot.id);
      const authUser = await auth.getUser(uid).catch(() => null);
      if (!authUser) {
        return res.status(409).json({
          success: false,
          error: 'Employee has no linked authentication account. Recreate the account securely.',
        });
      }
      if (uid === req.user!.uid &&
          (req.body.isActive === false ||
           (req.body.role != null && String(req.body.role) !== 'admin'))) {
        return res.status(409).json({
          success: false,
          error: 'An administrator cannot deactivate or demote their own account.',
        });
      }

      const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
      const authUpdates: { displayName?: string; email?: string; disabled?: boolean } = {};

      if (req.body.name != null) {
        const name = String(req.body.name).trim();
        if (!name) return res.status(400).json({ success: false, error: 'Name is required.' });
        updates.name = name;
        authUpdates.displayName = name;
      }
      if (req.body.email != null) {
        const email = String(req.body.email).trim().toLowerCase();
        if (!email.includes('@')) {
          return res.status(400).json({ success: false, error: 'A valid email is required.' });
        }
        updates.email = email;
        authUpdates.email = email;
      }
      if (req.body.phoneNumber != null) updates.phoneNumber = String(req.body.phoneNumber).trim();
      if (req.body.preferredLanguage != null) {
        updates.preferredLanguage = String(req.body.preferredLanguage).trim();
      }
      if (req.body.role != null) {
        const role = String(req.body.role).trim();
        if (!employeeRoles.has(role)) {
          return res.status(400).json({ success: false, error: 'Invalid employee role.' });
        }
        updates.role = role;
      }
      if (req.body.isActive != null) {
        const isActive = req.body.isActive === true;
        updates.isActive = isActive;
        updates.accountStatus = isActive ? 'active' : 'suspended';
        authUpdates.disabled = !isActive;
      }

      await auth.updateUser(uid, authUpdates);
      if (snapshot.id === uid) {
        await documentRef.update(updates);
      } else {
        await db.runTransaction(async (transaction) => {
          transaction.set(db.collection('users').doc(uid), {
            ...existing,
            ...updates,
            uid,
          });
          transaction.delete(documentRef);
        });
      }

      return res.status(200).json({ success: true, data: { uid } });
    } catch (error) {
      next(error);
    }
  }
);

router.delete(
  '/employees/:documentId',
  requireAppCheck,
  requireAuth,
  requireRole(['admin']),
  accountMutationRateLimiter,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const documentRef = db.collection('users').doc(req.params.documentId);
      const snapshot = await documentRef.get();
      if (!snapshot.exists) {
        return res.status(404).json({ success: false, error: 'Employee was not found.' });
      }
      const existing = snapshot.data() || {};
      if (!employeeRoles.has(String(existing.role || ''))) {
        return res.status(400).json({ success: false, error: 'User is not an employee account.' });
      }
      const uid = String(existing.uid || snapshot.id);
      if (uid === req.user!.uid) {
        return res.status(409).json({
          success: false,
          error: 'Use the account-deletion flow to delete your own account.',
        });
      }
      if (await hasActiveBookings('assignedPilotId', uid) ||
          await hasActiveBookings('copilotId', uid)) {
        return res.status(409).json({
          success: false,
          error: 'Reassign or complete this employee’s active bookings before deletion.',
        });
      }

      const anonymizedId = `deleted-${crypto.createHash('sha256').update(uid).digest('hex').slice(0, 16)}`;
      await anonymizeMatchingDocuments('bookings', 'assignedPilotId', uid, {
        assignedPilotId: anonymizedId,
        assignedPilotName: 'Deleted pilot',
      });
      await anonymizeMatchingDocuments('bookings', 'copilotId', uid, {
        copilotId: anonymizedId,
        copilotName: 'Deleted pilot',
      });
      await deleteMatchingDocuments('notifications', 'recipientUid', uid);
      await storage.bucket().deleteFiles({ prefix: `users/${uid}/`, force: true });
      await documentRef.delete();
      if (snapshot.id !== uid) await db.collection('users').doc(uid).delete().catch(() => undefined);
      await auth.deleteUser(uid).catch((error: any) => {
        if (error?.code !== 'auth/user-not-found') throw error;
      });

      return res.status(200).json({ success: true });
    } catch (error) {
      next(error);
    }
  }
);

router.delete(
  '/me',
  requireAppCheck,
  requireAccountIdentity,
  accountMutationRateLimiter,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const uid = req.user!.uid;
      const activeBookingChecks = await Promise.all([
        hasActiveBookings('farmerUid', uid),
        hasActiveBookings('createdByRetailerId', uid),
        hasActiveBookings('assignedPilotId', uid),
        hasActiveBookings('copilotId', uid),
      ]);
      if (activeBookingChecks.some(Boolean)) {
        return res.status(409).json({
          success: false,
          error: 'Complete or cancel active bookings before deleting this account.',
        });
      }
      const anonymizedId = `deleted-${crypto
        .createHash('sha256')
        .update(uid)
        .digest('hex')
        .slice(0, 16)}`;

      await deleteMatchingDocuments('farms', 'farmerUid', uid);
      await deleteMatchingDocuments('notifications', 'recipientUid', uid);
      await anonymizeMatchingDocuments('activities', 'userId', uid, {
        userId: anonymizedId,
        userName: 'Deleted user',
      });
      await anonymizeMatchingDocuments('payments', 'userId', uid, {
        userId: anonymizedId,
      });
      await anonymizeMatchingDocuments('bookings', 'farmerUid', uid, {
        farmerUid: anonymizedId,
        farmerName: 'Deleted user',
        farmerPhone: null,
        preferredLanguage: null,
      });
      await anonymizeMatchingDocuments('bookings', 'createdByRetailerId', uid, {
        createdByRetailerId: anonymizedId,
        retailerName: 'Deleted retailer',
      });
      await anonymizeMatchingDocuments('bookings', 'assignedPilotId', uid, {
        assignedPilotId: anonymizedId,
        assignedPilotName: 'Deleted pilot',
      });
      await anonymizeMatchingDocuments('bookings', 'copilotId', uid, {
        copilotId: anonymizedId,
        copilotName: 'Deleted pilot',
      });

      await storage
        .bucket()
        .deleteFiles({ prefix: `users/${uid}/`, force: true });
      await db.collection('users').doc(uid).delete();
      await auth.deleteUser(uid);

      return res.status(200).json({ success: true });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
