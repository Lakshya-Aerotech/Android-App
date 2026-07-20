import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../farm/presentation/map_picker/map_picker_screen.dart';

class RetailerRegistrationScreen extends ConsumerStatefulWidget {
  const RetailerRegistrationScreen({super.key});

  @override
  ConsumerState<RetailerRegistrationScreen> createState() =>
      _RetailerRegistrationScreenState();
}

class _RetailerRegistrationScreenState
    extends ConsumerState<RetailerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gstController = TextEditingController();
  final _idController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _mandalController = TextEditingController();
  final _villageController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gstController.dispose();
    _idController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _mandalController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) setState(() => _selectedLocation = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select GPS location')),
      );
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    await ref
        .read(authViewModelProvider.notifier)
        .registerRetailer(
          shopName: _shopNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          gstNumber: _gstController.text.trim(),
          aadhaarPan: _idController.text.trim(),
          shopAddress: _addressController.text.trim(),
          stateName: _stateController.text.trim(),
          district: _districtController.text.trim(),
          mandal: _mandalController.text.trim(),
          village: _villageController.text.trim(),
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.unauthenticated &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retailer registration submitted successfully.'),
          ),
        );
        context.go('/login');
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
        title: const Text('Retailer Registration'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _requiredField('Shop Name *', _shopNameController),
              AppSpacing.verticalMd,
              _requiredField('Owner Name *', _ownerNameController),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Email *',
                hintText: 'retailer@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Password *',
                hintText: 'Enter password',
                controller: _passwordController,
                obscureText: true,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Confirm Password *',
                hintText: 'Re-enter password',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'GST Number (Optional)',
                hintText: 'Enter GST number',
                controller: _gstController,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Aadhaar/PAN (Optional)',
                hintText: 'Enter Aadhaar or PAN',
                controller: _idController,
              ),
              AppSpacing.verticalMd,
              _requiredField('Shop Address *', _addressController, maxLines: 3),
              AppSpacing.verticalMd,
              _requiredField('State *', _stateController),
              AppSpacing.verticalMd,
              _requiredField('District *', _districtController),
              AppSpacing.verticalMd,
              _requiredField('Mandal *', _mandalController),
              AppSpacing.verticalMd,
              _requiredField('Village *', _villageController),
              AppSpacing.verticalLg,
              InkWell(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLocation == null
                          ? AppColors.border
                          : AppColors.success,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedLocation == null
                              ? 'Select GPS Location *'
                              : 'GPS Selected (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                text: 'Submit Registration',
                onPressed: _submit,
                isLoading: authState.status == AuthStatus.loading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requiredField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return CustomTextField(
      label: label,
      hintText: label.replaceAll(' *', ''),
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }
}
