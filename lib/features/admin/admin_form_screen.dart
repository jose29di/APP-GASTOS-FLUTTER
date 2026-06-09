import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';

class AdminFormScreen extends StatefulWidget {
  const AdminFormScreen({
    super.key,
    required this.table,
    required this.title,
    required this.labelField,
    this.extraFields = const [],
    this.showRate = false,
    this.showIcon = false,
    this.editItem,
  });

  final String table;
  final String title;
  final String labelField;
  final List<String> extraFields;
  final bool showRate;
  final bool showIcon;
  final Map<String, dynamic>? editItem;

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _nameCon = TextEditingController();
  final _rateCon = TextEditingController();
  final _extraCons = <TextEditingController>[];
  final _formKey = GlobalKey<FormState>();
  String? _icon;

  static const _iconOptions = [
    'precision_manufacturing_outlined',
    'engineering_outlined',
    'handyman_outlined',
    'construction_outlined',
    'person_outline',
    'payments_outlined',
    'account_balance_outlined',
    'credit_card_outlined',
  ];

  IconData _iconData(String name) {
    final map = <String, IconData>{
      'precision_manufacturing_outlined': Icons.precision_manufacturing_outlined,
      'engineering_outlined': Icons.engineering_outlined,
      'handyman_outlined': Icons.handyman_outlined,
      'construction_outlined': Icons.construction_outlined,
      'person_outline': Icons.person_outline,
      'payments_outlined': Icons.payments_outlined,
      'account_balance_outlined': Icons.account_balance_outlined,
      'credit_card_outlined': Icons.credit_card_outlined,
    };
    return map[name] ?? Icons.list_alt_outlined;
  }

  String _iconLabel(String name) {
    return name
        .replaceAll('_outlined', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    for (final _ in widget.extraFields) {
      _extraCons.add(TextEditingController());
    }
    if (widget.editItem != null) {
      _nameCon.text = widget.editItem![widget.labelField] as String? ?? '';
      if (widget.showRate) {
        _rateCon.text = ((widget.editItem!['rate'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(0);
      }
      if (widget.showIcon) {
        _icon = widget.editItem!['icon'] as String?;
      }
      for (var i = 0; i < widget.extraFields.length; i++) {
        _extraCons[i].text = widget.editItem![widget.extraFields[i]] as String? ?? '';
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      widget.labelField: _nameCon.text.trim(),
    };
    if (widget.showRate) {
      data['rate'] = (double.tryParse(_rateCon.text.replaceAll(',', '.')) ?? 0) / 100;
    }
    if (widget.showIcon) {
      data['icon'] = _icon;
    }
    for (var i = 0; i < widget.extraFields.length; i++) {
      data[widget.extraFields[i]] = _extraCons[i].text.trim();
    }

    if (widget.editItem != null) {
      await AppDatabase.update(widget.table, data, where: 'id = ?', whereArgs: [widget.editItem!['id']]);
    } else {
      await AppDatabase.insert(widget.table, data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _rateCon.dispose();
    for (final c in _extraCons) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editItem != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar' : 'Nuevo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCon,
              decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.label_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            if (widget.showRate) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _rateCon,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Porcentaje (%)', prefixIcon: Icon(Icons.percent_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
            ],
            if (widget.showIcon) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _icon,
                decoration: const InputDecoration(labelText: 'Icono', prefixIcon: Icon(Icons.emoji_symbols_outlined)),
                items: _iconOptions.map((name) => DropdownMenuItem(
                  value: name,
                  child: Row(
                    children: [
                      Icon(_iconData(name), size: 20),
                      const SizedBox(width: 10),
                      Text(_iconLabel(name)),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _icon = v),
              ),
            ],
            for (var i = 0; i < widget.extraFields.length; i++) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _extraCons[i],
                decoration: InputDecoration(
                  labelText: widget.extraFields[i],
                  prefixIcon: const Icon(Icons.text_fields_outlined),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
