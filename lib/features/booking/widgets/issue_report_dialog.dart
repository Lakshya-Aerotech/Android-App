import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../viewmodels/booking_viewmodel.dart';

class IssueReportDialog extends StatefulWidget {
  final String bookingDocId;

  const IssueReportDialog({super.key, required this.bookingDocId});

  @override
  State<IssueReportDialog> createState() => _IssueReportDialogState();
}

class _IssueReportDialogState extends State<IssueReportDialog> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Incomplete Coverage',
    'Poor Spraying',
    'Pilot Delay',
    'Wrong Area',
    'Drone Problem',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report an Issue', style: AppTextStyles.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Issue Category', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choose category'),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Description',
              hintText: 'Describe the issue in detail...',
              controller: _descriptionController,
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, child) {
            final isLoading = ref.watch(bookingViewModelProvider).isLoading;
            return PrimaryButton(
              text: 'Report Issue',
              onPressed: (_selectedCategory != null && _descriptionController.text.isNotEmpty)
                  ? () async {
                      await ref.read(bookingViewModelProvider.notifier).reportIssue(
                        widget.bookingDocId,
                        _selectedCategory!,
                        _descriptionController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              isLoading: isLoading,
            );
          },
        ),
      ],
    );
  }
}
