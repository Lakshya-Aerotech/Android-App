import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/models/user_model.dart';
import '../../farm/presentation/add_farm/add_farm_screen.dart';
import 'retailer_farmer_form_screen.dart';

class RetailerFarmerDetailsScreen extends StatelessWidget {
  final UserModel farmer;

  const RetailerFarmerDetailsScreen({super.key, required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Farmer Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RetailerFarmerFormScreen(farmer: farmer),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (farmer.name?.isNotEmpty ?? false)
                    ? farmer.name![0].toUpperCase()
                    : 'F',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              farmer.name ?? 'Farmer',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow('Mobile Number', farmer.phoneNumber ?? '-'),
            _DetailRow('Email', farmer.email ?? '-'),
            _DetailRow('Village', farmer.village ?? '-'),
            _DetailRow('District', farmer.district ?? '-'),
            _DetailRow('State', farmer.state ?? '-'),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Open Farmer Profile', onPressed: () {}),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Add Farm',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFarmScreen(farmerOverride: farmer),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Book Service',
              onPressed: () =>
                  context.push('/retailer/book-service', extra: farmer),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
