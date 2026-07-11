import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Text(title, style: AppTextStyles.titleLarge),
      content: Text(content, style: AppTextStyles.bodyMedium),
      actions: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: cancelLabel,
                onPressed: onCancel ?? () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: confirmLabel,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
