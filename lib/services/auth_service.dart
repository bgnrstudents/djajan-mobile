import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

import 'api_service.dart';

enum AuthRole { pelanggan, umkm }

class AuthSession {
  final AuthRole role;
  final Map<String, dynamic> data;

  const AuthSession({required this.role, required this.data});
}

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'djajan_auth_token';
  static const _roleKey = 'djajan_auth_role';

 final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: ApiConfig.googleServerClientId,
  scopes: ['email', 'profile'],
);
  bool _loading = false;
  String? _errorMessage;
  AuthSession? _session;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  AuthSession? get session => _session;

  Future<AuthSession> login(String identifier, String password) async {
    return _run(() async {
      try {
        final data = await ApiService.post('pelanggan/login', {
          'identifier': identifier.trim(),
          'password': password,
        });
        return _setSession(data as Map<String, dynamic>);
      } on ApiException catch (customerError) {
        if (customerError.field != null ||
            !customerError.pesan.contains('salah')) {
          rethrow;
        }
        final data = await ApiService.post('login', {
          'identifier': identifier.trim(),
          'password': password,
        });
        return _setSession(data as Map<String, dynamic>);
      }
    });
  }

  Future<void> register({
    required String nama,
    required String noTelp,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _run(() async {
      final data = await ApiService.post('pelanggan/register', {
        'nama': nama.trim(),
        'no_telp': noTelp.trim(),
        if (email.trim().isNotEmpty) 'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      _setSession(data as Map<String, dynamic>);
      return null;
    });
  }

  Future<AuthSession> loginWithGoogle() async {
    return _run(() async {
      if (ApiConfig.googleServerClientId.isEmpty) {
        throw ApiException(
          'Google Login belum dikonfigurasi. '
          'Jalankan aplikasi dengan Web OAuth Client ID.',
        );
      }

      try {
        await _googleSignIn.signOut();
        final account = await _googleSignIn.signIn();
        if (account == null) {
          throw ApiException('Login Google dibatalkan.');
        }

        final authentication = await account.authentication;
        final idToken = authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw ApiException('Google tidak memberikan ID token yang valid.');
        }

        final data =
            await ApiService.post('auth/google', {'id_token': idToken});
        return _setSession(data as Map<String, dynamic>);
      } on ApiException {
        rethrow;
      } on PlatformException catch (error) {
        throw ApiException(_googleErrorMessage(error));
      } catch (error) {
        throw ApiException('Google Login gagal: $error');
      }
    });
  }

  String _googleErrorMessage(PlatformException error) {
    switch (error.code) {
      case 'sign_in_canceled':
      case 'canceled':
        return 'Login Google dibatalkan.';
      case 'sign_in_failed':
        return 'Google Login gagal. Periksa package Android, SHA-1, dan OAuth Client.';
      case 'network_error':
        return 'Google Login membutuhkan koneksi internet.';
      default:
        return 'Google Login gagal (${error.code}). ${error.message ?? ''}'.trim();
    }
  }

  Future<void> logout() async {
    try {
      if (ApiService.hasToken) {
        final endpoint =
            _session?.role == AuthRole.umkm ? 'logout' : 'pelanggan/logout';
        await ApiService.post(endpoint, {});
      }
    } finally {
      await _googleSignIn.signOut();
      await _clearSession();
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on ApiException catch (error) {
      _errorMessage = error.pesan;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  AuthSession _setSession(Map<String, dynamic> data) {
    final role = data['role'] == 'umkm' ? AuthRole.umkm : AuthRole.pelanggan;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException('Server tidak mengembalikan token login.');
    }
    ApiService.setToken(token);
    _session = AuthSession(role: role, data: data);
    _saveSession(token, role);
    return _session!;
  }

  Future<void> _saveSession(String token, AuthRole role) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_roleKey, role.name);
  }

  Future<void> _clearSession() async {
    ApiService.setToken(null);
    _session = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_roleKey);
    notifyListeners();
  }
}
