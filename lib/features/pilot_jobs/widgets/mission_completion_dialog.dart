import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class MissionCompletionDialog extends StatefulWidget {
  final Function(String notes, double area, String duration, String? chemical) onConfirm;

  const MissionCompletionDialog({super.key, required this.onConfirm});

  @override
  State<MissionCompletionDialog> createState() => _MissionCompletionDialogState();
}

class _MissionCompletionDialogState extends State<MissionCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _areaController = TextEditingController();
  final _durationController = TextEditingController();
  final _chemicalController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _areaController.dispose();
    _durationController.dispose();
    _chemicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mission Completion Report', style: AppTextStyles.titleLarge),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Area Covered (Acres) *',
                hintText: '0.0',
                controller: _areaController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Flight Duration (Mins) *',
                hintText: 'e.g. 15',
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Chemical Used (Optional)',
                hintText: 'e.g. Urea 5L',
                controller: _chemicalController,
              ),
              AppSpacing.verticalMd,
              CustomTextField(
                label: 'Mission Notes *',
                hintText: 'Any observations...',
                controller: _notesController,
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        PrimaryButton(
          text: 'Submit Report',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                _notesController.text,
                double.parse(_areaController.text),
                _durationController.text,
                _chemicalController.text.isEmpty ? null : _chemicalController.text,
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
