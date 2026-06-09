import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';
import 'package:gastos_erp_tracker/features/history/widgets/date_header.dart';
import 'package:gastos_erp_tracker/features/history/widgets/filter_header_delegate.dart';
import 'package:gastos_erp_tracker/features/history/widgets/transaction_card.dart';
import 'package:gastos_erp_tracker/features/transactions/transaction_form_screen.dart';

class SmartHistoryScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? parentScaffoldKey;
  const SmartHistoryScreen({super.key, this.parentScaffoldKey});

  @override
  State<SmartHistoryScreen> createState() => _SmartHistoryScreenState();
}

class _SmartHistoryScreenState extends State<SmartHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.currentUser();
      if (user == null) {
        if (mounted) setState(() { _error = 'Sesión expirada. Inicia sesión nuevamente.'; _loading = false; });
        return;
      }
      final data = await AppDatabase.query(
        'transactions',
        where: 'owner_id = ?',
        whereArgs: [user['id']],
        orderBy: 'date DESC, created_at DESC',
      );
      if (mounted) _transactions = data;
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _dateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(DateTime(date.year, date.month, date.day)).inDays;

      if (diff == 0) return 'Hoy';
      if (diff == 1) return 'Ayer';
      if (diff <= 7) return 'Hace $diff días';

      const months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
      ];
      return '${date.day} de ${months[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showActions(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver detalle'),
              onTap: () { Navigator.pop(ctx); _showDetail(tx); },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () { Navigator.pop(ctx); _editTransaction(tx); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Borrar', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _confirmDelete(tx); },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? 'expense';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type == 'income' ? 'Ingreso' : type == 'advance' ? 'Anticipo' : 'Egreso'} — ${currency(amount)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Proyecto', tx['project'] as String? ?? ''),
              _detailRow('Proveedor', tx['vendor'] as String? ?? ''),
              _detailRow('Categoría', tx['category'] as String? ?? ''),
              _detailRow('Factura #', tx['factura_number'] as String? ?? '—'),
              _detailRow('Fecha', tx['date'] as String? ?? ''),
              _detailRow('Notas', tx['notes'] as String? ?? '—'),
              if (tx['paid_amount'] != null)
                _detailRow('Pagado', currency((tx['paid_amount'] as num).toDouble())),
            ],
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }

  void _editTransaction(Map<String, dynamic> tx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(existingTransaction: tx)),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete(Map<String, dynamic> tx) async {
    final id = tx['id'] as int;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar registro'),
        content: const Text('¿Estás seguro de eliminar este registro? No se puede deshacer.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AppDatabase.transaction((txn) async {
          await txn.delete('retentions', where: 'transaction_id = ?', whereArgs: [id]);
          await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
          final user = await AuthService.currentUser();
          if (user != null) {
            await txn.insert('audit_log', {
              'user_id': user['id'],
              'action': 'delete',
              'entity_type': 'transaction',
              'entity_id': id,
              'old_values': jsonEncode(tx),
            });
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro eliminado'), behavior: SnackBarBehavior.floating),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error al borrar'),
              content: Text('$e'),
              actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir menú',
            onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
          ),
          title: const Text('Historial inteligente'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final grouped = <String, List<int>>{};
    for (var i = 0; i < _transactions.length; i++) {
      final label = _dateLabel(_transactions[i]['date'] as String? ?? '');
      grouped.putIfAbsent(label, () => []).add(i);
    }

    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => (_transactions[b.value.first]['date'] as String? ?? '')
          .compareTo(_transactions[a.value.first]['date'] as String? ?? ''));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Abrir menú',
          onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
        ),
        title: const Text('Historial inteligente'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: FilterHeaderDelegate()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: _transactions.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .4)),
                          const SizedBox(height: 12),
                          Text('No hay registros', style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text('Agrega tu primer ingreso o egreso', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                : SliverList.separated(
                    itemCount: _transactions.length + sortedGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      int running = 0;
                      for (final group in sortedGroups) {
                        if (index == running) return DateHeader(group.key);
                        running++;
                        if (index < running + group.value.length) {
                          return TransactionCard(
                            data: _transactions[group.value[index - running]],
                            onTap: () => _showActions(_transactions[group.value[index - running]]),
                          );
                        }
                        running += group.value.length;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
