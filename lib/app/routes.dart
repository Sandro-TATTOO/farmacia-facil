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

// Rotas que não precisam de login
const _publicRoutes = ['/splash', '/login', '/register'];

// Cria o router com proteção de rotas baseada no estado de autenticação
GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isPublic  = _publicRoutes.contains(state.matchedLocation);

      // Ainda carregando — fica na splash
      if (authState.isLoading) return '/splash';

      // Não logado tentando acessar rota protegida → vai para login
      if (!authState.isLoggedIn && !isPublic) return '/login';

      // Logado tentando acessar login/cadastro → vai para home
      if (authState.isLoggedIn &&
          (state.matchedLocation == '/login' ||
           state.matchedLocation == '/register' ||
           state.matchedLocation == '/splash')) {
        return '/home';
      }

      return null; // sem redirecionamento
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Autenticação
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // App principal com barra de navegação
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

// Provider do router — permite que o GoRouter leia o authProvider
final routerProvider = Provider<GoRouter>((ref) => createRouter(ref as WidgetRef));
