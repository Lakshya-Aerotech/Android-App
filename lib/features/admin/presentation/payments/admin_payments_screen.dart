import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../booking/models/booking_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allPaymentsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payments Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: paymentsAsync.when(
              data: (bookings) {
                final filtered = _applyFilter(bookings);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No payments found matching filter.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _PaymentCard(booking: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      'All',
      'Pending Cash Collection',
      'Cash Collected',
      'Awaiting Admin Confirmation',
      'Paid',
      'Rejected',
    ];

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  List<BookingModel> _applyFilter(List<BookingModel> bookings) {
    if (_selectedFilter == 'All') return bookings;
    if (_selectedFilter == 'Cash Collected') {
      return bookings.where((b) => b.paymentStatus == 'Cash Collected by Pilot').toList();
    }
    if (_selectedFilter == 'Rejected') {
      return bookings.where((b) => b.paymentStatus == 'Deposit Rejected').toList();
    }
    return bookings.where((b) => b.paymentStatus == _selectedFilter).toList();
  }
}

class _PaymentCard extends ConsumerWidget {
  final BookingModel booking;
  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(booking.bookingId, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Farmer', booking.farmerName ?? 'N/A'),
          _detailRow('Pilot', booking.assignedPilotName ?? 'N/A'),
          _detailRow('Amount', '₹${booking.payableAmount?.toStringAsFixed(2) ?? '0.00'}'),
          _detailRow('Method', booking.paymentMethod ?? 'N/A'),
          if (booking.cashCollectedAt != null)
            _detailRow('Collected', DateFormat('dd MMM, hh:mm a').format(booking.cashCollectedAt!)),
          if (booking.cashDepositedAt != null)
            _detailRow('Deposited', DateFormat('dd MMM, hh:mm a').format(booking.cashDepositedAt!)),
          
          if (booking.paymentStatus == 'Awaiting Admin Confirmation') ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context, ref),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmPayment(context, ref),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: const Text('Confirm Deposit'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = Colors.grey;
    String label = booking.paymentStatus ?? 'Unknown';

    if (booking.paymentVerifiedByAdmin) {
      color = AppColors.success;
      label = 'Paid';
    } else if (booking.paymentStatus == 'Deposit Rejected') {
      color = Colors.red;
      label = 'Rejected';
    } else if (booking.paymentStatus == 'Awaiting Admin Confirmation') {
      color = Colors.orange;
      label = 'Awaiting Confirmation';
    } else if (booking.paymentStatus == 'Cash Collected by Pilot') {
      color = Colors.blue;
      label = 'Cash Collected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deposit'),
        content: const Text('Are you sure you want to confirm this cash deposit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminViewModelProvider.notifier).confirmPayment(booking.docId!);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Deposit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(adminViewModelProvider.notifier).rejectPayment(booking.docId!, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

