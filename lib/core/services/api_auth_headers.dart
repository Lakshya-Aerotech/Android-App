import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiAuthHeaders {
  ApiAuthHeaders._();

  static Future<Map<String, String>> create() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Authentication is required.');
    }

    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    return {
      'Authorization': 'Bearer $idToken',
      if (appCheckToken != null && appCheckToken.isNotEmpty)
        'X-Firebase-AppCheck': appCheckToken,
    };
  }
}
