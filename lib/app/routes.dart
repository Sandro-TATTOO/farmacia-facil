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

// Notifier que o GoRouter escuta para saber quando redirecionar
class AuthRouterNotifier extends ChangeNotifier {
  AuthState _authState;

  AuthRouterNotifier(AuthState initialState) : _authState = initialState;

  AuthState get authState => _authState;

  void update(AuthState newState) {
    if (_authState.isLoggedIn != newState.isLoggedIn ||
        _authState.isLoading  != newState.isLoading) {
      _authState = newState;
      notifyListeners();
    }
  }
}

GoRouter createRouter(WidgetRef ref) {
  // Cria o notifier com o estado inicial
  final notifier = AuthRouterNotifier(ref.read(authProvider));

  // Escuta mudanças no authProvider e atualiza o notifier
  ref.listen<AuthState>(authProvider, (_, next) {
    notifier.update(next);
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth     = notifier.authState;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (auth.isLoading)               return '/splash';
      if (!auth.isLoggedIn && !isPublic) return '/login';
      if (auth.isLoggedIn  && isPublic)  return '/home';

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
