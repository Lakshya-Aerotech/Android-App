import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_radius.dart';

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
    // Force a light background for dialogs to ensure visibility of buttons
    return AlertDialog(
      backgroundColor: Colors.white, 
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      title: Text(
        title, 
        style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
      ),
      content: Text(
        content, 
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 12,
          overflowSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 48),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(cancelLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                confirmLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
