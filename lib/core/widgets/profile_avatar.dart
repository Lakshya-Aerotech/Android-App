import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool showEditIcon;
  final VoidCallback? onEdit;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 30,
    this.showEditIcon = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.card,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Icon(Icons.person, size: radius, color: AppColors.textTertiary)
              : null,
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
