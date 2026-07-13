import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../widgets/booking_history_card.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(farmerBookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: 'Farmer',
              subtitle: 'Track your drone service bookings.',
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookings',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalMd,

                  // Search and Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search by Farm, Service or ID...',
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
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: IconButton(
                          onPressed: () => _showFilterDialog(),
                          icon: const Icon(Icons.filter_list, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.verticalLg,

                  bookingsAsync.when(
                    data: (bookings) {
                      final filteredBookings = bookings.where((b) {
                        final matchesSearch = b.farmName.toLowerCase().contains(_searchQuery) ||
                                              b.serviceType.toLowerCase().contains(_searchQuery) ||
                                              b.bookingId.toLowerCase().contains(_searchQuery);
                        final matchesStatus = _selectedStatus == null || b.status.name == _selectedStatus;
                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (filteredBookings.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyState(
                            title: 'No bookings found.',
                            message: 'You haven\'t made any bookings yet or no results match your filter.',
                            icon: Icons.assignment_outlined,
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return BookingHistoryCard(
                            booking: booking,
                            onTap: () => context.push('/booking-details', extra: booking),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Center(child: Text('Error loading bookings: $e')),
                  ),
                  const SizedBox(height: 40),
                ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Bookings', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('By Status', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['pending', 'assigned', 'accepted', 'inProgress', 'completed', 'cancelled'].map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedStatus = selected ? status : null);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() => _selectedStatus = null);
                  Navigator.pop(context);
                },
                child: const Text('Clear Filters'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
