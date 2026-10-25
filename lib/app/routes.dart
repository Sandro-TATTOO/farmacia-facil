import 'package:go_router/go_router.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/medications_screen.dart';
import '../screens/user/pharmacies_screen.dart';
import '../screens/user/health_tips_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/shared/main_shell.dart';

// Router simples — a splash cuida do redirecionamento inicial
// e cada tela cuida da sua própria proteção
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
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
