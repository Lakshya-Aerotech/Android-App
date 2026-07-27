import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logActivity(ActivityModel activity) async {
    try {
      await _firestore.collection('activities').add(activity.toMap());
    } catch (e) {
      // Fail silently for activity logging
      debugPrint('Error logging activity: $e');
    }
  }

  static Stream<List<ActivityModel>> getRecentActivities({int limit = 20}) {
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    return _firestore
        .collection('activities')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(twoDaysAgo))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Stream<List<ActivityModel>> getAllActivities() {
    return _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
