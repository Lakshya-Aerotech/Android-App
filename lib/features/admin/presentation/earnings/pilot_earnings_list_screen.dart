import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class PilotEarningsListScreen extends ConsumerWidget {
  const PilotEarningsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Pilot Earnings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: employeesAsync.when(
        data: (employees) {
          // Filter for roles that can earn incentives: Only Pilot and External Pilot
          final earningRoles = [UserRole.pilot, UserRole.externalPilot];
          final pilots = employees.where((e) => earningRoles.contains(e.role)).toList();

          if (pilots.isEmpty) {
            return const Center(child: Text('No pilots found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pilots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pilot = pilots[index];
              return _PilotEarningCard(pilot: pilot);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PilotEarningCard extends ConsumerWidget {
  final UserModel pilot;
  const _PilotEarningCard({required this.pilot});

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pilot.name ?? 'Unknown', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                  Text(pilot.role.value.toUpperCase(), style: AppTextStyles.bodySmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${pilot.walletBalance.toStringAsFixed(2)}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat('Jobs', '${pilot.completedJobs}'),
              _buildSmallStat('Acres', pilot.totalAcres.toStringAsFixed(1)),
              _buildSmallStat('Last Paid', pilot.lastSalaryPaidAt != null 
                  ? DateFormat('dd MMM').format(pilot.lastSalaryPaidAt!) 
                  : 'Never'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/admin/pilot-earning-details', extra: pilot),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: pilot.walletBalance > 0 
                      ? () => _showMarkPaidDialog(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark Paid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showMarkPaidDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController(text: pilot.walletBalance.toStringAsFixed(2));
    final periodController = TextEditingController(text: DateFormat('MMMM yyyy').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Salary Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark ₹${pilot.walletBalance.toStringAsFixed(2)} as paid for ${pilot.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: periodController,
              decoration: const InputDecoration(labelText: 'Period'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(adminViewModelProvider.notifier).markSalaryAsPaid(
                pilotId: pilot.uid!,
                amount: double.tryParse(amountController.text) ?? pilot.walletBalance,
                period: periodController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
