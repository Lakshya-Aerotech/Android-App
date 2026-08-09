import crypto from 'crypto';
import { NextFunction, Response, Router } from 'express';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { config } from '../config';
import { db } from '../firebase';
import { AuthenticatedRequest, requireAuth, requireRole } from '../middleware/auth.middleware';
import { requireAppCheck } from '../middleware/app-check.middleware';
import { bookingCreationRateLimiter } from '../middleware/rate-limit.middleware';

const router = Router();

function roundedCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

router.post(
  '/',
  requireAppCheck,
  requireAuth,
  requireRole(['farmer', 'retailer']),
  bookingCreationRateLimiter,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const farmId = String(req.body.farmId || '').trim();
      const serviceType = String(req.body.serviceType || '').trim();
      const preferredTime = String(req.body.preferredTime || '').trim();
      const remarks = req.body.remarks == null ? null : String(req.body.remarks).trim();
      const estimatedArea = Number(req.body.estimatedArea);
      const bookingDateInput = String(req.body.bookingDate || '');
      const bookingDate = /^\d{4}-\d{2}-\d{2}$/.test(bookingDateInput)
        ? new Date(`${bookingDateInput}T00:00:00.000Z`)
        : new Date(Number.NaN);
      const couponId = req.body.couponId == null ? null : String(req.body.couponId).trim();

      if (!farmId || !serviceType || !/^([01]\d|2[0-3]):[0-5]\d$/.test(preferredTime) ||
          !Number.isFinite(estimatedArea) || estimatedArea <= 0 ||
          Number.isNaN(bookingDate.getTime())) {
        return res.status(400).json({ success: false, error: 'Invalid booking details.' });
      }
      if (remarks && remarks.length > 1000) {
        return res.status(400).json({ success: false, error: 'Remarks cannot exceed 1000 characters.' });
      }
      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);
      if (bookingDate < today) {
        return res.status(400).json({ success: false, error: 'Booking date cannot be in the past.' });
      }

      const actorUid = req.user!.uid;
      const isRetailer = req.user!.role === 'retailer';
      const farmerUid = isRetailer ? String(req.body.farmerUid || '').trim() : actorUid;
      if (!farmerUid) {
        return res.status(400).json({ success: false, error: 'A farmer is required.' });
      }

      const farmerSnapshot = await db.collection('users').doc(farmerUid).get();
      const farmSnapshot = await db.collection('farms').doc(farmId).get();
      if (!farmerSnapshot.exists || !farmSnapshot.exists) {
        return res.status(404).json({ success: false, error: 'Farmer or farm was not found.' });
      }
      const farmer = farmerSnapshot.data() || {};
      const farm = farmSnapshot.data() || {};
      if (farmer.role !== 'farmer' || farm.farmerUid !== farmerUid || farm.isActive === false) {
        return res.status(403).json({ success: false, error: 'The selected farm is not available to this account.' });
      }
      if (isRetailer && farmer.createdByRetailerId !== actorUid && farmer.createdBy !== actorUid) {
        return res.status(403).json({ success: false, error: 'The farmer is not managed by this retailer.' });
      }
      const farmArea = Number(farm.area);
      if (Number.isFinite(farmArea) && estimatedArea > farmArea) {
        return res.status(400).json({ success: false, error: 'Estimated area exceeds the farm area.' });
      }

      const originalAmount = roundedCurrency(estimatedArea * config.bookingRatePerAcre);
      const documentRef = db.collection('bookings').doc();
      const publicBookingId = `LA-${Date.now()}-${crypto.randomBytes(2).toString('hex').toUpperCase()}`;

      const result = await db.runTransaction(async (transaction) => {
        let couponData: Record<string, any> | null = null;
        let couponRef: FirebaseFirestore.DocumentReference | null = null;
        let discountAmount = 0;

        if (couponId) {
          couponRef = db.collection('coupons').doc(couponId);
          const couponSnapshot = await transaction.get(couponRef);
          if (!couponSnapshot.exists) throw Object.assign(new Error('Coupon was not found.'), { statusCode: 404 });
          couponData = couponSnapshot.data() || {};
          const now = new Date();
          const validFrom = couponData.validFrom?.toDate?.();
          const validUntil = couponData.validUntil?.toDate?.();
          if (validFrom) validFrom.setHours(0, 0, 0, 0);
          if (validUntil) validUntil.setHours(23, 59, 59, 999);
          const region = String(couponData.applicableRegion || '').trim().toLowerCase();
          const assignedRetailers = Array.isArray(couponData.assignedRetailerIds)
            ? couponData.assignedRetailerIds.map(String)
            : [];

          if (couponData.isActive !== true || Number(couponData.remainingUsage) <= 0 ||
              !validFrom || !validUntil || now < validFrom || now > validUntil ||
              String(couponData.eligibleService || '').trim().toLowerCase() !== serviceType.toLowerCase() ||
              !['', 'all', 'global', 'any', String(farm.state || '').trim().toLowerCase()].includes(region) ||
              (isRetailer ? (assignedRetailers.length > 0 && !assignedRetailers.includes(actorUid))
                : assignedRetailers.length > 0)) {
            throw Object.assign(new Error('Coupon is not eligible for this booking.'), { statusCode: 409 });
          }

          const discountValue = Number(couponData.discountValue);
          if (!Number.isFinite(discountValue) || discountValue < 0) {
            throw Object.assign(new Error('Coupon has an invalid discount.'), { statusCode: 409 });
          }
          discountAmount = couponData.discountType === 'percentage'
            ? originalAmount * Math.min(discountValue, 100) / 100
            : discountValue;
          discountAmount = roundedCurrency(Math.min(discountAmount, originalAmount));
          transaction.update(couponRef, {
            remainingUsage: Number(couponData.remainingUsage) - 1,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        const payableAmount = roundedCurrency(originalAmount - discountAmount);
        const now = Timestamp.now();
        transaction.create(documentRef, {
          bookingId: publicBookingId,
          farmerUid,
          farmerName: farmer.name || null,
          farmerPhone: farmer.phoneNumber || null,
          preferredLanguage: farmer.preferredLanguage || null,
          farmerId: farmerUid,
          createdByRole: isRetailer ? 'retailer' : 'farmer',
          createdByRetailerId: isRetailer ? actorUid : null,
          retailerName: isRetailer ? req.user!.name || null : null,
          farmId,
          farmName: farm.farmName || null,
          village: farm.village || null,
          district: farm.district || null,
          state: farm.state || null,
          cropType: farm.cropType || null,
          farmArea: Number.isFinite(farmArea) ? farmArea : null,
          latitude: Number(farm.latitude) || null,
          longitude: Number(farm.longitude) || null,
          serviceType,
          bookingDate: Timestamp.fromDate(bookingDate),
          preferredTime,
          estimatedArea,
          remarks,
          status: 'pending',
          statusHistory: [{
            status: 'pending',
            updatedBy: isRetailer ? req.user!.name || 'Retailer' : farmer.name || 'Farmer',
            updatedByRole: isRetailer ? 'retailer' : 'farmer',
            timestamp: now,
            remarks: 'Booking submitted successfully.',
          }],
          couponId,
          couponCode: couponData?.couponCode || null,
          couponDiscountType: couponData?.discountType || null,
          couponDiscountValue: couponData?.discountValue || null,
          originalAmount,
          discountAmount,
          payableAmount,
          paymentStatus: payableAmount === 0 ? 'WAIVED' : 'PENDING',
          cashCollected: false,
          cashDeposited: false,
          paymentVerifiedByAdmin: payableAmount === 0,
          couponVerified: couponId != null,
          couponVerificationStatus: couponId ? 'verified' : null,
          operationsRemarks: [],
          missionPhotos: [],
          createdAt: now,
          updatedAt: now,
        });

        return { payableAmount };
      });

      return res.status(201).json({
        success: true,
        data: { documentId: documentRef.id, bookingId: publicBookingId, ...result },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
