import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class RetailerStatusScreen extends ConsumerWidget {
  const RetailerStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    final status = user?.approvalStatus ?? ApprovalStatus.pending;
    final content = switch (status) {
      ApprovalStatus.pending => (
        Icons.hourglass_top,
        'Registration Pending',
        'Your retailer account is waiting for admin approval.',
      ),
      ApprovalStatus.rejected => (
        Icons.cancel_outlined,
        'Registration Rejected',
        'Your retailer registration was rejected. Please contact support.',
      ),
      ApprovalStatus.suspended => (
        Icons.block,
        'Account Suspended',
        'Your retailer account is suspended. Please contact the administrator.',
      ),
      ApprovalStatus.approved => (
        Icons.check_circle_outline,
        'Account Approved',
        'Your account is approved.',
      ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(content.$1, size: 84, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                content.$2,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content.$3,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              if (status == ApprovalStatus.approved)
                PrimaryButton(
                  text: 'Go to Dashboard',
                  onPressed: () => context.go('/retailer'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref.read(authViewModelProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
