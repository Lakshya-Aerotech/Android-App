import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsSource {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> farms;
  final List<Map<String, dynamic>> drones;

  const AdminAnalyticsSource({
    required this.users,
    required this.bookings,
    required this.farms,
    required this.drones,
  });
}

abstract class AdminAnalyticsRepository {
  Future<AdminAnalyticsSource> fetchAnalyticsSource();
}

class AdminAnalyticsRepositoryImpl implements AdminAnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AdminAnalyticsSource> fetchAnalyticsSource() async {
    final results = await Future.wait([
      _firestore.collection('users').get(),
      _firestore.collection('bookings').get(),
      _firestore.collection('farms').get(),
      _firestore.collection('drones').get(),
    ]);

    return AdminAnalyticsSource(
      users: _docs(results[0]),
      bookings: _docs(results[1]),
      farms: _docs(results[2]),
      drones: _docs(results[3]),
    );
  }

  List<Map<String, dynamic>> _docs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map((doc) => {...doc.data(), '_docId': doc.id}).toList();
  }
}
