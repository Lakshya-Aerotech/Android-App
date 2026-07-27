import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../wallet/models/wallet_transaction_model.dart';
import '../../../wallet/models/salary_payment_model.dart';

class PilotEarningDetailsScreen extends ConsumerStatefulWidget {
  final UserModel pilot;
  const PilotEarningDetailsScreen({super.key, required this.pilot});

  @override
  ConsumerState<PilotEarningDetailsScreen> createState() => _PilotEarningDetailsScreenState();
}

class _PilotEarningDetailsScreenState extends ConsumerState<PilotEarningDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(walletTransactionsStreamProvider(widget.pilot.uid ?? ''));
    final paymentsAsync = ref.watch(salaryPaymentsStreamProvider(widget.pilot.uid ?? ''));
    final settingsAsync = ref.watch(systemSettingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.pilot.name ?? 'Pilot Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(widget.pilot, settingsAsync),
            const SizedBox(height: 32),
            _buildActionSection(context),
            const SizedBox(height: 32),
            Text('Transaction History', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTransactionsList(transactionsAsync),
            const SizedBox(height: 32),
            Text('Incentive History', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentsList(paymentsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(UserModel pilot, AsyncValue settingsAsync) {
    final rate = settingsAsync.maybeWhen(
      data: (s) => pilot.role == UserRole.pilot ? s.pilotRatePerAcre : s.copilotRatePerAcre,
      orElse: () => 0.0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Current Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '₹${pilot.walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Jobs', '${pilot.completedJobs}'),
              _buildStat('Total Acres', pilot.totalAcres.toStringAsFixed(1)),
              _buildStat('Rate', '₹$rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Administrative Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Mark Incentive as Paid',
            onPressed: widget.pilot.walletBalance > 0 ? () => _showMarkPaidDialog(context) : null,
            backgroundColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context) {
    final amountController = TextEditingController(text: widget.pilot.walletBalance.toStringAsFixed(2));
    final periodController = TextEditingController(text: DateFormat('MMMM yyyy').format(DateTime.now()));
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Incentive Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Confirm that the incentive has been paid to this employee outside the application.'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '₹'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Incentive Period'),
              ),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? widget.pilot.walletBalance;
              await ref.read(adminViewModelProvider.notifier).markSalaryAsPaid(
                pilotId: widget.pilot.uid!,
                amount: amount,
                period: periodController.text,
                remarks: remarksController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AsyncValue<List<WalletTransactionModel>> transactionsAsync) {
    return transactionsAsync.when(
      data: (txs) {
        if (txs.isEmpty) return const Center(child: Text('No transactions.'));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = txs[index];
            final isEarning = tx.type == TransactionType.earning;
            return ListTile(
              leading: Icon(isEarning ? Icons.add_circle : Icons.remove_circle, color: isEarning ? Colors.green : Colors.red),
              title: Text(tx.description),
              subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt)),
              trailing: Text(
                '${isEarning ? "+" : ""} ₹${tx.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(color: isEarning ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildPaymentsList(AsyncValue<List<SalaryPaymentModel>> paymentsAsync) {
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) return const Center(child: Text('No incentive records.'));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = payments[index];
            return ListTile(
              leading: const Icon(Icons.payment, color: AppColors.primary),
              title: Text('₹${p.amountPaid.toStringAsFixed(2)} Paid'),
              subtitle: Text('Period: ${p.salaryPeriod}\nOn ${DateFormat('dd MMM yyyy').format(p.paidAt)}'),
              isThreeLine: true,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
