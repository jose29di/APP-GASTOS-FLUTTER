import 'dart:convert';
import '../database/app_database.dart';
import 'auth_service.dart';

class AuditService {
  AuditService._();

  static Future<void> log({
    required String action,
    required String entityType,
    required int entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final user = await AuthService.currentUser();
    if (user == null) return;

    await AppDatabase.insert('audit_log', {
      'user_id': user['id'],
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues != null ? jsonEncode(oldValues) : null,
      'new_values': newValues != null ? jsonEncode(newValues) : null,
    });
  }

  static Future<List<Map<String, dynamic>>> getHistory({
    String? entityType,
    int? entityId,
    int? userId,
    int limit = 50,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (entityType != null) {
      conditions.add('a.entity_type = ?');
      args.add(entityType);
    }
    if (entityId != null) {
      conditions.add('a.entity_id = ?');
      args.add(entityId);
    }
    if (userId != null) {
      conditions.add('a.user_id = ?');
      args.add(userId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final whereArgs = args.isNotEmpty ? args : null;

    return AppDatabase.query(
      'audit_log a JOIN users u ON a.user_id = u.id',
      columns: ['a.*', 'u.name as user_name', 'u.email as user_email'],
      where: where,
      whereArgs: whereArgs,
      orderBy: 'a.created_at DESC',
      limit: limit,
    );
  }
}
