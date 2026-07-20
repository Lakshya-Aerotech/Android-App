import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/user_model.dart';
import '../viewmodels/retailer_viewmodel.dart';

class RetailerFarmerFormScreen extends ConsumerStatefulWidget {
  final UserModel? farmer;

  const RetailerFarmerFormScreen({super.key, this.farmer});

  @override
  ConsumerState<RetailerFarmerFormScreen> createState() =>
      _RetailerFarmerFormScreenState();
}

class _RetailerFarmerFormScreenState
    extends ConsumerState<RetailerFarmerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _villageController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;

  bool get _isEditing => widget.farmer != null;

  @override
  void initState() {
    super.initState();
    final farmer = widget.farmer;
    _nameController = TextEditingController(text: farmer?.name);
    _mobileController = TextEditingController(text: farmer?.phoneNumber);
    _emailController = TextEditingController(text: farmer?.email);
    _villageController = TextEditingController(text: farmer?.village);
    _districtController = TextEditingController(text: farmer?.district);
    _stateController = TextEditingController(text: farmer?.state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      await ref
          .read(retailerViewModelProvider.notifier)
          .updateFarmer(
            widget.farmer!.copyWith(
              name: _nameController.text.trim(),
              phoneNumber: _mobileController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              village: _villageController.text.trim(),
              district: _districtController.text.trim(),
              state: _stateController.text.trim(),
            ),
          );
      if (mounted) context.pop();
      return;
    }

    final farmer = await ref
        .read(retailerViewModelProvider.notifier)
        .createFarmer(
          name: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          village: _villageController.text.trim(),
          district: _districtController.text.trim(),
          stateName: _stateController.text.trim(),
        );
    if (!mounted) return;
    if (farmer != null) {
      context.pushReplacement('/retailer/farmer-details', extra: farmer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(retailerViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Farmer' : 'Register Farmer'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Farmer Name *',
                hintText: 'Enter farmer name',
                controller: _nameController,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Mobile Number *',
                hintText: '9876543210',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Email (Optional)',
                hintText: 'farmer@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Village *',
                hintText: 'Enter village',
                controller: _villageController,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'District *',
                hintText: 'Enter district',
                controller: _districtController,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'State *',
                hintText: 'Enter state',
                controller: _stateController,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: _isEditing ? 'Update Farmer' : 'Save Farmer',
                onPressed: _submit,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
