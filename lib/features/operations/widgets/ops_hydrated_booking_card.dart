import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../booking/models/booking_model.dart';
import '../viewmodels/operations_viewmodel.dart';
import 'ops_booking_card.dart';

class OpsHydratedBookingCard extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const OpsHydratedBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If snapshots are already present, just render the card immediately
    if (booking.farmerName != null && booking.village != null) {
      return OpsBookingCard(booking: booking, onTap: onTap);
    }

    // Otherwise, use the hydration provider
    final hydratedAsync = ref.watch(hydratedBookingProvider(booking));

    return hydratedAsync.when(
      data: (hydratedBooking) => OpsBookingCard(booking: hydratedBooking, onTap: onTap),
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => OpsBookingCard(booking: booking, onTap: onTap), // Fallback to raw if error
    );
  }
}
