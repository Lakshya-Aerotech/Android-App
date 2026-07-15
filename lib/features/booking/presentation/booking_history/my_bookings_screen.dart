import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/components/dashboard_header.dart';
import '../../../../shared/enums/booking_status.dart';
import '../../models/booking_model.dart';
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
  String? _selectedFilter;

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
      body: Column(
        children: [
          DashboardHeader(
            userName: 'Farmer',
            subtitle: 'Track your drone service bookings.',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Bookings',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/book-service'),
                        icon: const Icon(Icons.add_circle, color: AppColors.accent, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            decoration: const InputDecoration(
                              hintText: 'Search farm or ID...',
                              prefixIcon: Icon(Icons.search, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showFilterDialog,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Icon(Icons.filter_list, color: _selectedFilter != null ? AppColors.accent : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  bookingsAsync.when(
                    data: (bookings) {
                      final filtered = _applyFilters(bookings);

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: EmptyState(
                              title: 'No bookings found.',
                              message: 'Try adjusting your search or filters.',
                              icon: Icons.assignment_outlined,
                            ),
                          ),
                        );
                      }

                      return _buildGroupedList(filtered);
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BookingModel> _applyFilters(List<BookingModel> bookings) {
    var filtered = bookings.where((b) {
      final matchesSearch = b.farmName.toLowerCase().contains(_searchQuery) ||
          b.bookingId.toLowerCase().contains(_searchQuery) ||
          (b.assignedPilotName?.toLowerCase() ?? '').contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (_selectedFilter == null) return filtered;

    switch (_selectedFilter) {
      case 'Upcoming':
        return filtered.where((b) => [
          BookingStatus.pending,
          BookingStatus.reviewed,
          BookingStatus.pilotAssigned,
          BookingStatus.droneAssigned,
          BookingStatus.accepted,
        ].contains(b.status)).toList();
      case 'Active':
        return filtered.where((b) => [
          BookingStatus.enRoute,
          BookingStatus.arrived,
          BookingStatus.inProgress,
        ].contains(b.status)).toList();
      case 'Completed':
        return filtered.where((b) => [
          BookingStatus.completed,
          BookingStatus.farmerConfirmed,
          BookingStatus.closed,
        ].contains(b.status)).toList();
      case 'Cancelled':
        return filtered.where((b) => b.status == BookingStatus.cancelled).toList();
      case 'Issue Reported':
        return filtered.where((b) => b.status == BookingStatus.issueReported).toList();
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return filtered;
      default:
        return filtered;
    }
  }

  Widget _buildGroupedList(List<BookingModel> bookings) {
    if (_selectedFilter != null) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) => BookingHistoryCard(
          booking: bookings[index],
          onTap: () => context.push('/booking-details', extra: bookings[index]),
        ),
      );
    }

    // Default grouping: Active & Upcoming first, then Completed, then others
    final active = bookings.where((b) => [
      BookingStatus.enRoute, BookingStatus.arrived, BookingStatus.inProgress, BookingStatus.completed
    ].contains(b.status)).toList();

    final upcoming = bookings.where((b) => [
      BookingStatus.pending, BookingStatus.reviewed, BookingStatus.pilotAssigned, BookingStatus.droneAssigned, BookingStatus.accepted
    ].contains(b.status)).toList();

    final history = bookings.where((b) => [
      BookingStatus.farmerConfirmed, BookingStatus.closed, BookingStatus.cancelled, BookingStatus.issueReported
    ].contains(b.status)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active.isNotEmpty) ...[
          _buildSectionHeader('Current & Completed Missions'),
          ...active.map((b) => BookingHistoryCard(booking: b, onTap: () => context.push('/booking-details', extra: b))),
          const SizedBox(height: 24),
        ],
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader('Upcoming Assignments'),
          ...upcoming.map((b) => BookingHistoryCard(booking: b, onTap: () => context.push('/booking-details', extra: b))),
          const SizedBox(height: 24),
        ],
        if (history.isNotEmpty) ...[
          _buildSectionHeader('Booking History'),
          ...history.map((b) => BookingHistoryCard(booking: b, onTap: () => context.push('/booking-details', extra: b))),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
    );
  }

  void _showFilterDialog() {
    final filters = ['Upcoming', 'Active', 'Completed', 'Cancelled', 'Issue Reported', 'Newest', 'Oldest'];

    showModalBottomSheet(
      context: context,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                        onSelected: (selected) {
                          setModalState(() => _selectedFilter = selected ? filter : null);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Clear Filters',
                    onPressed: () {
                      setState(() => _selectedFilter = null);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
