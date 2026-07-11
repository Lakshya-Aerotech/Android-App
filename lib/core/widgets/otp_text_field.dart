import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';

class OTPTextField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;

  const OTPTextField({
    super.key,
    this.length = 4,
    required this.onCompleted,
  });

  @override
  State<OTPTextField> createState() => _OTPTextFieldState();
}

class _OTPTextFieldState extends State<OTPTextField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (index) => TextEditingController());
    focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < widget.length - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    String otp = controllers.map((e) => e.text).join();
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 60,
          height: 60,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.titleLarge,
            onChanged: (value) => _onChanged(value, index),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
