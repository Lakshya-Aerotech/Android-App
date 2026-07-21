import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../booking/models/booking_model.dart';

final couponBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .where((booking) => booking.couponId != null)
        .toList();
  });
});

final userFutureProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final authRepo = ref.read(authRepositoryProvider);
  return authRepo.getUserData(uid);
});

class CouponHistoryScreen extends ConsumerWidget {
  const CouponHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(couponBookingsStreamProvider);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(context.tr('Coupon Usage History')),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('No coupon redemptions found'),
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _HistoryCard(booking: booking, dateFormat: dateFormat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${context.tr('Error loading history')}: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BookingModel booking;
  final DateFormat dateFormat;

  const _HistoryCard({required this.booking, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final discountLabel = booking.couponDiscountType == 'percentage'
        ? '${(booking.couponDiscountValue ?? 0.0).toStringAsFixed(0)}%'
        : 'Rs. ${(booking.couponDiscountValue ?? 0.0).toStringAsFixed(0)}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.couponCode ?? 'UNKNOWN',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '- Rs. ${(booking.discountAmount ?? 0.0).toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRow(context.tr('Booking ID'), booking.bookingId),
            _buildRow(context.tr('Farmer'), booking.farmerName ?? 'N/A'),
            _buildRetailerRow(context.tr('Retailer'), booking.createdByRetailerId),
            _buildRow(context.tr('Service Type'), booking.serviceType),
            _buildRow(context.tr('Discount Value'), discountLabel),
            _buildRow(context.tr('Date Applied'), dateFormat.format(booking.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerRow(String label, String? retailerId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: retailerId != null
                ? _RetailerNameText(retailerId: retailerId)
                : Text(
                    'Direct Booking',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RetailerNameText extends ConsumerWidget {
  final String retailerId;
  const _RetailerNameText({required this.retailerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userFutureProvider(retailerId));
    return userAsync.when(
      data: (user) => Text(
        user?.name ?? 'Unknown Retailer',
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey)),
      error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red)),
    );
  }
}
