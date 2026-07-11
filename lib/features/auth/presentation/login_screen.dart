import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmployeeMode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFarmerSubmit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    
    // Add country code if not present. Assuming +91 for now.
    final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
    ref.read(authViewModelProvider.notifier).sendOtp(fullPhone);
  }

  void _onEmployeeSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    
    ref.read(authViewModelProvider.notifier).loginEmployee(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.otpSent) {
        context.push('/otp', extra: _phoneController.text.trim());
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/'); // Splash will handle redirect
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.airplanemode_active, size: 60, color: AppColors.accent),
              const SizedBox(height: 40),
              Text('Welcome Back!', style: AppTextStyles.headlineLarge),
              Text('Login to continue', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 40),
              
              if (!_isEmployeeMode) ...[
                CustomTextField(
                  label: 'Mobile Number',
                  hintText: 'Enter your 10 digit number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: Text('+91 ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                AppSpacing.verticalLg,
                PrimaryButton(
                  text: 'Send OTP',
                  isLoading: state.status == AuthStatus.loading,
                  onPressed: _onFarmerSubmit,
                  icon: const Icon(Icons.send_outlined, size: 18),
                ),
              ] else ...[
                CustomTextField(
                  label: 'Email',
                  hintText: 'Enter employee email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                AppSpacing.verticalMd,
                CustomTextField(
                  label: 'Password',
                  hintText: 'Enter password',
                  controller: _passwordController,
                  obscureText: true,
                ),
                AppSpacing.verticalLg,
                PrimaryButton(
                  text: 'Login',
                  isLoading: state.status == AuthStatus.loading,
                  onPressed: _onEmployeeSubmit,
                ),
              ],

              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTextStyles.labelSmall),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 32),
              
              TextButton(
                onPressed: () => setState(() => _isEmployeeMode = !_isEmployeeMode),
                child: Text(
                  _isEmployeeMode ? 'Continue as Farmer' : 'Employee Login',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
                ),
              ),
              
              const SizedBox(height: 40),
              Text(
                'By continuing, you agree to our\nTerms & Conditions and Privacy Policy',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
