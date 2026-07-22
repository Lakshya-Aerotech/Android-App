import 'package:flutter/material.dart';

enum BookingStatus {
  pending,
  reviewed,
  pilotAssigned,
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
  farmerConfirmed,
  closed,
  issueReported,
  cancelled;

  /// Returns a user-friendly display name
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.reviewed:
        return 'Reviewed';
      case BookingStatus.pilotAssigned:
        return 'Pilot Assigned';
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
      case BookingStatus.issueReported:
        return 'Issue Reported';
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
      case BookingStatus.issueReported:
        return Colors.red.shade700;
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
      case BookingStatus.issueReported:
        return Icons.report_problem_outlined;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  /// Serialization for Firestore
  String toFirestore() => name;

  /// Deserialization from Firestore
  static BookingStatus fromString(String? status) {
    if (status == null || status.isEmpty) return BookingStatus.pending;

    // Exact match
    for (var value in BookingStatus.values) {
      if (value.name == status) return value;
    }

    // Normalization fallback (for robustness)
    final normalized = status.toLowerCase().replaceAll('_', '');
    for (var value in BookingStatus.values) {
      if (value.name.toLowerCase() == normalized) return value;
    }

    // Explicit snake_case mappings
    if (status == 'approved') return BookingStatus.reviewed;
    if (status == 'pilot_assigned') return BookingStatus.pilotAssigned;
    if (status == 'en_route') return BookingStatus.enRoute;
    if (status == 'in_progress') return BookingStatus.inProgress;
    if (status == 'farmer_confirmed') return BookingStatus.farmerConfirmed;
    if (status == 'issue_reported') return BookingStatus.issueReported;

    return BookingStatus.pending;
  }
}
