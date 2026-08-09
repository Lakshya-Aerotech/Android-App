import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/enums/booking_status.dart';
import '../../viewmodels/operations_viewmodel.dart';

class OpsTrackJobsScreen extends ConsumerWidget {
  const OpsTrackJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(allOperationsBookingsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Job Tracking')),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load jobs: $error')),
        data: (items) {
          final active = items.where((booking) => {
                BookingStatus.enRoute,
                BookingStatus.arrived,
                BookingStatus.inProgress,
              }.contains(booking.status)).toList();
          if (active.isEmpty) {
            return const Center(child: Text('No jobs are currently active.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final booking = active[index];
              return Card(
                child: ListTile(
                  leading: Icon(booking.status.icon, color: booking.status.color),
                  title: Text(booking.bookingId),
                  subtitle: Text(
                    '${booking.farmName} • ${booking.status.displayName}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/ops-booking-details',
                    extra: booking,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
