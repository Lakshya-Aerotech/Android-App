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

enum _LoginMode { farmer, retailer, employee }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMode _selectedMode = _LoginMode.farmer;

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
    final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
    ref.read(authViewModelProvider.notifier).sendOtp(fullPhone);
  }

  void _onRetailerSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    ref.read(authViewModelProvider.notifier).loginRetailer(email, password);
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
        context.go('/');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Image.asset(
                'assets/images/lakshya_logo.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              // Drone Image
              Image.asset(
                'assets/images/login_drone.png',
                width: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              // Welcome Text
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'Login to continue',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeChip(
                    label: 'Farmer',
                    selected: _selectedMode == _LoginMode.farmer,
                    onTap: () =>
                        setState(() => _selectedMode = _LoginMode.farmer),
                  ),
                  _ModeChip(
                    label: 'Retailer',
                    selected: _selectedMode == _LoginMode.retailer,
                    onTap: () =>
                        setState(() => _selectedMode = _LoginMode.retailer),
                  ),
                  _ModeChip(
                    label: 'Employee',
                    selected: _selectedMode == _LoginMode.employee,
                    onTap: () =>
                        setState(() => _selectedMode = _LoginMode.employee),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedMode == _LoginMode.farmer) ...[
                CustomTextField(
                  label: 'Mobile Number',
                  hintText: '98 7654 3210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '+91',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                AppSpacing.verticalLg,
                PrimaryButton(
                  text: 'Send OTP',
                  isLoading: state.status == AuthStatus.loading,
                  onPressed: _onFarmerSubmit,
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                CustomTextField(
                  label: 'Email',
                  hintText: _selectedMode == _LoginMode.retailer
                      ? 'retailer@lakshya.com'
                      : 'employee@lakshya.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                AppSpacing.verticalMd,
                CustomTextField(
                  label: 'Password',
                  hintText: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                ),
                AppSpacing.verticalLg,
                PrimaryButton(
                  text: _selectedMode == _LoginMode.retailer
                      ? 'Login as Retailer'
                      : 'Login as Employee',
                  isLoading: state.status == AuthStatus.loading,
                  onPressed: _selectedMode == _LoginMode.retailer
                      ? _onRetailerSubmit
                      : _onEmployeeSubmit,
                ),
                if (_selectedMode == _LoginMode.employee)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () => context.push('/retailer-registration'),
                child: Text(
                  'Create Retailer Account',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),

              const SizedBox(height: 48),
              // Footer
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  children: const [
                    TextSpan(text: 'By continuing, you agree to our\n'),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}
