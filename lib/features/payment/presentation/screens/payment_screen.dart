import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../booking/models/booking_model.dart';
import '../../providers/payment_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(paymentControllerProvider.notifier).reset());
  }

  void _onPayNow() async {
    final booking = widget.booking;
    final bookingId = booking.docId;
    final amount = booking.payableAmount ?? 0.0;

    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User or Booking details missing')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Payment amount must be greater than 0')),
      );
      return;
    }

    await ref.read(paymentControllerProvider.notifier).initiatePayment(
          bookingId: bookingId,
        );

    final paymentState = ref.read(paymentControllerProvider);
    if (paymentState.error != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Error'),
            content: Text(paymentState.error!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else if (paymentState.isSuccess &&
        paymentState.paymentUrl != null &&
        paymentState.merchantTransactionId != null) {
      if (mounted) {
        context.push('/payment-webview', extra: {
          'booking': booking,
          'paymentUrl': paymentState.paymentUrl,
          'merchantTransactionId': paymentState.merchantTransactionId,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final originalAmount = b.originalAmount ?? 0.0;
    final discount = b.discountAmount ?? 0.0;
    final payableAmount = b.payableAmount ?? 0.0;
    
    final paymentState = ref.watch(paymentControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Online Payment Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Booking Payment',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Review the summary below before proceeding to the secure PhonePe gateway.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Farmer Name', b.farmerName ?? 'N/A'),
                  _buildSummaryRow('Booking Code', b.bookingId),
                  _buildSummaryRow('Service Type', b.serviceType),
                  _buildSummaryRow('Estimated Area', '${b.estimatedArea} Acres'),
                  const Divider(height: 24),
                  _buildSummaryRow('Original Amount', '₹${originalAmount.toStringAsFixed(2)}'),
                  if (discount > 0)
                    _buildSummaryRow('Coupon Discount', '- ₹${discount.toStringAsFixed(2)}', valueColor: AppColors.success),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Final Amount', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '₹${payableAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (paymentState.isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Initiating payment gateway, please wait...'),
                  ],
                ),
              )
            else
              PrimaryButton(
                text: 'PAY NOW',
                onPressed: _onPayNow,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
