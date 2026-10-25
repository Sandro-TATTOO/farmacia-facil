import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// ─── Estado ──────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user:         clearUser  ? null : (user ?? this.user),
      isLoading:    isLoading  ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Flag para evitar dupla atualização durante cadastro/login
  bool _ignoreNextAuthChange = false;

  @override
  AuthState build() {
    // Escuta mudanças de autenticação do Firebase em tempo real
    _auth.authStateChanges().listen(_onAuthStateChanged);
    return const AuthState(isLoading: true);
  }

  // Disparado automaticamente pelo Firebase quando o usuário loga/desloga
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // Se estamos no meio de um login/cadastro manual, ignora esta chamada
    if (_ignoreNextAuthChange) {
      _ignoreNextAuthChange = false;
      return;
    }

    if (firebaseUser == null) {
      state = const AuthState();
      return;
    }

    await _loadUserFromFirestore(firebaseUser);
  }

  // Busca dados do usuário no Firestore e atualiza o estado
  Future<void> _loadUserFromFirestore(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      UserModel userModel;

      if (doc.exists && doc.data() != null) {
        userModel = UserModel.fromMap({
          'id': firebaseUser.uid,
          ...doc.data()!,
        });
      } else {
        // Documento não existe — cria um básico
        userModel = UserModel(
          id:        firebaseUser.uid,
          name:      firebaseUser.displayName ??
                     firebaseUser.email!.split('@')[0],
          email:     firebaseUser.email ?? '',
          phone:     '',
          address:   '',
          createdAt: DateTime.now(),
        );
        await _saveUserToFirestore(userModel);
      }

      state = AuthState(user: userModel);
    } catch (e) {
      _log('Erro ao carregar dados do usuário: $e');
      state = const AuthState();
    }
  }

  // ── Cadastro ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Validações
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Preencha nome, e-mail e senha');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'E-mail inválido');
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Senha deve ter pelo menos 6 caracteres');
      return false;
    }

    try {
      // Evita que _onAuthStateChanged trate este evento
      _ignoreNextAuthChange = true;

      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password,
      );

      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(name.trim());

      final newUser = UserModel(
        id:        firebaseUser.uid,
        name:      name.trim(),
        email:     email.trim().toLowerCase(),
        phone:     phone.trim(),
        address:   address.trim(),
        createdAt: DateTime.now(),
      );

      await _saveUserToFirestore(newUser);

      _log('Cadastro OK: ${newUser.email}');
      // Atualiza estado diretamente — sem passar pelo listener
      state = AuthState(user: newUser);
      return true;

    } on FirebaseAuthException catch (e) {
      _ignoreNextAuthChange = false;
      state = state.copyWith(
          isLoading: false,
          errorMessage: _translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _ignoreNextAuthChange = false;
      _log('Erro no cadastro: $e');
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao cadastrar. Tente novamente.');
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Preencha e-mail e senha');
      return false;
    }

    try {
      // Evita que _onAuthStateChanged trate este evento
      _ignoreNextAuthChange = true;

      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password,
      );

      // Carrega dados do Firestore e atualiza estado diretamente
      await _loadUserFromFirestore(credential.user!);

      _log('Login OK: ${email.trim()}');
      return true;

    } on FirebaseAuthException catch (e) {
      _ignoreNextAuthChange = false;
      state = state.copyWith(
          isLoading: false,
          errorMessage: _translateFirebaseError(e.code));
      return false;
    } catch (e) {
      _ignoreNextAuthChange = false;
      _log('Erro no login: $e');
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao fazer login. Tente novamente.');
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState();
  }

  // ── Salva no Firestore ────────────────────────────────────────────────────
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set({
      'name':      user.name,
      'email':     user.email,
      'phone':     user.phone,
      'address':   user.address,
      'createdAt': user.createdAt.toIso8601String(),
    });
  }

  // ── Traduz erros do Firebase ──────────────────────────────────────────────
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Faça login.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      default:
        return 'Erro de autenticação ($code). Tente novamente.';
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Auth] $msg');
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
