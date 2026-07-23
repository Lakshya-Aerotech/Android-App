import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../models/system_settings_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  final _pilotRateController = TextEditingController();
  final _copilotRateController = TextEditingController();

  @override
  void dispose() {
    _pilotRateController.dispose();
    _copilotRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(systemSettingsStreamProvider);

    ref.listen(systemSettingsStreamProvider, (previous, next) {
      if (next is AsyncData<SystemSettingsModel>) {
        _pilotRateController.text = next.value.pilotRatePerAcre.toString();
        _copilotRateController.text = next.value.copilotRatePerAcre.toString();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incentive Rates', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Set the standard incentive rates per acre for pilots and copilots.', style: AppTextStyles.bodySmall),
                const SizedBox(height: 24),
                _buildRateField('Pilot Rate (₹ / Acre)', _pilotRateController),
                const SizedBox(height: 16),
                _buildRateField('Copilot Rate (₹ / Acre)', _copilotRateController),
                const Spacer(),
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: () async {
                    final newSettings = SystemSettingsModel(
                      pilotRatePerAcre: double.tryParse(_pilotRateController.text) ?? settings.pilotRatePerAcre,
                      copilotRatePerAcre: double.tryParse(_copilotRateController.text) ?? settings.copilotRatePerAcre,
                    );
                    await ref.read(adminViewModelProvider.notifier).updateSystemSettings(newSettings);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings updated successfully')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildRateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
