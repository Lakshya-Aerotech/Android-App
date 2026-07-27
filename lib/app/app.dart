import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routes/app_router.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/locale_viewmodel.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/viewmodel/auth_viewmodel.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeViewModelProvider);
    final user = ref.watch(userModelProvider);

    NotificationService.setRouter(router);
    
    // Ensure user is synced if already available
    if (user != null) {
      if (NotificationService.currentUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.syncUser(user);
        });
      }
      if (user.preferredLanguage != null && locale?.languageCode != user.preferredLanguage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(localeViewModelProvider.notifier).setLocale(Locale(user.preferredLanguage!));
        });
      }
    }

    ref.listen(userModelProvider, (_, next) {
      NotificationService.syncUser(next);
      if (next != null && next.preferredLanguage != null) {
        final currentLocale = ref.read(localeViewModelProvider);
        if (currentLocale?.languageCode != next.preferredLanguage) {
          ref.read(localeViewModelProvider.notifier).setLocale(Locale(next.preferredLanguage!));
        }
      }
    });

    return MaterialApp.router(
      title: 'Lakshya Smartguard systems',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
