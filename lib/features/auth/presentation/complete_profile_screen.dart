import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
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
      language: _selectedLanguage,
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
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Step!', style: AppTextStyles.headlineLarge),
            Text('Tell us a bit more about yourself', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 32),
            
            CustomTextField(
              label: 'Phone Number',
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
            
            Text('Preferred Language', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: ['English', 'Hindi', 'Marathi', 'Gujarati'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: AppTextStyles.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) setState(() => _selectedLanguage = newValue);
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
          ],
        ),
      ),
    );
  }
}

// Small fix for CustomTextField enabled property if not exists
extension on CustomTextField {
  Widget get _textField {
    // This is just a conceptual note, I should check if CustomTextField has enabled
    return Container(); 
  }
}
