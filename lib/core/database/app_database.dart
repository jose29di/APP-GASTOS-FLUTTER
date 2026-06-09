import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'schema.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _instance;

  static Future<Database> get instance async {
    if (_instance != null) return _instance!;
    _instance = await _init();
    return _instance!;
  }

  static Future<Database> _openDb(String path, {bool isRetry = false}) {
    return openDatabase(
      path,
      version: Schema.version,
      onCreate: (db, version) async {
        final statements = Schema.createTables.split(';');
        for (final stmt in statements) {
          final trimmed = stmt.trim();
          if (trimmed.isNotEmpty) {
            await db.execute('$trimmed;');
          }
        }
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final statements = Schema.migrationV1ToV2.split(';');
          for (final stmt in statements) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              try {
                await db.execute('$trimmed;');
              } catch (_) {}
            }
          }
          await _seedDefaults(db);
        }
        if (oldVersion < 3) {
          final statements = Schema.migrationV2ToV3.split(';');
          for (final stmt in statements) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              try {
                await db.execute('$trimmed;');
              } catch (_) {}
            }
          }
          await _seedRetentionRates(db);
        }
        if (oldVersion < 4) {
          final statements = Schema.migrationV3ToV4.split(';');
          for (final stmt in statements) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              try {
                await db.execute('$trimmed;');
              } catch (_) {}
            }
          }
        }
        if (oldVersion < 5) {
          final statements = Schema.migrationV4ToV5.split(';');
          for (final stmt in statements) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              try {
                await db.execute('$trimmed;');
              } catch (_) {}
            }
          }
        }
        if (oldVersion < 6) {
          final statements = Schema.migrationV5ToV6.split(';');
          for (final stmt in statements) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              try {
                await db.execute('$trimmed;');
              } catch (_) {}
            }
          }
        }
      },
    );
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'gastos_erp.db');

    try {
      return await _openDb(path);
    } catch (e) {
      // Si falla la apertura, eliminar BD corrupta y reintentar una vez
      try {
        await deleteDatabase(path);
      } catch (_) {}
      return await _openDb(path, isRetry: true);
    }
  }

  static Future<void> _seedRetentionRates(Database db) async {
    final count = await db.query('retention_rates');
    if (count.isEmpty) {
      await db.insert('retention_rates', {'type': 'source', 'name': '1%', 'rate': 0.01});
      await db.insert('retention_rates', {'type': 'source', 'name': '1.75%', 'rate': 0.0175});
      await db.insert('retention_rates', {'type': 'source', 'name': '2%', 'rate': 0.02});
      await db.insert('retention_rates', {'type': 'source', 'name': '10%', 'rate': 0.10});
      await db.insert('retention_rates', {'type': 'iva', 'name': '10%', 'rate': 0.10});
      await db.insert('retention_rates', {'type': 'iva', 'name': '30%', 'rate': 0.30});
      await db.insert('retention_rates', {'type': 'iva', 'name': '70%', 'rate': 0.70});
      await db.insert('retention_rates', {'type': 'iva', 'name': '100%', 'rate': 1.00});
      await db.insert('retention_rates', {'type': 'professional_service', 'name': '8%', 'rate': 0.08});
      await db.insert('retention_rates', {'type': 'professional_service', 'name': '10%', 'rate': 0.10});
    }
  }

  static Future<void> _seedDefaults(Database db) async {
    final count = await db.query('iva_rates');
    if (count.isEmpty) {
      await db.insert('iva_rates', {'name': 'IVA 12%', 'rate': 0.12});
      await db.insert('iva_rates', {'name': 'IVA 0%', 'rate': 0.0});
      await db.insert('iva_rates', {'name': 'Exento de IVA', 'rate': 0.0});
    }

    final projCount = await db.query('projects');
    if (projCount.isEmpty) {
      await db.insert('projects', {'name': 'Proyecto Cliente X'});
      await db.insert('projects', {'name': 'Remodelación Taller'});
      await db.insert('projects', {'name': 'Obra Casa Norte'});
      await db.insert('projects', {'name': 'Personal'});
    }

    final motCount = await db.query('motives');
    if (motCount.isEmpty) {
      await db.insert('motives', {'name': 'Materia Prima', 'icon': 'precision_manufacturing_outlined'});
      await db.insert('motives', {'name': 'Mano de Obra', 'icon': 'engineering_outlined'});
      await db.insert('motives', {'name': 'Servicios', 'icon': 'handyman_outlined'});
      await db.insert('motives', {'name': 'Herramientas', 'icon': 'construction_outlined'});
      await db.insert('motives', {'name': 'Personal', 'icon': 'person_outline'});
    }

    final pmCount = await db.query('payment_methods');
    if (pmCount.isEmpty) {
      await db.insert('payment_methods', {'name': 'Efectivo', 'icon': 'payments_outlined'});
      await db.insert('payment_methods', {'name': 'Transferencia', 'icon': 'account_balance_outlined'});
      await db.insert('payment_methods', {'name': 'Tarjeta', 'icon': 'credit_card_outlined'});
    }

    await _seedRetentionRates(db);
  }

  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert(table, data);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await instance;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await instance;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  static Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await instance;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  static Future<T?> transaction<T>(Future<T> Function(Transaction txn) fn) async {
    final db = await instance;
    return db.transaction(fn);
  }
  
  static Future<void> recalcularPagado(dynamic db, int transactionId) async {
    final advances = (await db.query('transactions',
      where: 'related_transaction_id = ? AND type = ?',
      whereArgs: [transactionId, 'advance'])) as List<Map<String, dynamic>>;
    final totalPaidFromAdvances = advances.fold<double>(0.0, (double s, Map<String, dynamic> a) => s + ((a['paid_amount'] as num?)?.toDouble() ?? 0.0));
    final orig = (await db.query('transactions',
      where: 'id = ?', whereArgs: [transactionId])) as List<Map<String, dynamic>>;
    if (orig.isEmpty) return;
    final origAmount = (orig.first['amount'] as num).toDouble();
    final directPaid = (orig.first['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = totalPaidFromAdvances > directPaid
        ? totalPaidFromAdvances
        : directPaid;
    await db.update('transactions',
      {
        'is_paid': totalPaid >= origAmount ? 1 : 0,
        'paid_amount': totalPaid >= origAmount ? origAmount : totalPaid,
      },
      where: 'id = ?', whereArgs: [transactionId]);
  }
}
