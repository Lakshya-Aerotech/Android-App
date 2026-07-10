import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart'; // Placeholder

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Placeholder(), // Initial route
      ),
    ],
  );
}
