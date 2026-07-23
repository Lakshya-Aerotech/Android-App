import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/models/system_settings_model.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/wallet_transaction_model.dart';
import '../models/salary_payment_model.dart';

final pilotWalletTransactionsProvider = StreamProvider<List<WalletTransactionModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref.watch(adminRepositoryProvider).getWalletTransactionsStream(user.uid!);
});

final pilotSalaryPaymentsProvider = StreamProvider<List<SalaryPaymentModel>>((ref) {
  final user = ref.watch(userModelProvider);
  if (user == null || user.uid == null) return Stream.value([]);
  return ref.watch(adminRepositoryProvider).getSalaryPaymentsStream(user.uid!);
});

final currentSystemSettingsProvider = StreamProvider<SystemSettingsModel>((ref) {
  return ref.watch(adminRepositoryProvider).getSystemSettingsStream();
});
