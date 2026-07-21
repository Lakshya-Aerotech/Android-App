import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../models/booking_model.dart';
import '../../viewmodels/booking_viewmodel.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedMethod;
  final double _pricePerAcre = 500.0; // Placeholder price

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final originalAmount = b.originalAmount ?? (b.actualAreaCovered ?? b.estimatedArea) * _pricePerAcre;
    
    double discount = 0;
    if (b.couponCode != null) {
      if (b.couponDiscountType == 'Percentage') {
        discount = originalAmount * (b.couponDiscountAmount ?? 0) / 100;
      } else {
        discount = b.couponDiscountAmount ?? 0;
      }
    }
    
    final finalAmount = originalAmount - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Summary', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryCard(originalAmount, discount, finalAmount),
            const SizedBox(height: 32),
            Text('Select Payment Method', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentOption(
              title: 'UPI',
              subtitle: 'Pay using any UPI app',
              icon: Icons.account_balance_wallet_outlined,
              value: 'UPI',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              title: 'Cash',
              subtitle: 'Pay cash to the pilot',
              icon: Icons.money_outlined,
              value: 'Cash',
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Continue',
              onPressed: _selectedMethod == null ? null : () => _handlePayment(originalAmount, finalAmount, discount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double original, double discount, double finalAmt) {
    final b = widget.booking;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildRow('Farmer Name', b.farmerName ?? 'N/A'),
          _buildRow('Booking ID', b.bookingId),
          _buildRow('Service Type', b.serviceType),
          const Divider(height: 24),
          _buildRow('Original Amount', '₹${original.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildRow('Coupon Discount', '- ₹${discount.toStringAsFixed(2)}', valueColor: AppColors.success),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Final Amount', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '₹${finalAmt.toStringAsFixed(2)}',
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayment(double original, double finalAmt, double discount) async {
    if (_selectedMethod == 'UPI') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI payment integration will be available in a future update.')),
      );
    }

    await ref.read(bookingViewModelProvider.notifier).requestPayment(
      docId: widget.booking.docId!,
      method: _selectedMethod!,
      originalAmount: original,
      finalAmount: finalAmt,
      discountAmount: discount > 0 ? discount : null,
    );

    if (mounted) {
      context.pop();
    }
  }
}
