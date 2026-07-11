import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PilotDashboard extends ConsumerWidget {
  const PilotDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Pilot Dashboard',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'This module is under development.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildInfoRow('Name', user?.name ?? 'N/A'),
              _buildInfoRow('Email', user?.email ?? 'N/A'),
              _buildInfoRow('Role', user?.role.name.toUpperCase() ?? 'PILOT'),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
