import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/otp_text_field.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text('OTP Verification', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 12),
            Text(
              'Enter the 6-digit code sent to\n+91 ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 48),
            OTPTextField(
              length: 6,
              onCompleted: (otp) {
                ref.read(authViewModelProvider.notifier).verifyOtp(otp);
              },
            ),
            const SizedBox(height: 32),
            if (state.status == AuthStatus.loading)
              const CircularProgressIndicator(color: AppColors.accent)
            else
              PrimaryButton(
                text: 'Verify & Continue',
                onPressed: () {
                  // The OTPTextField onCompleted usually handles this, 
                  // but we can add a manual trigger if needed or just let the user know to wait.
                },
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Didn't receive code? ", style: AppTextStyles.bodyMedium),
                TextButton(
                  onPressed: _timerSeconds == 0 
                    ? () {
                        ref.read(authViewModelProvider.notifier).sendOtp('+91${widget.phoneNumber}');
                        _startTimer();
                      } 
                    : null,
                  child: Text(
                    _timerSeconds == 0 ? 'Resend' : 'Resend in ${_timerSeconds}s',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _timerSeconds == 0 ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
