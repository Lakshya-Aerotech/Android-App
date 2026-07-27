import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakshya_aerotech/core/constants/app_sizes.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/empty_state.dart';
import 'package:lakshya_aerotech/shared/components/dashboard_header.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';
import 'package:lakshya_aerotech/features/operations/widgets/ops_hydrated_booking_card.dart';
import 'package:lakshya_aerotech/shared/enums/booking_status.dart';

class OpsPendingBookingsScreen extends ConsumerStatefulWidget {
  const OpsPendingBookingsScreen({super.key});

  @override
  ConsumerState<OpsPendingBookingsScreen> createState() => _OpsPendingBookingsScreenState();
}

class _OpsPendingBookingsScreenState extends ConsumerState<OpsPendingBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedService;
  String? _selectedCrop;
  BookingStatus? _filterStatus;
  bool _isNewestFirst = true;
  int _selectedTab = 0; // 0 for All Bookings, 1 for Reported Issues

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBookingsAsync = ref.watch(allOperationsBookingsStreamProvider);
    final issuesAsync = ref.watch(reportedIssuesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: 'Operations',
              subtitle: 'Manage and review bookings.',
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTab == 0 ? 'All Bookings' : 'Reported Issues',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.invalidate(allOperationsBookingsStreamProvider);
                          ref.invalidate(reportedIssuesStreamProvider);
                        },
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(0, 'All', Icons.assignment_outlined),
                        ),
                        Expanded(
                          child: _buildTab(1, 'Issues', Icons.report_problem_outlined),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search ID, Farmer, Farm...',
                            prefixIcon: const Icon(Icons.search),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      if (_selectedTab == 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _showFilterDialog,
                            icon: const Icon(Icons.filter_list, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  (_selectedTab == 0 ? allBookingsAsync : issuesAsync).when(
                    data: (bookings) {
                      var filtered = bookings.where((b) {
                        final matchesSearch = b.bookingId.toLowerCase().contains(_searchQuery) ||
                                              (b.farmerName?.toLowerCase() ?? '').contains(_searchQuery) ||
                                              b.farmName.toLowerCase().contains(_searchQuery) ||
                                              (b.village?.toLowerCase() ?? '').contains(_searchQuery);
                        
                        final matchesService = _selectedService == null || b.serviceType == _selectedService;
                        final matchesCrop = _selectedCrop == null || b.cropType == _selectedCrop;
                        final matchesStatus = _selectedTab != 0 || _filterStatus == null || b.status == _filterStatus;
                        
                        return matchesSearch && matchesService && matchesCrop && matchesStatus;
                      }).toList();

                      if (!_isNewestFirst) filtered = filtered.reversed.toList();

                      if (filtered.isEmpty) {
                        return EmptyState(
                          title: _selectedTab == 0 ? 'No bookings found.' : 'No reported issues.',
                          message: _selectedTab == 0 ? 'Try adjusting your filters.' : 'Great job! No issues reported.',
                          icon: _selectedTab == 0 ? Icons.search_off_rounded : Icons.check_circle_outline,
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return OpsHydratedBookingCard(
                            booking: filtered[index],
                            onTap: () => context.push('/ops-booking-details', extra: filtered[index]),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter & Sort', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  Text('Status', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusChip(setModalState, 'Pending', BookingStatus.pending),
                      _statusChip(setModalState, 'Reviewed', BookingStatus.reviewed),
                      _statusChip(setModalState, 'Assigned', BookingStatus.pilotAssigned),
                      _statusChip(setModalState, 'Completed', BookingStatus.completed),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text('Sort By', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Newest First'),
                        selected: _isNewestFirst,
                        onSelected: (v) {
                          setModalState(() => _isNewestFirst = true);
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Oldest First'),
                        selected: !_isNewestFirst,
                        onSelected: (v) {
                          setModalState(() => _isNewestFirst = false);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text('Crop Type', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Cotton', 'Paddy', 'Chilli', 'Maize', 'Soya'].map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: _selectedCrop == c,
                        onSelected: (selected) {
                          setModalState(() => _selectedCrop = selected ? c : null);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedService = null;
                          _selectedCrop = null;
                          _filterStatus = null;
                          _isNewestFirst = true;
                        });
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _statusChip(StateSetter setModalState, String label, BookingStatus status) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setModalState(() => _filterStatus = selected ? status : null);
        setState(() {});
      },
    );
  }
}
