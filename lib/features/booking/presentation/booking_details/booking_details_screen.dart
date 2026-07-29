import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/confirmation_dialog.dart' as widgets;
import '../../../../shared/enums/booking_status.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/booking_timeline.dart';
import '../../widgets/mission_summary_card.dart';
import '../../widgets/rating_card.dart';
import '../../widgets/issue_report_dialog.dart';
import '../../../../shared/widgets/live_tracking_map.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/viewmodel/auth_viewmodel.dart';
import '../../../payment/data/services/payment_api.dart';
import '../../../payment/presentation/screens/payment_webview_screen.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use docId to listen for real-time updates
    final bookingAsync = ref.watch(singleBookingStreamProvider(booking.docId!));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: bookingAsync.when(
        data: (liveBooking) {
          if (liveBooking == null) {
            return const Center(child: Text('Booking not found.'));
          }
          return _buildContent(context, ref, liveBooking);
        },
        loading: () => _buildContent(context, ref, booking), // Show initial data while loading
        error: (e, _) => Center(child: Text('Error loading booking: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, BookingModel b) {
    final user = ref.watch(userModelProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(b),
          const SizedBox(height: 24),
          
          if (b.status == BookingStatus.completed) ...[
             _buildPostServiceActions(context, ref, b),
             const SizedBox(height: 24),
          ],

          if ([BookingStatus.enRoute, BookingStatus.arrived, BookingStatus.inProgress].contains(b.status)) ...[
            Text('Live Tracking', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LiveTrackingMap(booking: b),
            const SizedBox(height: 24),
          ],

          if (b.status == BookingStatus.farmerConfirmed || b.status == BookingStatus.closed) ...[
            RatingCard(booking: b),
            const SizedBox(height: 24),
          ],

          if (b.actualAreaCovered != null) ...[
            MissionSummaryCard(booking: b),
            const SizedBox(height: 24),
          ],

          if (b.paymentMethod != null || (b.payableAmount ?? 0) > 0) ...[
            Text('Payment Details', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentSummaryCard(context, ref, b, user),
            const SizedBox(height: 24),
          ],

          if (b.hasCoupon) ...[
            Text('Coupon & Verification', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCouponVerificationCard(b),
            const SizedBox(height: 24),
          ],

          Text('Farm & Service', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          BookingSummaryCard(
            label: 'Farm Name',
            value: b.farmName,
            icon: Icons.landscape_outlined,
          ),
          BookingSummaryCard(
            label: 'Service Type',
            value: b.serviceType,
            icon: Icons.settings_suggest_outlined,
          ),
          BookingSummaryCard(
            label: 'Estimated Area',
            value: '${b.estimatedArea} Acres',
            icon: Icons.crop_free,
          ),

          if (b.assignedPilotId != null) ...[
            const SizedBox(height: 24),
            Text('Assigned Resources', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            BookingSummaryCard(
              label: 'Pilot Name',
              value: b.assignedPilotName ?? 'N/A',
              icon: Icons.person_add_alt_1_outlined,
            ),
            if (b.status != BookingStatus.pending && b.status != BookingStatus.cancelled) ...[
              const SizedBox(height: 12),
              ref.watch(userDetailsProvider(b.assignedPilotId!)).when(
                data: (pilot) => BookingSummaryCard(
                  label: 'Pilot Contact',
                  value: pilot?.phoneNumber ?? 'N/A',
                  icon: Icons.phone_outlined,
                ),
                loading: () => const BookingSummaryCard(
                  label: 'Pilot Contact',
                  value: 'Loading...',
                  icon: Icons.phone_outlined,
                ),
                error: (_, __) => const BookingSummaryCard(
                  label: 'Pilot Contact',
                  value: 'Error loading contact',
                  icon: Icons.phone_outlined,
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),
          Text('Service Progress', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: BookingTimeline(booking: b),
          ),

          if (b.remarks != null || b.operationsRemarks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Notes', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (b.remarks != null)
              _buildNoteCard('Your Note', b.remarks!),
            ...b.operationsRemarks.map((r) => _buildNoteCard('Ops: ${r.createdBy}', r.message)),
          ],

          const SizedBox(height: 40),
          
          if (b.status == BookingStatus.pending && !(b.paymentStatus?.toUpperCase() == 'SUCCESS' || b.paymentStatus?.toUpperCase() == 'PAID')) ...[
            PrimaryButton(
              text: 'Cancel Booking',
              onPressed: () => _showCancelConfirmation(context, ref, b.docId!),
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking ID', style: AppTextStyles.bodySmall),
                    Text(
                      b.bookingId,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: StatusChip.fromStatus(b.status)),
            ],
          ),
          const Divider(height: 32),
          _buildQuickInfo(b),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(BookingModel b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildInfoColumn(
            Icons.calendar_today_outlined,
            'Date',
            DateFormat('dd MMM').format(b.bookingDate),
          ),
        ),
        Expanded(
          child: _buildInfoColumn(
            Icons.access_time_outlined,
            'Time',
            b.preferredTime,
          ),
        ),
        Expanded(
          child: _buildInfoColumn(
            Icons.grass_outlined,
            'Crop',
            b.cropType,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        Text(
          value, 
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(BuildContext context, WidgetRef ref, BookingModel b, UserModel? user) {
    final bool isPaid = b.paymentStatus?.toUpperCase() == 'SUCCESS' || b.paymentStatus?.toUpperCase() == 'PAID';
    final bool isUpi = (b.paymentMethod ?? 'UPI').toUpperCase() == 'UPI';
    final bool isCash = (b.paymentMethod ?? '').toUpperCase() == 'CASH';
    final bool isStaffOrAdmin = user?.role == UserRole.admin || user?.role == UserRole.operations;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Original Amount', '₹${b.originalAmount?.toStringAsFixed(2) ?? '0.00'}'),
          if ((b.discountAmount ?? 0) > 0)
            _buildPaymentRow(
              'Coupon Discount', 
              '- ₹${b.discountAmount?.toStringAsFixed(2) ?? '0.00'}', 
              valueColor: AppColors.success,
            ),
          _buildPaymentRow(
            'Final Amount', 
            '₹${b.payableAmount?.toStringAsFixed(2) ?? '0.00'}',
            isBold: true,
            valueColor: AppColors.primary,
          ),
          const Divider(height: 24),
          _buildPaymentRow('Payment Timing', b.paymentTiming == 'PAY_AFTER_SERVICE' ? 'Pay After Service' : 'Pay Now'),
          _buildPaymentRow('Payment Method', isCash ? 'Cash' : 'UPI (Cashfree)'),
          _buildPaymentRow(
            'Payment Status', 
            b.paymentStatus ?? 'PAYMENT_PENDING',
            valueColor: isPaid ? AppColors.success : AppColors.warning,
            isBold: true,
          ),
          if (isPaid) ...[
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PAYMENT COMPLETED',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ] else if (isUpi) ...[
            const Divider(height: 24),
            PrimaryButton(
              text: 'COMPLETE PAYMENT (CASHFREE UPI)',
              onPressed: () => _handlePayNow(context, ref, b),
            ),
          ] else if (isCash) ...[
            const Divider(height: 24),
            if (isStaffOrAdmin) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.payments, color: Colors.white),
                label: const Text('CONFIRM CASH COLLECTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleConfirmCash(context, ref, b),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Waiting for Cash Collection by Pilot / Operations Staff.',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _handlePayNow(BuildContext context, WidgetRef ref, BookingModel b) async {
    try {
      final paymentApi = ref.read(paymentApiServiceProvider);
      final response = await paymentApi.createPayment(
        bookingId: b.bookingId,
        userId: b.farmerUid,
        amount: b.payableAmount ?? 0.0,
        mobileNumber: b.farmerPhone ?? '9999999999',
      );

      if (context.mounted && response.paymentUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              booking: b,
              paymentUrl: response.paymentUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating Cashfree payment: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleConfirmCash(BuildContext context, WidgetRef ref, BookingModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cash Payment'),
        content: Text('Confirm that cash payment of Rs. ${(b.payableAmount ?? 0).toStringAsFixed(2)} has been collected for booking ${b.bookingId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cash Received'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = ref.read(dioProvider);
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken();

        final response = await dio.post(
          'http://192.168.0.232:3000/api/payment/confirm-cash',
          data: {
            'bookingId': b.docId ?? b.bookingId,
            'remarks': 'Cash collected by staff',
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (context.mounted) {
          if (response.data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cash payment confirmed successfully!'), backgroundColor: AppColors.success),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['message'] ?? 'Failed to confirm cash.'), backgroundColor: AppColors.error),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error confirming cash payment: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildPaymentRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponVerificationCard(BookingModel b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Coupon Code', b.couponCode!),
          _buildPaymentRow('Retailer', b.retailerName ?? 'N/A'),
          _buildPaymentRow(
            'Verification Status', 
            b.couponVerificationStatus ?? 'Pending Verification',
            valueColor: b.couponVerified ? AppColors.success : Colors.orange,
          ),
          if (b.couponVerified) ...[
            _buildPaymentRow(
              'Verified At', 
              b.couponVerifiedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(b.couponVerifiedAt!) : 'N/A',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPostServiceActions(BuildContext context, WidgetRef ref, BookingModel b) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () => _showIssueReportDialog(context, b.docId!),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Report an Issue'),
        ),
      ],
    );
  }

  void _showIssueReportDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => IssueReportDialog(bookingDocId: docId),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref, String docId) {
    showDialog(
      context: context,
      builder: (context) => widgets.ConfirmationDialog(
        title: 'Cancel Booking',
        content: 'Are you sure you want to cancel this booking? This action cannot be undone.',
        confirmLabel: 'Yes, Cancel',
        onConfirm: () {
          ref.read(bookingViewModelProvider.notifier).cancelBooking(docId);
        },
      ),
    );
  }
}
