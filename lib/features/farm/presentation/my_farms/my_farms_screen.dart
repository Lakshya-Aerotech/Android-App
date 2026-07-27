import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../viewmodels/farm_viewmodel.dart';
import '../../widgets/detailed_farm_card.dart';
import '../../models/farm_model.dart';
import '../../../../core/localization/app_localizations.dart';

class MyFarmsScreen extends ConsumerStatefulWidget {
  const MyFarmsScreen({super.key});

  @override
  ConsumerState<MyFarmsScreen> createState() => _MyFarmsScreenState();
}

class _MyFarmsScreenState extends ConsumerState<MyFarmsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCrop;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-farm'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.tr('Add Farm'), style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: context.tr('Farmer'),
              subtitle: context.tr('Manage all your registered farms.'),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('My Farms'),
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalMd,

                  // Search and Filter Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged:
                              (value) =>
                                  setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: context.tr('Search by name, village...'),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => _showFilterDialog(),
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.verticalLg,

                  switch (farmsAsync) {
                    AsyncData(:final value) => _buildFarmList(value),
                    AsyncError(:final error) => _buildError(error),
                    _ => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  },
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmList(List<FarmModel> farms) {
    final filteredFarms =
        farms.where((farm) {
          final matchesSearch =
              farm.farmName.toLowerCase().contains(_searchQuery) ||
              farm.village.toLowerCase().contains(_searchQuery) ||
              farm.cropType.toLowerCase().contains(_searchQuery);
          final matchesCrop =
              _selectedCrop == null || farm.cropType == _selectedCrop;
          return matchesSearch && matchesCrop;
        }).toList();

    if (filteredFarms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: EmptyState(
          title: 'No farms added yet.',
          message: 'Start by adding your first farm to book drone services.',
          icon: Icons.landscape_outlined,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredFarms.length,
      itemBuilder: (context, index) {
        final farm = filteredFarms[index];
        return DetailedFarmCard(
          farm: farm,
          onTap: () => context.push('/farm-details', extra: farm),
        );
      },
    );
  }

  Widget _buildError(Object error) {
    debugPrint('Firestore Error in MyFarmsScreen: $error');
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: EmptyState(
        title: 'Unable to load farms.',
        message: 'There was a technical issue. Please try again later.',
        icon: Icons.error_outline,
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Filter Farms'),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(context.tr('By Crop Type'), style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['Cotton', 'Paddy', 'Chilli', 'Maize', 'Soya', 'Other'].map((crop) {
                      final isSelected = _selectedCrop == crop;
                      return ChoiceChip(
                        label: Text(context.tr(crop)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCrop = selected ? crop : null);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() => _selectedCrop = null);
                  Navigator.pop(context);
                },
                child: Text(context.tr('Clear Filters')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
