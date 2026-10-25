import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/medications_screen.dart';
import '../screens/user/pharmacies_screen.dart';
import '../screens/user/health_tips_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/shared/main_shell.dart';

const _publicRoutes = ['/splash', '/login', '/register'];

GoRouter createRouter(Ref ref) {
  // Listenable que notifica o GoRouter quando o auth muda
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isPublic  = _publicRoutes.contains(state.matchedLocation);

      // Ainda carregando — fica na splash
      if (authState.isLoading) return '/splash';

      // Não logado em rota protegida → vai para login
      if (!authState.isLoggedIn && !isPublic) return '/login';

      // Logado em rota pública → vai para home
      if (authState.isLoggedIn && isPublic) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/medications',
            builder: (context, state) => const MedicationsScreen(),
          ),
          GoRoute(
            path: '/pharmacies',
            builder: (context, state) => const PharmaciesScreen(),
          ),
          GoRoute(
            path: '/health-tips',
            builder: (context, state) => const HealthTipsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Notifica o GoRouter quando o estado de autenticação muda
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.isLoggedIn != next.isLoggedIn ||
          previous?.isLoading  != next.isLoading) {
        notifyListeners();
      }
    });
  }
}
