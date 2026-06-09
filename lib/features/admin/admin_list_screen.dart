import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'admin_form_screen.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({
    super.key,
    required this.table,
    required this.title,
    required this.labelField,
    this.extraFields = const [],
    this.showRate = false,
    this.showIcon = false,
  });

  final String table;
  final String title;
  final String labelField;
  final List<String> extraFields;
  final bool showRate;
  final bool showIcon;

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppDatabase.query(widget.table, orderBy: 'name ASC');
    if (mounted) setState(() { _items = data; _loading = false; });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await AppDatabase.delete(widget.table, where: 'id = ?', whereArgs: [id]);
      _load();
    }
  }

  IconData _iconFromString(String? name) {
    if (name == null) return Icons.list_alt_outlined;
    // Mapeo de nombres de iconos
    final icons = <String, IconData>{
      'precision_manufacturing_outlined': Icons.precision_manufacturing_outlined,
      'engineering_outlined': Icons.engineering_outlined,
      'handyman_outlined': Icons.handyman_outlined,
      'construction_outlined': Icons.construction_outlined,
      'person_outline': Icons.person_outline,
      'payments_outlined': Icons.payments_outlined,
      'account_balance_outlined': Icons.account_balance_outlined,
      'credit_card_outlined': Icons.credit_card_outlined,
    };
    return icons[name] ?? Icons.list_alt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AdminFormScreen(
                  table: widget.table,
                  title: widget.title,
                  labelField: widget.labelField,
                  extraFields: widget.extraFields,
                  showRate: widget.showRate,
                  showIcon: widget.showIcon,
                ),
              ));
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .4)),
                      const SizedBox(height: 12),
                      Text('Sin elementos', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text('Agrega el primer elemento', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AdminFormScreen(
                              table: widget.table,
                              title: widget.title,
                              labelField: widget.labelField,
                              extraFields: widget.extraFields,
                              showRate: widget.showRate,
                              showIcon: widget.showIcon,
                            ),
                          ));
                          _load();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final active = (item['is_active'] as int?) == 1;
                      return ListTile(
                        leading: widget.showIcon && item['icon'] != null
                            ? Icon(_iconFromString(item['icon'] as String?), color: active ? null : Colors.grey)
                            : null,
                        title: Text(item[widget.labelField] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: active ? null : Colors.grey)),
                        subtitle: widget.showRate && item['rate'] != null
                            ? Text([
                                if (widget.extraFields.isNotEmpty)
                                  item[widget.extraFields.first] as String? ?? '',
                                '${((item['rate'] as num) * 100).toStringAsFixed(0)}%',
                              ].where((s) => s.isNotEmpty).join(' · '))
                            : widget.extraFields.isNotEmpty
                                ? Text(item[widget.extraFields.first] as String? ?? '')
                                : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? Colors.green : Colors.grey),
                              onPressed: () async {
                                await AppDatabase.update(widget.table, {'is_active': active ? 0 : 1}, where: 'id = ?', whereArgs: [item['id']]);
                                _load();
                              },
                            ),
                            PopupMenuButton(
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  child: const ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), dense: true, visualDensity: VisualDensity.compact),
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => AdminFormScreen(
                                        table: widget.table,
                                        title: widget.title,
                                        labelField: widget.labelField,
                                        extraFields: widget.extraFields,
                                        showRate: widget.showRate,
                                        showIcon: widget.showIcon,
                                        editItem: item,
                                      ),
                                    ));
                                    _load();
                                  },
                                ),
                                PopupMenuItem(
                                  child: const ListTile(leading: Icon(Icons.delete_outlined, color: Colors.red), title: Text('Eliminar', style: TextStyle(color: Colors.red)), dense: true, visualDensity: VisualDensity.compact),
                                  onTap: () => _delete(item['id'] as int),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
