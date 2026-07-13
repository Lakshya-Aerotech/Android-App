import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../models/farm_model.dart';
import '../../viewmodels/farm_viewmodel.dart';
import '../add_farm/add_farm_screen.dart';

class FarmDetailsScreen extends ConsumerWidget {
  final FarmModel farm;
  const FarmDetailsScreen({super.key, required this.farm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Farm Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _editFarm(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _deleteFarm(context, ref),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Static Map Preview
            SizedBox(
              height: 200,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(farm.latitude, farm.longitude),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('farm'),
                    position: LatLng(farm.latitude, farm.longitude),
                  ),
                },
                liteModeEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          farm.farmName,
                          style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                      StatusChip(
                        label: farm.isActive ? 'Active' : 'Inactive',
                        backgroundColor: (farm.isActive ? AppColors.success : Colors.red).withValues(alpha: 0.1),
                        textColor: farm.isActive ? AppColors.success : Colors.red,
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  
                  _buildDetailItem('Crop Type', farm.cropType, Icons.spa_outlined),
                  _buildDetailItem('Total Area', '${farm.area} ${farm.unit}', Icons.crop_free),
                  _buildDetailItem('Village', farm.village, Icons.home_work_outlined),
                  _buildDetailItem('District', farm.district, Icons.location_city_outlined),
                  _buildDetailItem('State', farm.state, Icons.map_outlined),
                  _buildDetailItem('Coordinates', '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}', Icons.gps_fixed),
                  _buildDetailItem('Created On', DateFormat('dd MMM yyyy, hh:mm a').format(farm.createdAt), Icons.calendar_today_outlined),
                  
                  const SizedBox(height: 40),
                  
                  PrimaryButton(
                    text: 'Book Service for this Farm',
                    onPressed: () {
                      // Future Booking Module Integration
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editFarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddFarmScreen(existingFarm: farm)),
    );
  }

  void _deleteFarm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Farm',
        content: 'Are you sure you want to delete "${farm.farmName}"? This will move the farm to inactive state.',
        confirmLabel: 'Delete',
        onConfirm: () {
          ref.read(farmViewModelProvider.notifier).deleteFarm(farm.docId!);
          context.pop(); // Pop dialog
          context.pop(); // Pop details screen
        },
      ),
    );
  }
}
