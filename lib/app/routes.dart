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

GoRouter createRouter(WidgetRef ref) {
  // ref.watch garante que o router reage a mudanças no authProvider
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      // Ainda carregando — fica na splash
      if (authState.isLoading) return '/splash';

      // Não logado em rota protegida → login
      if (!authState.isLoggedIn && !isPublic) return '/login';

      // Logado em rota pública → home
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

// Listenable que notifica o GoRouter quando o authProvider muda
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      // Notifica o router sempre que o estado de auth mudar
      if (previous?.isLoggedIn != next.isLoggedIn ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }
}
