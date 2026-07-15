import 'package:flutter/material.dart';

enum BookingStatus {
  pending,
  reviewed,
  pilotAssigned,
  droneAssigned,
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
  farmerConfirmed,
  closed,
  cancelled;

  /// Returns the enum value from a string, with safety fallbacks
  static BookingStatus fromString(String? status) {
    if (status == null || status.isEmpty) return BookingStatus.pending;

    // Normalize string: lowercase and remove underscores
    final normalized = status.toLowerCase().replaceAll('_', '');

    // Exact match search
    for (var value in BookingStatus.values) {
      if (value.name.toLowerCase() == normalized) return value;
    }

    // Explicit snake_case mappings
    switch (status.toLowerCase()) {
      case 'approved':
        return BookingStatus.reviewed;
      case 'pilot_assigned':
        return BookingStatus.pilotAssigned;
      case 'drone_assigned':
        return BookingStatus.droneAssigned;
      case 'en_route':
        return BookingStatus.enRoute;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'farmer_confirmed':
        return BookingStatus.farmerConfirmed;
    }

    debugPrint(
      'Warning: Unknown BookingStatus string received: $status. Defaulting to pending.',
    );
    return BookingStatus.pending;
  }

  /// Returns a user-friendly display name
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.reviewed:
        return 'Reviewed';
      case BookingStatus.pilotAssigned:
        return 'Pilot Assigned';
      case BookingStatus.droneAssigned:
        return 'Drone Assigned';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.enRoute:
        return 'En Route';
      case BookingStatus.arrived:
        return 'Arrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.farmerConfirmed:
        return 'Confirmed';
      case BookingStatus.closed:
        return 'Closed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns the color associated with this status
  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.reviewed:
        return Colors.blue;
      case BookingStatus.pilotAssigned:
        return Colors.purple;
      case BookingStatus.droneAssigned:
        return Colors.indigo;
      case BookingStatus.accepted:
        return Colors.teal;
      case BookingStatus.enRoute:
        return Colors.cyan;
      case BookingStatus.arrived:
        return Colors.blueGrey;
      case BookingStatus.inProgress:
        return Colors.amber;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.farmerConfirmed:
        return Colors.green.shade700;
      case BookingStatus.closed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  /// Returns the icon associated with this status
  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.pending_actions;
      case BookingStatus.reviewed:
        return Icons.rate_review_outlined;
      case BookingStatus.pilotAssigned:
        return Icons.person_add_outlined;
      case BookingStatus.droneAssigned:
        return Icons.precision_manufacturing_outlined;
      case BookingStatus.accepted:
        return Icons.check_circle_outline;
      case BookingStatus.enRoute:
        return Icons.local_shipping_outlined;
      case BookingStatus.arrived:
        return Icons.location_on_outlined;
      case BookingStatus.inProgress:
        return Icons.run_circle_outlined;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.farmerConfirmed:
        return Icons.verified_user_outlined;
      case BookingStatus.closed:
        return Icons.archive_outlined;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  /// Serialization for Firestore
  String toFirestore() => name;
}
