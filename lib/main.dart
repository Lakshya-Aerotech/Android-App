import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase here when ready
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
