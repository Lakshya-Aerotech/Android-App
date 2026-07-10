import 'package:flutter/material.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lakshya Aerotech',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
