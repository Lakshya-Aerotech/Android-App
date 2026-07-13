import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.pilot;
  String _selectedLanguage = 'English';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = ref.read(userModelProvider);
    
    final error = await ref.read(adminViewModelProvider.notifier).createEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      language: _selectedLanguage == 'English' ? 'en' : 'te',
      isActive: _isActive,
      createdBy: admin?.name ?? 'Admin',
    );

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee created successfully'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(adminViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Details',
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Full Name',
                hintText: 'John Doe',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email Address',
                hintText: 'john@lakshya.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                hintText: '9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length >= 10 ? null : 'Invalid phone number',
              ),
              const SizedBox(height: 16),
              
              Text('Assign Role', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              _buildDropdown<UserRole>(
                value: _selectedRole,
                items: const [UserRole.pilot, UserRole.operations, UserRole.admin],
                onChanged: (v) => setState(() => _selectedRole = v!),
                labelBuilder: (role) => role.name.toUpperCase(),
              ),
              const SizedBox(height: 16),
              
              Text('Preferred Language', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _selectedLanguage,
                items: const ['English', 'Telugu'],
                onChanged: (v) => setState(() => _selectedLanguage = v!),
                labelBuilder: (lang) => lang,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Account', style: AppTextStyles.bodyLarge),
                      Text('Enable immediate login access', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Create Employee',
                onPressed: _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item), style: AppTextStyles.bodyLarge),
            );
          }).toList(),
        ),
      ),
    );
  }
}
