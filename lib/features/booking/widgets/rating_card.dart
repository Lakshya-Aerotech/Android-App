import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/booking_model.dart';
import '../viewmodels/booking_viewmodel.dart';

class RatingCard extends StatefulWidget {
  final BookingModel booking;

  const RatingCard({super.key, required this.booking});

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard> {
  double _rating = 0;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.booking.rating != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Feedback', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.booking.rating! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            if (widget.booking.feedback != null && widget.booking.feedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(widget.booking.feedback!, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(bookingViewModelProvider).isLoading;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate Our Service', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1.0),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Comments (Optional)',
                hintText: 'Tell us about your experience...',
                controller: _feedbackController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Submit Feedback',
                onPressed: _rating > 0 ? () {
                  ref.read(bookingViewModelProvider.notifier).submitRating(
                    widget.booking.docId!,
                    _rating,
                    _feedbackController.text,
                  );
                } : null,
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }
}
