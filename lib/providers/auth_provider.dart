import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// ─── Chaves de armazenamento local ───────────────────────────────────────────
const _kLoggedUserId = 'ff_loggedUserId';
const _kUsersMap     = 'ff_usersMap';

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
  @override
  AuthState build() {
    Future.microtask(_loadSavedSession);
    return const AuthState(isLoading: true);
  }

  // ── Carrega sessão ao abrir o app ─────────────────────────────────────────
  Future<void> _loadSavedSession() async {
    try {
      final prefs  = await _getPrefs();
      final userId = prefs.getString(_kLoggedUserId);

      _log('Sessão salva: $userId');
      _log('UsersMap: ${prefs.getString(_kUsersMap)}');

      if (userId != null && userId.isNotEmpty) {
        final user = _getUserById(prefs, userId);
        if (user != null) {
          _log('Usuário encontrado: ${user.email}');
          state = AuthState(user: user);
          return;
        }
      }
    } catch (e) {
      _log('Erro ao carregar sessão: $e');
    }

    state = const AuthState();
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
    await Future.delayed(const Duration(milliseconds: 500));

    final emailClean = email.trim().toLowerCase();

    // Validações
    if (name.trim().isEmpty || emailClean.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Preencha nome, e-mail e senha');
      return false;
    }
    if (!emailClean.contains('@') || !emailClean.contains('.')) {
      state = state.copyWith(isLoading: false, errorMessage: 'E-mail inválido');
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Senha deve ter pelo menos 6 caracteres');
      return false;
    }

    try {
      final prefs = await _getPrefs();

      // Verifica duplicidade
      final existing = _getUserByEmail(prefs, emailClean);
      if (existing != null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Este e-mail já está cadastrado. Faça login.');
        return false;
      }

      // Cria e salva o usuário
      final userId = 'u${DateTime.now().millisecondsSinceEpoch}';
      final newUser = UserModel(
        id:        userId,
        name:      name.trim(),
        email:     emailClean,
        phone:     phone.trim(),
        address:   address.trim(),
        createdAt: DateTime.now(),
      );

      _saveUser(prefs, newUser, password);
      await prefs.setString(_kLoggedUserId, userId);

      _log('Cadastro OK: $emailClean | userId: $userId');
      _log('UsersMap após cadastro: ${prefs.getString(_kUsersMap)}');

      state = AuthState(user: newUser);
      return true;
    } catch (e) {
      _log('Erro no cadastro: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao cadastrar. Tente novamente.');
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));

    final emailClean = email.trim().toLowerCase();

    if (emailClean.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Preencha e-mail e senha');
      return false;
    }

    try {
      final prefs = await _getPrefs();

      _log('Tentando login: $emailClean');
      _log('UsersMap atual: ${prefs.getString(_kUsersMap)}');

      final user = _getUserByEmail(prefs, emailClean);

      if (user == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'E-mail não encontrado. Faça seu cadastro.');
        return false;
      }

      final savedPassword = _getPassword(prefs, user.id);
      _log('Senha salva: $savedPassword | Senha digitada: $password');

      if (savedPassword != password) {
        state = state.copyWith(isLoading: false, errorMessage: 'Senha incorreta.');
        return false;
      }

      await prefs.setString(_kLoggedUserId, user.id);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      _log('Erro no login: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao fazer login. Tente novamente.');
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kLoggedUserId);
    state = const AuthState();
  }

  // ─── Helpers síncronos (não precisam de await) ────────────────────────────

  void _saveUser(SharedPreferences prefs, UserModel user, String password) {
    final raw  = prefs.getString(_kUsersMap) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(raw);

    // Salva dados do usuário + senha na mesma entrada
    users[user.id] = {
      'id':        user.id,
      'name':      user.name,
      'email':     user.email,
      'phone':     user.phone,
      'address':   user.address,
      'createdAt': user.createdAt.toIso8601String(),
      'password':  password,
    };

    prefs.setString(_kUsersMap, jsonEncode(users));
  }

  UserModel? _getUserById(SharedPreferences prefs, String userId) {
    final raw = prefs.getString(_kUsersMap) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(raw);
    final data = users[userId];
    if (data == null) return null;
    try {
      return UserModel.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  UserModel? _getUserByEmail(SharedPreferences prefs, String email) {
    final raw = prefs.getString(_kUsersMap) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(raw);

    for (final entry in users.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if ((map['email'] as String? ?? '').toLowerCase() == email) {
        try {
          return UserModel.fromMap(map);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  String? _getPassword(SharedPreferences prefs, String userId) {
    final raw = prefs.getString(_kUsersMap) ?? '{}';
    final Map<String, dynamic> users = jsonDecode(raw);
    final data = users[userId];
    if (data == null) return null;
    return (data as Map)['password'] as String?;
  }

  // Obtém uma instância fresca do SharedPreferences
  Future<SharedPreferences> _getPrefs() async {
    // Recarrega para garantir dados mais recentes (importante no Flutter Web)
    SharedPreferences.resetStatic();
    return SharedPreferences.getInstance();
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Auth] $msg');
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
