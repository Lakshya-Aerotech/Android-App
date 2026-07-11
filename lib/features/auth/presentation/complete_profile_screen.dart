import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_nameController.text.isEmpty ||
        _villageController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _stateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    ref.read(authViewModelProvider.notifier).completeProfile(
          name: _nameController.text.trim(),
          village: _villageController.text.trim(),
          district: _districtController.text.trim(),
          stateName: _stateController.text.trim(),
          language: _selectedLanguage == 'English' ? 'en' : 'te',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final user = ref.watch(userModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/farmer');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Complete Profile',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Final Step!',
              style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
            ),
            AppSpacing.verticalXs,
            Text(
              'Tell us a bit more about yourself',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Mobile Number',
              hintText: '',
              controller: TextEditingController(text: user?.phoneNumber ?? ''),
              enabled: false,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Full Name',
              hintText: 'Enter your name',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Village',
              hintText: 'Enter village name',
              controller: _villageController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'District',
              hintText: 'Enter district',
              controller: _districtController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'State',
              hintText: 'Enter state',
              controller: _stateController,
            ),
            const SizedBox(height: 16),
            Text(
              'Preferred Language',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: ['English', 'Telugu']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedLanguage = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Save & Continue',
              isLoading: state.status == AuthStatus.loading,
              onPressed: _onSave,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
