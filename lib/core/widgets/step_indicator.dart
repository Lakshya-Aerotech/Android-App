import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        bool isCompleted = index < currentStep;
        bool isActive = index == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.accent : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive || isCompleted ? AppColors.accent : AppColors.card,
                      border: Border.all(
                        color: isActive || isCompleted ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: AppColors.textInverted)
                          : Text(
                              '${index + 1}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isActive ? AppColors.textInverted : AppColors.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.accent : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isActive ? AppColors.accent : AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
