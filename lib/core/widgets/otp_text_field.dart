import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OTPTextField extends StatelessWidget {
  final int length;
  final Function(String) onCompleted;
  final TextEditingController? controller;

  const OTPTextField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate box width based on screen size to prevent overflow
    // 40 is a safe minimum width for OTP boxes
    final boxWidth = ((screenWidth - 60) / length).clamp(40.0, 56.0);

    final defaultPinTheme = PinTheme(
      width: boxWidth,
      height: 56,
      textStyle: AppTextStyles.titleLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.success, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primary,
      ),
    );

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Pinput(
        length: length,
        controller: controller,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        onCompleted: onCompleted,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        // Using separatorBuilder to have consistent spacing
        separatorBuilder: (index) => const SizedBox(width: 8),
        cursor: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              width: 2,
              height: 28,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
