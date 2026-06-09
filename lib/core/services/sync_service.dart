import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

class SyncConfig {
  final int? id;
  final String provider;
  final String? serverUrl;
  final String? apiKey;
  final String? anonKey;
  final String? tursoUrl;
  final String? tursoToken;
  final bool autoSync;
  final int syncIntervalMinutes;
  final String? lastSyncAt;
  final String? lastSyncStatus;
  final bool isEnabled;

  const SyncConfig({
    this.id,
    this.provider = 'supabase',
    this.serverUrl,
    this.apiKey,
    this.anonKey,
    this.tursoUrl,
    this.tursoToken,
    this.autoSync = false,
    this.syncIntervalMinutes = 15,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.isEnabled = false,
  });

  factory SyncConfig.fromMap(Map<String, dynamic> map) => SyncConfig(
    id: map['id'] as int?,
    provider: map['provider'] as String? ?? 'supabase',
    serverUrl: map['server_url'] as String?,
    apiKey: map['api_key'] as String?,
    anonKey: map['anon_key'] as String?,
    tursoUrl: map['turso_url'] as String?,
    tursoToken: map['turso_token'] as String?,
    autoSync: (map['auto_sync'] as int?) == 1,
    syncIntervalMinutes: map['sync_interval_minutes'] as int? ?? 15,
    lastSyncAt: map['last_sync_at'] as String?,
    lastSyncStatus: map['last_sync_status'] as String?,
    isEnabled: (map['is_enabled'] as int?) == 1,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'provider': provider,
    'server_url': serverUrl,
    'api_key': apiKey,
    'anon_key': anonKey,
    'turso_url': tursoUrl,
    'turso_token': tursoToken,
    'auto_sync': autoSync ? 1 : 0,
    'sync_interval_minutes': syncIntervalMinutes,
    'last_sync_at': lastSyncAt,
    'last_sync_status': lastSyncStatus,
    'is_enabled': isEnabled ? 1 : 0,
  };
}

class SyncProgress {
  final double progress;
  final String status;
  SyncProgress(this.progress, this.status);
}

class _TursoHttpException implements Exception {
  final int statusCode;
  final String body;
  _TursoHttpException(this.statusCode, this.body);
  @override
  String toString() => 'HTTP $statusCode: $body';
}

class SyncService {
  SyncService._();

  static void Function(SyncProgress)? onProgress;

  static final List<String> _syncTables = [
    'users', 'contacts', 'transactions', 'retentions',
    'iva_rates', 'projects', 'motives', 'payment_methods', 'retention_rates',
  ];

  // ─── Turso helpers ─────────────────────────────────────────────

  /// Extrae el slug de la org desde URL Turso (ej: "app-jmejia" → "jmejia")
  static String _tursoOrgSlug(String tursoUrl) {
    final host = Uri.parse(tursoUrl.trim().replaceFirst(RegExp(r'^libsql://'), 'https://')).host;
    final first = host.split('.').first;
    return first.contains('-') ? first.split('-').last : first;
  }

  /// Extrae el nombre del database desde URL Turso (ej: "app-jmejia" → "app")
  static String _tursoDbName(String tursoUrl) {
    final host = Uri.parse(tursoUrl.trim().replaceFirst(RegExp(r'^libsql://'), 'https://')).host;
    final first = host.split('.').first;
    if (!first.contains('-')) return first;
    final slug = first.split('-').last;
    return first.substring(0, first.length - slug.length - 1);
  }

