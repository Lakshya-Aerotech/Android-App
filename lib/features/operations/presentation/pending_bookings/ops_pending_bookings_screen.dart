import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakshya_aerotech/core/constants/app_sizes.dart';
import 'package:lakshya_aerotech/core/theme/app_colors.dart';
import 'package:lakshya_aerotech/core/theme/app_text_styles.dart';
import 'package:lakshya_aerotech/core/widgets/empty_state.dart';
import 'package:lakshya_aerotech/shared/components/dashboard_header.dart';
import 'package:lakshya_aerotech/features/operations/viewmodels/operations_viewmodel.dart';
import 'package:lakshya_aerotech/features/operations/widgets/ops_booking_card.dart';

class OpsPendingBookingsScreen extends ConsumerStatefulWidget {
  const OpsPendingBookingsScreen({super.key});

  @override
  ConsumerState<OpsPendingBookingsScreen> createState() => _OpsPendingBookingsScreenState();
}

class _OpsPendingBookingsScreenState extends ConsumerState<OpsPendingBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final bool _isNewestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(pendingBookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              userName: 'Operations',
              subtitle: 'Review pending requests.',
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
                        'Pending Bookings',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(pendingBookingsStreamProvider),
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  bookingsAsync.when(
                    data: (bookings) {
                      var filtered = bookings.where((b) {
                        final matchesSearch = b.bookingId.toLowerCase().contains(_searchQuery) ||
                                              (b.farmerName?.toLowerCase() ?? '').contains(_searchQuery) ||
                                              b.farmName.toLowerCase().contains(_searchQuery);
                        return matchesSearch;
                      }).toList();

                      if (!_isNewestFirst) filtered = filtered.reversed.toList();

                      if (filtered.isEmpty) {
                        return const EmptyState(
                          title: 'No pending bookings.',
                          message: 'All requests have been reviewed.',
                          icon: Icons.done_all_rounded,
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return OpsBookingCard(
                            booking: filtered[index],
                            onTap: () => context.push('/ops-booking-details', extra: filtered[index]),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
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
}
