import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../app/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  bool _minTimeElapsed = false; // garante tempo mínimo na splash
  bool _authReady      = false; // auth já carregou?
  bool _navigated      = false;
  AuthState? _pendingState;

  @override
  void initState() {
    super.initState();

    // Animação de entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut));

    _animController.forward();

    // Tempo mínimo de 2 segundos na splash (para o usuário ver o logo)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _minTimeElapsed = true;
      _tryNavigate(_pendingState ?? const AuthState());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _tryNavigate(AuthState authState) {
    _pendingState = authState;
    if (_navigated) return;
    if (!_minTimeElapsed) return; // aguarda animação
    if (!_authReady) return;      // aguarda auth carregar

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (authState.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Marca auth como pronto quando isLoading for false
    if (!authState.isLoading && !_authReady) {
      _authReady = true;
      // Chama no próximo frame para não modificar estado durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryNavigate(authState);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    size: 70,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Farmácia Fácil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua saúde mais perto de você',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 60),
                const CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
