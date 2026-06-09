import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/app_database.dart';

class AuthService {
  static const _sessionKey = 'auth_session';
  static const _sessionTokenKey = 'auth_session_token';
  static const _sessionCreatedKey = 'auth_session_created';
  static const _userIdKey = 'current_user_id';
  static const _userNameKey = 'current_user_name';
  static const _userEmailKey = 'current_user_email';
  static const _userRoleKey = 'current_user_role';
  static const _sessionDuration = Duration(days: 30);

  static final _secure = FlutterSecureStorage();

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static String _generateToken() {
    final now = DateTime.now().toIso8601String();
    return sha256.convert(utf8.encode('$now-${DateTime.now().microsecondsSinceEpoch}')).toString();
  }

  /// Registra un nuevo usuario. Retorna el usuario creado o null si el email ya existe.
  static Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 4) return null;

    final existing = await AppDatabase.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (existing.isNotEmpty) return null;

    final id = await AppDatabase.insert('users', {
      'name': name.trim(),
      'email': email.toLowerCase().trim(),
      'password_hash': _hash(password),
    });

    return {'id': id, 'name': name.trim(), 'email': email.toLowerCase().trim(), 'role': 'user'};
  }

  /// Inicia sesión. Retorna el usuario o null si credenciales inválidas.
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final users = await AppDatabase.query(
        'users',
        where: 'email = ? AND is_active = 1',
        whereArgs: [email.toLowerCase().trim()],
      );
      if (users.isEmpty) return null;
      final user = users.first;
      if (user['password_hash'] != _hash(password)) return null;

      await _saveSession(user);
      return _sanitizeUser(user);
    } catch (_) {
      return null;
    }
  }

  /// Valida que la sesión actual sea válida contra la base de datos.
  static Future<bool> validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_userIdKey);
      final session = await _secure.read(key: _sessionKey);
      if (id == null || session != 'active') return false;

      final token = await _secure.read(key: _sessionTokenKey);
      final createdStr = await _secure.read(key: _sessionCreatedKey);
      if (token == null || createdStr == null) return false;

      final created = DateTime.tryParse(createdStr);
      if (created == null || DateTime.now().difference(created) > _sessionDuration) {
        await logout();
        return false;
      }

      final users = await AppDatabase.query(
        'users',
        columns: ['id'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [id],
      );
      if (users.isEmpty) {
        await logout();
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Versión simple para SplashScreen (solo verifica sesión sin DB).
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_userIdKey);
      final session = await _secure.read(key: _sessionKey);
      final token = await _secure.read(key: _sessionTokenKey);
      final createdStr = await _secure.read(key: _sessionCreatedKey);

      if (id == null || session != 'active' || token == null || createdStr == null) return false;

      final created = DateTime.tryParse(createdStr);
      if (created == null || DateTime.now().difference(created) > _sessionDuration) {
        await logout();
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _generateToken();
    final now = DateTime.now().toIso8601String();

    await prefs.setInt(_userIdKey, user['id'] as int);
    await prefs.setString(_userNameKey, user['name'] as String);
    await prefs.setString(_userEmailKey, user['email'] as String);
    await prefs.setString(_userRoleKey, user['role'] as String? ?? 'user');

    await _secure.write(key: _sessionKey, value: 'active');
    await _secure.write(key: _sessionTokenKey, value: token);
    await _secure.write(key: _sessionCreatedKey, value: now);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);

    await _secure.delete(key: _sessionKey);
    await _secure.delete(key: _sessionTokenKey);
    await _secure.delete(key: _sessionCreatedKey);
  }

  /// Retorna el usuario actual desde preferencias. Si se solicita refresh, lo busca en DB.
  static Future<Map<String, dynamic>?> currentUser({bool refresh = false}) async {
    try {
      if (refresh) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getInt(_userIdKey);
        if (id == null) return null;
        final users = await AppDatabase.query(
          'users',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (users.isEmpty) return null;
        final user = users.first;
        await _saveSession(user);
        return _sanitizeUser(user);
      }

      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_userIdKey);
      if (id == null) return null;
      return {
        'id': id,
        'name': prefs.getString(_userNameKey) ?? '',
        'email': prefs.getString(_userEmailKey) ?? '',
        'role': prefs.getString(_userRoleKey) ?? 'user',
      };
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _sanitizeUser(Map<String, dynamic> user) {
    return {
      'id': user['id'],
      'name': user['name'] ?? '',
      'email': user['email'] ?? '',
      'role': user['role'] ?? 'user',
      'is_active': user['is_active'] ?? 1,
    };
  }

  static Future<List<Map<String, dynamic>>> listUsers() async {
    return AppDatabase.query('users', columns: ['id', 'name', 'email', 'role', 'is_active']);
  }

  /// Verifica la contraseña del usuario actualmente logueado.
  static Future<bool> validatePassword(String password) async {
    final user = await currentUser();
    if (user == null) return false;
    return verifyPassword(user['id'] as int, password);
  }

  /// Verifica contraseña contra DB (para permisos de escritura entre usuarios).
  static Future<bool> verifyPassword(int userId, String password) async {
    try {
      final users = await AppDatabase.query(
        'users',
        where: 'id = ? AND is_active = 1',
        whereArgs: [userId],
      );
      if (users.isEmpty) return false;
      return users.first['password_hash'] == _hash(password);
    } catch (_) {
      return false;
    }
  }
}
