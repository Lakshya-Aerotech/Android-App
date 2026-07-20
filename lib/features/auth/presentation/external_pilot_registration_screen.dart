import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class ExternalPilotRegistrationScreen extends ConsumerStatefulWidget {
  const ExternalPilotRegistrationScreen({super.key});

  @override
  ConsumerState<ExternalPilotRegistrationScreen> createState() =>
      _ExternalPilotRegistrationScreenState();
}

class _ExternalPilotRegistrationScreenState
    extends ConsumerState<ExternalPilotRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _droneDetailsController = TextEditingController();
  final _districtsController = TextEditingController();
  final _radiusController = TextEditingController();

  // Files
  File? _profileImage;
  File? _pilotCert;
  File? _dgcaCert;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _droneDetailsController.dispose();
    _districtsController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        if (type == 'pilot') {
          _pilotCert = File(result.files.single.path!);
        } else {
          _dgcaCert = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photograph')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authViewModelProvider.notifier);

      final registrationData = UserModel(
        role: UserRole.externalPilot,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        aadhaarNumber: _aadhaarController.text.trim(),
        droneDetails: _droneDetailsController.text.trim(),
        operatingDistricts: _districtsController.text.split(',').map((e) => e.trim()).toList(),
        operatingRadius: double.tryParse(_radiusController.text.trim()),
        approvalStatus: ApprovalStatus.pending,
        accountStatus: AccountStatus.inactive,
        isActive: false,
        profileCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // I'll create a more comprehensive registration method in AuthViewModel
      await authNotifier.registerExternalPilotWithFiles(
        user: registrationData,
        password: _passwordController.text,
        profileImage: _profileImage!,
        pilotCert: _pilotCert,
        dgcaCert: _dgcaCert,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Submitted'),
        content: const Text(
          'Your registration has been submitted successfully.\n'
          'Your account will become active after Administrator approval.',
        ),
        actions: [
          PrimaryButton(
            text: 'Back to Login',
            onPressed: () {
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('External Pilot Registration'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Information', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full Name *',
                hintText: 'Enter your full name',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Mobile Number *',
                hintText: '9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email *',
                hintText: 'pilot@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password *',
                hintText: '••••••••',
                controller: _passwordController,
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Address *',
                hintText: 'Enter full address',
                controller: _addressController,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 32),
              Text('Identity', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Aadhaar Number *',
                hintText: '12-digit Aadhaar number',
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 12 ? 'Enter 12 digits' : null,
              ),

              const SizedBox(height: 32),
              Text('Drone Information', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Drone Details *',
                hintText: 'Model, Serial Number, etc.',
                controller: _droneDetailsController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              Text('Operating Information', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Operating Districts *',
                hintText: 'e.g. Warangal, Hyderabad (comma separated)',
                controller: _districtsController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Operating Radius (km) *',
                hintText: 'e.g. 50',
                controller: _radiusController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              Text('Documents & Profile', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              
              _FilePickerTile(
                label: 'Profile Photograph *',
                file: _profileImage,
                onTap: _pickImage,
                isImage: true,
              ),
              const SizedBox(height: 12),
              _FilePickerTile(
                label: 'Drone Pilot Certificate (Optional)',
                file: _pilotCert,
                onTap: () => _pickFile('pilot'),
              ),
              const SizedBox(height: 12),
              _FilePickerTile(
                label: 'DGCA Certificate (Optional)',
                file: _dgcaCert,
                onTap: () => _pickFile('dgca'),
              ),

              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Register as External Pilot',
                isLoading: _isLoading,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  final bool isImage;

  const _FilePickerTile({
    required this.label,
    required this.file,
    required this.onTap,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null ? AppColors.success : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isImage ? Icons.camera_alt_outlined : Icons.upload_file,
                  color: file != null ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null 
                      ? 'Selected: ${file!.path.split('/').last}'
                      : 'Choose ${isImage ? 'Image' : 'File'}',
                    style: TextStyle(
                      color: file != null ? AppColors.success : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
