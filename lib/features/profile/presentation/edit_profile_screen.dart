import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../auth/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _villageController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userModelProvider);
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _villageController = TextEditingController(text: user?.village);
    _districtController = TextEditingController(text: user?.district);
    _stateController = TextEditingController(text: user?.state);
    _selectedLanguage = user?.preferredLanguage == 'te' ? 'Telugu' : 'English';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onSave() async {
    await ref.read(authViewModelProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      village: _villageController.text.trim(),
      district: _districtController.text.trim(),
      stateName: _stateController.text.trim(),
      language: _selectedLanguage == 'English' ? 'en' : 'te',
    );
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final user = ref.watch(userModelProvider);
    final bool isFarmer = user?.role == UserRole.farmer;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomTextField(
              label: 'Full Name',
              hintText: 'Enter your name',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              hintText: 'Enter phone number',
              controller: _phoneController,
              enabled: true, 
            ),
            const SizedBox(height: 16),
            if (isFarmer) ...[
              CustomTextField(
                label: 'Village',
                hintText: 'Enter village',
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
            ] else ...[
              // For employees, show but don't edit these
              CustomTextField(
                label: 'Email',
                hintText: '',
                controller: TextEditingController(text: user?.email),
                enabled: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Role',
                hintText: '',
                controller: TextEditingController(text: user?.role.value.toUpperCase()),
                enabled: false,
              ),
              const SizedBox(height: 16),
            ],
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
                  items: ['English', 'Telugu'].map((String value) {
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
              text: 'Save Changes',
              isLoading: state.status == AuthStatus.loading,
              onPressed: _onSave,
            ),
          ],
        ),
      ),
    );
  }
}