  /// Mina un Database Token usando la REST API de Turso (timeout 20s)
  static Future<String> _tursoMintToken(String platformToken, String tursoUrl) async {
    final orgSlug = _tursoOrgSlug(tursoUrl);
    final dbName = _tursoDbName(tursoUrl);
    final uri = Uri.parse('https://api.turso.tech/v1/organizations/$orgSlug/databases/$dbName/auth/tokens?expiration=never&authorization=full-access');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $platformToken');
      request.headers.set('Content-Type', 'application/json');
      final resp = await request.close().timeout(const Duration(seconds: 20));
      final body = await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['jwt'] as String;
      }
      throw Exception('HTTP ${resp.statusCode}: $body');
    } on TimeoutException catch (e) {
      throw Exception('Tiempo de espera agotado al mintear token: $e');
    } finally {
      client.close(force: true);
    }
  }

  /// Convierte URL libsql:// → https://
  static String _httpUrl(String url) {
    var u = url.trim();
    if (u.startsWith('libsql://')) {
      u = 'https://${u.substring(9)}';
    } else if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    return u;
  }

  /// POST a Turso host directo, retorna JSON parseado (con timeout de 20s)
  static Future<Map<String, dynamic>> _httpPostTurso(String hostUrl, String token, String sql) async {
    final client = HttpClient();
    client.userAgent = 'gastos_erp_tracker/1.0';
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('${_httpUrl(hostUrl).replaceAll(RegExp(r'/$'), '')}/v1/execute');
      final body = jsonEncode({'stmt': {'sql': sql}});
      final bodyBytes = utf8.encode(body);

      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Content-Length', bodyBytes.length.toString());
      request.add(bodyBytes);
      final resp = await request.close().timeout(const Duration(seconds: 20));

      final respBody = await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      debugPrint('[TURSO] HTTP ${resp.statusCode}: $respBody');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(respBody) as Map<String, dynamic>;
      }
      throw _TursoHttpException(resp.statusCode, respBody);
    } on TimeoutException catch (e) {
      throw Exception('Tiempo de espera agotado: $e');
    } finally {
      client.close(force: true);
    }
  }

  /// Ejecuta SQL contra Turso. Si el `dbToken` da 401, intenta mintear un
  /// Database Token usando `platformToken` (que debe tener scope db:mint-token).
  /// Retorna (resultado, nuevoDbToken) — si se minteó, nuevoDbToken contiene el
  /// nuevo token; si no, es null.
  static Future<MapEntry<Map<String, dynamic>, String?>> _httpTursoExecute(
    String tursoUrl, String platformToken, String sql, {String? dbToken,
  }) async {
    String effectiveToken = dbToken ?? platformToken;
    bool minted = false;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await _httpPostTurso(tursoUrl, effectiveToken, sql);
        return MapEntry(result, minted ? effectiveToken : null);
      } on _TursoHttpException catch (e) {
        if (e.statusCode == 401 && !minted) {
          try {
            effectiveToken = await _tursoMintToken(platformToken, tursoUrl);
            minted = true;
            debugPrint('[TURSO] Token minteado exitosamente');
            continue;
          } catch (mintError) {
            debugPrint('[TURSO] Error al mintear token: $mintError');
          }
        }
        rethrow;
      }
    }
    throw Exception('No se pudo ejecutar la consulta');
  }

  // ─── Config CRUD ───────────────────────────────────────────────

  static Future<SyncConfig?> getConfig() async {
    final rows = await AppDatabase.query('sync_config', limit: 1);
    if (rows.isEmpty) return null;
    return SyncConfig.fromMap(rows.first);
  }

  static Future<void> saveConfig(SyncConfig config) async {
    final existing = await getConfig();
    if (existing?.id != null) {
      await AppDatabase.update('sync_config', config.toMap(), where: 'id = ?', whereArgs: [existing!.id]);
    } else {
      await AppDatabase.insert('sync_config', config.toMap());
    }
  }

  // ─── Progress ──────────────────────────────────────────────────

  static void _report(double progress, String status) {
    onProgress?.call(SyncProgress(progress, status));
  }

  // ─── HTTP helpers genéricos ────────────────────────────────────

  static Future<T> _retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i >= maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    throw Exception('Reintentos agotados');
  }

  static Future<dynamic> _fetchHttp(Uri uri, {Map<String, String>? headers}) async {
    return _retry(() async {
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body);
      }
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    });
  }

  // ─── Test Connection ───────────────────────────────────────────

  static Future<String> testConnection(SyncConfig config) async {
    try {
      switch (config.provider) {
        case 'turso':
          if (config.tursoUrl == null || config.tursoUrl!.isEmpty || config.tursoToken == null || config.tursoToken!.isEmpty) {
            return 'URL o token vacío';
          }
          debugPrint('[TURSO] URL: ${config.tursoUrl}');
          debugPrint('[TURSO] Token: ${config.tursoToken!.substring(0, 20)}...');
          final entry = await _httpTursoExecute(config.tursoUrl!, config.tursoToken!, 'SELECT 1');
          final result = entry.key;
          final newToken = entry.value;
          final ok = result.containsKey('result') || result.containsKey('results') || result.containsKey('baton');
          debugPrint('[TURSO] Respuesta: $result');
          if (ok && newToken != null) {
            // Guardar el nuevo token minteado
            await saveConfig(SyncConfig(
              id: config.id, provider: config.provider,
              serverUrl: config.serverUrl, apiKey: config.apiKey, anonKey: config.anonKey,
              tursoUrl: config.tursoUrl, tursoToken: newToken,
              autoSync: config.autoSync, syncIntervalMinutes: config.syncIntervalMinutes,
              lastSyncAt: config.lastSyncAt, lastSyncStatus: config.lastSyncStatus,
              isEnabled: config.isEnabled,
            ));
          }
          return ok ? 'ok' : 'Respuesta inesperada: $result';
        case 'supabase':
        case 'custom':
        default:
          if (config.serverUrl == null || config.serverUrl!.isEmpty) return 'URL vacía';
          final url = Uri.parse('${config.serverUrl!.replaceAll(RegExp(r'/$'), '')}/rest/v1/');
          final resp = await _retry(() => http.get(url, headers: {
            'apikey': config.apiKey ?? '',
            'Authorization': 'Bearer ${config.apiKey ?? ''}',
          }));
          return resp.statusCode == 200 ? 'ok' : 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      debugPrint('[TURSO] Error: $e');
      return e.toString();
    }
  }

  // ─── Sync ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> syncAll({SyncConfig? config}) async {
    config ??= await getConfig();
    if (config == null || !config.isEnabled) {
      return {'success': false, 'error': 'Sync no configurado o deshabilitado'};
    }

    try {
      _report(0.0, 'Iniciando sincronización...');

      final localData = <String, List<Map<String, dynamic>>>{};
      double progress = 0.0;

      for (int i = 0; i < _syncTables.length; i++) {
        final table = _syncTables[i];
        _report(progress, 'Leyendo $table...');
        localData[table] = await AppDatabase.query(table);
        progress = 0.05 * ((i + 1) / _syncTables.length);
      }

      _report(progress, 'Subiendo datos...');

      String? mintedToken;
      switch (config.provider) {
        case 'turso':
          mintedToken = await _syncTurso(config, localData, progress);
          break;
        case 'supabase':
        case 'custom':
        default:
          await _syncRest(config, localData, progress);
          break;
      }

      final now = DateTime.now().toIso8601String();
      await saveConfig(SyncConfig(
        id: config.id, provider: config.provider,
        serverUrl: config.serverUrl, apiKey: config.apiKey, anonKey: config.anonKey,
        tursoUrl: config.tursoUrl, tursoToken: mintedToken ?? config.tursoToken,
        autoSync: config.autoSync, syncIntervalMinutes: config.syncIntervalMinutes,
        lastSyncAt: now, lastSyncStatus: 'ok', isEnabled: config.isEnabled,
      ));

      _report(1.0, 'Sincronización completada');
      return {'success': true, 'synced': _syncTables.length};
    } catch (e) {
      await saveConfig(SyncConfig(
        id: config.id, provider: config.provider,
        serverUrl: config.serverUrl, apiKey: config.apiKey, anonKey: config.anonKey,
        tursoUrl: config.tursoUrl, tursoToken: config.tursoToken,
        autoSync: config.autoSync, syncIntervalMinutes: config.syncIntervalMinutes,
        lastSyncAt: DateTime.now().toIso8601String(), lastSyncStatus: 'error: $e',
        isEnabled: config.isEnabled,
      ));
      _report(1.0, 'Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<String?> _syncTurso(SyncConfig config, Map<String, List<Map<String, dynamic>>> data, double startProgress) async {
    double progress = startProgress;
    final range = 0.90 - startProgress;
    String? mintedToken;

    for (int i = 0; i < _syncTables.length; i++) {
      final table = _syncTables[i];
      final rows = data[table]!;
      final step = rows.isEmpty ? 0 : range / _syncTables.length / rows.length;

      for (final row in rows) {
        final cols = row.keys.join(', ');
        final vals = row.values.map((v) {
          if (v == null) return 'NULL';
          if (v is num) return '$v';
          return "'${v.toString().replaceAll("'", "''")}'";
        }).join(', ');
        final stmt = 'INSERT OR REPLACE INTO $table ($cols) VALUES ($vals)';
        final entry = await _httpTursoExecute(config.tursoUrl!, config.tursoToken!, stmt, dbToken: mintedToken);
        if (entry.value != null) mintedToken = entry.value;
        progress += step;
        _report(progress.clamp(0.0, 0.95), 'Subiendo $table...');
      }
    }
    return mintedToken;
  }

  static Future<void> _syncRest(SyncConfig config, Map<String, List<Map<String, dynamic>>> data, double startProgress) async {
    final baseUrl = config.serverUrl!.replaceAll(RegExp(r'/$'), '');
    final headers = {
      'apikey': config.apiKey ?? '',
      'Authorization': 'Bearer ${config.apiKey ?? ''}',
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal',
    };
    final restUrl = '$baseUrl/rest/v1';
    double progress = startProgress;
    final range = 0.90 - startProgress;

    for (int i = 0; i < _syncTables.length; i++) {
      final table = _syncTables[i];
      final rows = data[table]!;
      final step = rows.isEmpty ? 0 : range / _syncTables.length / rows.length;

      for (final row in rows) {
        final id = row['id'];
        await _retry(() => http.post(
          Uri.parse('$restUrl/$table'),
          headers: headers,
          body: jsonEncode({...row, 'id': id, 'synced_at': DateTime.now().toIso8601String()}),
        ));
        progress += step;
        _report(progress.clamp(0.0, 0.95), 'Subiendo $table...');
      }
    }
  }

  // ─── Restore ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> restoreFromRemote({SyncConfig? config}) async {
    config ??= await getConfig();
    if (config == null || !config.isEnabled) {
      return {'success': false, 'error': 'Sync no configurado o deshabilitado'};
    }

    try {
      _report(0.0, 'Iniciando restauración...');

      final remoteData = <String, List<Map<String, dynamic>>>{};

      _report(0.05, 'Conectando con el servidor...');

      String? mintedToken;
      switch (config.provider) {
        case 'turso':
          mintedToken = await _fetchTursoAll(config, remoteData);
          break;
        case 'supabase':
        case 'custom':
        default:
          await _fetchRestAll(config, remoteData);
          break;
      }

      _report(0.5, 'Restaurando datos localmente...');
      // Pequeña pausa para que la UI procese eventos
      await Future.delayed(const Duration(milliseconds: 50));

      final db = await AppDatabase.instance;
      // Limpiar cada tabla fuera de una transacción masiva
      // (permite pausas entre tablas para no congelar la UI)
      for (final table in _syncTables.reversed) {
        await db.delete(table);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      for (int i = 0; i < _syncTables.length; i++) {
        final table = _syncTables[i];
        final rows = remoteData[table] ?? [];
        // Insertar en lotes pequeños, no todo en una transacción
        for (int j = 0; j < rows.length; j += 20) {
          final batch = rows.sublist(j, (j + 20).clamp(0, rows.length));
          await db.transaction((txn) async {
            for (final row in batch) {
              await txn.insert(table, row);
            }
          });
          await Future.delayed(const Duration(milliseconds: 5));
        }
        _report(0.5 + (0.45 * ((i + 1) / _syncTables.length)), 'Restaurando $table...');
        await Future.delayed(const Duration(milliseconds: 30));
      }

      await saveConfig(SyncConfig(
        id: config.id, provider: config.provider,
        serverUrl: config.serverUrl, apiKey: config.apiKey, anonKey: config.anonKey,
        tursoUrl: config.tursoUrl, tursoToken: mintedToken ?? config.tursoToken,
        autoSync: config.autoSync, syncIntervalMinutes: config.syncIntervalMinutes,
        lastSyncAt: DateTime.now().toIso8601String(), lastSyncStatus: 'restored',
        isEnabled: config.isEnabled,
      ));

      _report(1.0, 'Restauración completada');
      return {'success': true, 'tables': _syncTables.length};
    } catch (e) {
      _report(1.0, 'Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<String?> _fetchTursoAll(SyncConfig config, Map<String, List<Map<String, dynamic>>> output) async {
    String? mintedToken;

    for (int i = 0; i < _syncTables.length; i++) {
      final table = _syncTables[i];
      _report(0.05 + (0.45 * (i / _syncTables.length)), 'Descargando $table...');

      final entry = await _httpTursoExecute(config.tursoUrl!, config.tursoToken!, 'SELECT * FROM $table', dbToken: mintedToken);
      if (entry.value != null) mintedToken = entry.value;
      final result = entry.key;

      // Compatible con formato nuevo (result['result']) y viejo (result['results'][0])
      final inner = result['result'] as Map<String, dynamic>?
          ?? (result['results'] as List?)?.firstOrNull as Map<String, dynamic>?;
      final cols = inner?['cols'] as List? ?? [];
      final data = inner?['rows'] as List? ?? [];
      final rows = <Map<String, dynamic>>[];
      for (final row in data) {
        final map = <String, dynamic>{};
        for (int j = 0; j < cols.length && j < row.length; j++) {
          final col = cols[j] is Map ? (cols[j] as Map)['name'] : cols[j];
          map[col.toString()] = _tursoValue(row[j]);
        }
        rows.add(map);
      }
      output[table] = rows;
      // Pausa para que la UI pueda procesar eventos entre descargas
      await Future.delayed(const Duration(milliseconds: 30));
    }
    return mintedToken;
  }

  static dynamic _tursoValue(dynamic val) {
    if (val is Map && val.containsKey('value')) return _tursoValue(val['value']);
    if (val is Map && val.containsKey('type')) {
      if (val['type'] == 'null') return null;
      return val['value'];
    }
    return val;
  }

  static Future<void> _fetchRestAll(SyncConfig config, Map<String, List<Map<String, dynamic>>> output) async {
    final baseUrl = config.serverUrl!.replaceAll(RegExp(r'/$'), '');
    final headers = {
      'apikey': config.apiKey ?? '',
      'Authorization': 'Bearer ${config.apiKey ?? ''}',
    };

    for (int i = 0; i < _syncTables.length; i++) {
      final table = _syncTables[i];
      _report(0.05 + (0.45 * (i / _syncTables.length)), 'Descargando $table...');

      final result = await _fetchHttp(
        Uri.parse('$baseUrl/rest/v1/$table?select=*'),
        headers: headers,
      );

      if (result is List) {
        output[table] = result.cast<Map<String, dynamic>>();
      } else {
        output[table] = [];
      }
    }
  }
}
