import 'dart:async';
import 'dart:convert';
import 'dart:developer' show debugger;
import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/core/theme/app_colors.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';
import 'package:gastos_erp_tracker/features/transactions/widgets/amount_input.dart';
import 'package:gastos_erp_tracker/features/transactions/widgets/tax_sub_form.dart';
import 'package:gastos_erp_tracker/shared/widgets/horizontal_choice_chips.dart';
import 'package:gastos_erp_tracker/shared/widgets/labeled_field.dart';
import 'package:gastos_erp_tracker/shared/widgets/section_title.dart';

class TransactionFormScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? parentScaffoldKey;
  final Map<String, dynamic>? existingTransaction;
  const TransactionFormScreen({super.key, this.parentScaffoldKey, this.existingTransaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  String _type = 'expense';
  bool _hasInvoice = true;
  String _category = 'Materia Prima';
  String _payment = 'Efectivo';
  String _scope = 'business';
  DateTime? _dueDate;
  String _project = 'Proyecto Cliente X';
  bool _isPaid = false;
  String _paidMethod = 'Pago completo';
  DateTime _invoiceDate = DateTime.now();

  int? _payAgainstId;
  double _payAgainstRemaining = 0;
  List<Map<String, dynamic>> _payableTransactions = [];

  List<RetentionEntry> _retentionEntries = [];

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _motives = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<String> _sourceRetentionValues = ['1.75%', 'Otro'];
  List<String> _ivaRetentionValues = ['30%', 'Otro'];
  List<String> _profRetentionValues = ['8%', 'Otro'];
  double _ivaRate = 0.12;
  int? _selectedContactId;

  final _amount = TextEditingController();
  final _ivaBase = TextEditingController();
  final _zeroBase = TextEditingController();
  final _vendorCon = TextEditingController();
  final _noteCon = TextEditingController();
  final _facturaCon = TextEditingController();
  final _paidAmountCon = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showRetentionForm = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _loadStep;
  int? _editId;

  double get amount => double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0.0;
  double get paidAmount => double.tryParse(_paidAmountCon.text.replaceAll(',', '.')) ?? 0.0;
  double get ivaBase => double.tryParse(_ivaBase.text.replaceAll(',', '.')) ?? 0.0;

  double _rate(String value) {
    if (value == 'Otro' || value.isEmpty) return 0.0;
    return (double.tryParse(value.replaceAll('%', '')) ?? 0.0) / 100;
  }

  double _retentionBase(String type) {
    if (type == 'iva') return ivaBase * _ivaRate;
    return ivaBase;
  }



  double get totalRetentions => _retentionEntries.fold(0.0, (sum, e) {
    final base = e.customBase ?? _retentionBase(e.type);
    final rate = _rate(e.rateName);
    return sum + base * rate;
  });
  double get netCash => amount - totalRetentions;

  double get _effectivePaidAmount {
    if (!_isPaid && _type != 'advance') return 0.0;
    if (_type == 'advance') return amount;
    if (_paidMethod == 'Pago parcial') return paidAmount > 0 ? paidAmount : amount;
    return amount;
  }

  Color get _stateColor {
    if (_type == 'advance') return AppColors.violet;
    return _type == 'income' ? AppColors.income : AppColors.expense;
  }

  String get _typeLabel {
    switch (_type) {
      case 'income': return 'Ingreso';
      case 'advance': return 'Anticipo';
      default: return 'Egreso';
    }
  }

  String get _contactLabel => _type == 'income' ? 'Cliente' : 'Proveedor';

  String get _selectedPayableLabel {
    if (_payAgainstId == null) return 'Seleccionar factura';
    final t = _payableTransactions.firstWhere(
      (t) => t['id'] == _payAgainstId,
      orElse: () => <String, dynamic>{},
    );
    if (t.isEmpty) return 'Seleccionar factura';
    final label = t['type'] == 'income' ? 'Por cobrar' : 'Por pagar';
    return '${t['project'] ?? 'S/P'} — $label';
  }

  void _openInvoicePicker(BuildContext ctx) {
    final incomes = _payableTransactions.where((t) => t['type'] == 'income').toList();
    final expenses = _payableTransactions.where((t) => t['type'] == 'expense').toList();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (ctx2) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx3, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Text('Seleccionar factura', style: Theme.of(ctx3).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              if (incomes.isNotEmpty) ...[
                Text('Por cobrar (Ingresos)', style: Theme.of(ctx3).textTheme.labelLarge?.copyWith(color: AppColors.income)),
                const SizedBox(height: 8),
                ...incomes.map((t) => _buildInvoiceTile(ctx3, t)),
                const SizedBox(height: 16),
              ],

              if (expenses.isNotEmpty) ...[
                Text('Por pagar (Egresos)', style: Theme.of(ctx3).textTheme.labelLarge?.copyWith(color: AppColors.expense)),
                const SizedBox(height: 8),
                ...expenses.map((t) => _buildInvoiceTile(ctx3, t)),
              ],

              if (incomes.isEmpty && expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No hay facturas pendientes', style: Theme.of(ctx3).textTheme.bodyMedium, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTile(BuildContext ctx, Map<String, dynamic> t) {
    final amt = (t['amount'] as num).toDouble();
    final paid = (t['paid_amount'] as num?)?.toDouble() ?? 0;
    final remaining = amt - paid;
    final isIncome = t['type'] == 'income';
    final label = isIncome ? 'Por cobrar' : 'Por pagar';
    final contact = t['contact_name'] as String? ?? (isIncome ? 'Cliente' : 'Proveedor');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? AppColors.income.withValues(alpha: .15) : AppColors.expense.withValues(alpha: .15),
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? AppColors.income : AppColors.expense),
        ),
        title: Text(t['project'] as String? ?? 'S/P', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$contact · ${currency(remaining)} pendiente'),
        trailing: Chip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          backgroundColor: isIncome ? AppColors.income.withValues(alpha: .15) : AppColors.expense.withValues(alpha: .15),
        ),
        onTap: () {
          setState(() {
            _payAgainstId = t['id'] as int;
            _payAgainstRemaining = remaining;
            _project = t['project'] as String? ?? _project;
            _selectedContactId = t['contact_id'] as int?;
            _vendorCon.text = t['contact_name'] as String? ?? t['vendor'] as String? ?? '';
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _loadError = null; _loadStep = null; });

    // ── Safety timeout: fuerza error si pasa 30s sin completar ──
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _loading) {
        setState(() {
          _loadError = 'TIMEOUT 30s — _loadData no completó. Revisa la terminal para logs.';
          _loading = false;
        });
      }
    });

    final editTx = widget.existingTransaction;
    print('[DEBUG] _loadData INICIADO, editTx=$editTx');

    try {
      print('[DEBUG] Solicitando AuthService.currentUser()...');
      final user = await AuthService.currentUser();
      print('[DEBUG] currentUser result: $user');

      if (user == null) {
        print('[DEBUG] user es null');
        if (mounted) {
          setState(() => _loadError = 'Tu sesión ha expirado. Inicia sesión nuevamente.');
        }
        return;
      }

      // ── Query 1: contacts ──
      if (mounted) setState(() => _loadStep = 'Contactos...');
      print('[DEBUG] Query contacts...');
      late List<Map<String, dynamic>> contacts;
      try {
        contacts = await AppDatabase.query('contacts', where: 'owner_id = ?', whereArgs: [user['id']], orderBy: 'name ASC').timeout(const Duration(seconds: 10));
        print('[DEBUG] contacts OK, count=${contacts.length}');
      } catch (e) {
        print('[DEBUG] contacts ERROR: $e');
        rethrow;
      }

      // ── Query 2: projects ──
      if (mounted) setState(() => _loadStep = 'Proyectos...');
      print('[DEBUG] Query projects...');
      late List<Map<String, dynamic>> projects;
      try {
        projects = await AppDatabase.query('projects', where: 'is_active = 1', orderBy: 'name ASC').timeout(const Duration(seconds: 10));
        print('[DEBUG] projects OK, count=${projects.length}');
      } catch (e) {
        print('[DEBUG] projects ERROR: $e');
        rethrow;
      }

      // ── Query 3: motives ──
      if (mounted) setState(() => _loadStep = 'Motivos...');
      print('[DEBUG] Query motives...');
      late List<Map<String, dynamic>> motives;
      try {
        motives = await AppDatabase.query('motives', where: 'is_active = 1', orderBy: 'name ASC').timeout(const Duration(seconds: 10));
        print('[DEBUG] motives OK, count=${motives.length}');
      } catch (e) {
        print('[DEBUG] motives ERROR: $e');
        rethrow;
      }

      // ── Query 4: payment_methods ──
      if (mounted) setState(() => _loadStep = 'Métodos de pago...');
      print('[DEBUG] Query payment_methods...');
      late List<Map<String, dynamic>> paymentMethods;
      try {
        paymentMethods = await AppDatabase.query('payment_methods', where: 'is_active = 1', orderBy: 'name ASC').timeout(const Duration(seconds: 10));
        print('[DEBUG] payment_methods OK, count=${paymentMethods.length}');
      } catch (e) {
        print('[DEBUG] payment_methods ERROR: $e');
        rethrow;
      }

      // ── Query 5: retention_rates ──
      if (mounted) setState(() => _loadStep = 'Retenciones...');
      print('[DEBUG] Query retention_rates...');
      late List<Map<String, dynamic>> retentions;
      try {
        retentions = await AppDatabase.query('retention_rates', where: 'is_active = 1', orderBy: 'type ASC, rate ASC').timeout(const Duration(seconds: 10));
        print('[DEBUG] retention_rates OK, count=${retentions.length}');
      } catch (e) {
        print('[DEBUG] retention_rates ERROR: $e');
        rethrow;
      }

      // ── Query 6: iva_rates ──
      if (mounted) setState(() => _loadStep = 'IVA...');
      print('[DEBUG] Query iva_rates...');
      late List<Map<String, dynamic>> ivaRates;
      try {
        ivaRates = await AppDatabase.query('iva_rates', where: 'is_active = 1', limit: 1).timeout(const Duration(seconds: 10));
        print('[DEBUG] iva_rates OK, count=${ivaRates.length}');
      } catch (e) {
        print('[DEBUG] iva_rates ERROR: $e');
        rethrow;
      }

      // ── Query 7: transactions ──
      if (mounted) setState(() => _loadStep = 'Transacciones pendientes...');
      print('[DEBUG] Query transactions...');
      late List<Map<String, dynamic>> rawTxns;
      try {
        rawTxns = await AppDatabase.query('transactions', where: 'owner_id = ? AND is_paid = 0', whereArgs: [user['id']], orderBy: 'date DESC').timeout(const Duration(seconds: 10));
        print('[DEBUG] transactions OK, count=${rawTxns.length}');
      } catch (e) {
        print('[DEBUG] transactions ERROR: $e');
        rethrow;
      }

      print('[DEBUG] Todas las queries OK, seteando UI...');

      // ── Pre-cargar datos para editar anticipo ──
      int? advanceRelId;
      double advanceRemaining = 0;
      String? advanceProject;
      if (editTx != null && editTx['type'] == 'advance') {
        advanceRelId = editTx['related_transaction_id'] as int?;
        if (advanceRelId != null) {
          final linked = await AppDatabase.query('transactions',
              where: 'id = ?', whereArgs: [advanceRelId]);
          if (linked.isNotEmpty) {
            final linkedAmt = (linked.first['amount'] as num).toDouble();
            final advances = await AppDatabase.query('transactions',
                where: 'related_transaction_id = ? AND type = ?',
                whereArgs: [advanceRelId, 'advance']);
            final totalAdvancePaid = advances.fold<double>(
              0.0,
              (double s, Map<String, dynamic> a) => s + ((a['paid_amount'] as num?)?.toDouble() ?? 0.0),
            );
            advanceRemaining = linkedAmt - totalAdvancePaid;
            advanceProject = linked.first['project'] as String?;
          }
        }
      }

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _projects = projects;
          _motives = motives;
          _paymentMethods = paymentMethods;

          final txns = List<Map<String, dynamic>>.from(rawTxns.map((t) {
            final c = t['contact_id'] != null
                ? _contacts.firstWhere(
                    (c) => c['id'] == t['contact_id'],
                    orElse: () => <String, dynamic>{},
                  )
                : <String, dynamic>{};
            final copy = Map<String, dynamic>.from(t);
            copy['contact_name'] = c['name'] as String? ?? t['vendor'] as String? ?? '';
            return copy;
          }));
          _payableTransactions = txns;

          _sourceRetentionValues = retentions
              .where((r) => r['type'] == 'source')
              .map((r) => r['name'] as String).toList();
          if (!_sourceRetentionValues.contains('Otro')) _sourceRetentionValues.add('Otro');

          _ivaRetentionValues = retentions
              .where((r) => r['type'] == 'iva')
              .map((r) => r['name'] as String).toList();
          if (!_ivaRetentionValues.contains('Otro')) _ivaRetentionValues.add('Otro');

          _profRetentionValues = retentions
              .where((r) => r['type'] == 'professional_service')
              .map((r) => r['name'] as String).toList();
          if (!_profRetentionValues.contains('Otro')) _profRetentionValues.add('Otro');

          if (ivaRates.isNotEmpty) _ivaRate = (ivaRates.first['rate'] as num).toDouble();

          if (_projects.isNotEmpty) _project = _projects.first['name'] as String? ?? _project;
          if (_motives.isNotEmpty) _category = _motives.first['name'] as String? ?? _category;
          if (_paymentMethods.isNotEmpty) _payment = _paymentMethods.first['name'] as String? ?? _payment;

          // ── Pre-llenar si estamos editando ──
          if (editTx != null) {
            final e = editTx;
            _editId = e['id'] as int?;
            _type = e['type'] as String? ?? 'expense';
            _hasInvoice = (e['has_invoice'] as int?) == 1;
            _category = e['category'] as String? ?? _category;
            _payment = e['payment_method'] as String? ?? _payment;
            _scope = e['scope'] as String? ?? 'business';
            _project = e['project'] as String? ?? _project;
            _isPaid = (e['is_paid'] as int?) == 1;
            _paidMethod = (e['paid_amount'] != null && (e['paid_amount'] as num) < (e['amount'] as num)) ? 'Pago parcial' : 'Pago completo';
            _invoiceDate = DateTime.tryParse(e['date'] as String? ?? '') ?? DateTime.now();
            _dueDate = DateTime.tryParse(e['due_date'] as String? ?? '');
            _selectedContactId = e['contact_id'] as int?;
            _amount.text = (e['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '';
            _ivaBase.text = (e['iva_base'] as num?)?.toDouble().toStringAsFixed(2) ?? '';
            _zeroBase.text = (e['zero_base'] as num?)?.toDouble().toStringAsFixed(2) ?? '';
            _vendorCon.text = e['vendor'] as String? ?? '';
            _noteCon.text = e['notes'] as String? ?? '';
            _facturaCon.text = e['factura_number'] as String? ?? '';
            final paidAmt = (e['paid_amount'] as num?)?.toDouble() ?? 0;
            if (paidAmt > 0) _paidAmountCon.text = paidAmt.toStringAsFixed(2);
            if (_hasInvoice) _showRetentionForm = true;
            if (advanceRelId != null) {
              _payAgainstId = advanceRelId;
              _payAgainstRemaining = advanceRemaining;
              if (advanceProject != null) _project = advanceProject;
            }
          }

          _loading = false;
          _loadStep = null;
        });
      }
    } catch (e) {
      print('[DEBUG] _loadData CATCH: $e');
      debugger(when: true); // Pausa si hay debugger conectado
      if (mounted) {
        setState(() {
          _loadError = '$e';
          _loadStep = null;
        });
      }
    }
  }

  Future<void> _pickDate({required DateTime initial, required ValueChanged<DateTime> onPicked, String helpText = 'Seleccionar fecha'}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: helpText,
    );
    if (picked != null && mounted) setState(() => onPicked(picked));
  }

  Map<String, dynamic> _retentionData(RetentionEntry entry) {
    if (entry.rateName.isEmpty) return {};
    final rate = _rate(entry.rateName);
    final base = entry.customBase ?? _retentionBase(entry.type);
    return {'type': entry.type, 'base_amount': base, 'rate': rate, 'value': base * rate};
  }

  List<String> _validate() {
    final errors = <String>[];
    if (amount <= 0) errors.add('El monto debe ser mayor a 0');
    if (_type == 'expense' && _category.isEmpty) errors.add('Selecciona un motivo');
    if (_project.isEmpty) errors.add('Selecciona un proyecto');
    if (_type != 'advance' && _hasInvoice && _facturaCon.text.trim().isEmpty) errors.add('Ingresa el número de factura');
    if (_isPaid && _paidMethod == 'Pago parcial' && paidAmount <= 0) errors.add('Ingresa el monto pagado');
    if (_isPaid && _paidMethod == 'Pago parcial' && paidAmount > amount) errors.add('El monto pagado no puede superar el total');
    if (_type == 'advance' && _payAgainstId == null) errors.add('Selecciona la transacción a pagar');
    if (_type == 'advance' && amount <= 0) errors.add('Ingresa el monto a pagar');
    if (_type == 'advance' && amount > _payAgainstRemaining) errors.add('El monto a pagar no puede superar el saldo pendiente (\$${_payAgainstRemaining.toStringAsFixed(2)})');
    return errors;
  }

  Future<void> _save() async {
    if (!mounted) return;

    final errors = _validate();
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Errores en el formulario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            )).toList(),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Corregir')),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);
    debugPrint('[SAVE] _saving=true');

    // Seguridad: si tras 20s el saving no se resetéa solo, lo forzamos
    final safetyTimer = Timer(const Duration(seconds: 20), () {
      debugPrint('[SAVE] safety timeout — forcé _saving=false');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La operación tardó demasiado. Intenta de nuevo.'), behavior: SnackBarBehavior.floating),
        );
      }
    });

    late final Map<String, dynamic> record;
    try {
      final user = await AuthService.currentUser();
      if (user == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sesión expirada'),
              content: const Text('Tu sesión ha expirado. Inicia sesión nuevamente.'),
              actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
            ),
          );
        }
        return;
      }

      final categories = {'income': 'Ingreso', 'advance': 'Anticipo', 'expense': _category};

      record = {
        'owner_id': user['id'],
        'contact_id': _selectedContactId,
        'type': _type,
        'amount': amount,
        'category': categories[_type] ?? _category,
        'project': _project,
        'scope': _scope,
        'payment_method': _payment,
        'has_invoice': _hasInvoice ? 1 : 0,
        'factura_number': _hasInvoice ? _facturaCon.text.trim() : null,
        'iva_base': _hasInvoice ? ivaBase : 0.0,
        'zero_base': _hasInvoice ? (double.tryParse(_zeroBase.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
        'is_credit': _isPaid || _type == 'advance' ? 0 : 1,
        'due_date': _dueDate?.toIso8601String(),
        'is_paid': _isPaid || _type == 'advance' ? 1 : 0,
        'paid_amount': _effectivePaidAmount,
        'paid_date': _isPaid || _type == 'advance' ? DateTime.now().toIso8601String() : null,
        'date': _invoiceDate.toIso8601String(),
        'notes': _noteCon.text.trim(),
        'vendor': _vendorCon.text.trim().isEmpty ? 'Sin especificar' : _vendorCon.text.trim(),
        'related_transaction_id': _type == 'advance' ? _payAgainstId : null,
      };

      await AppDatabase.transaction((txn) async {
        int id;
        String action;

        if (_editId != null) {
          // EDITAR: actualizar registro existente
          id = _editId!;
          action = 'update';
          await txn.update('transactions', record, where: 'id = ?', whereArgs: [id]);
          await txn.delete('retentions', where: 'transaction_id = ?', whereArgs: [id]);
          debugPrint('[SAVE] transaction updated id=$id');
        } else {
          // NUEVO: insertar
          id = await txn.insert('transactions', record);
          action = 'create';
          debugPrint('[SAVE] transaction inserted id=$id');
        }

        if (_hasInvoice && _type != 'advance') {
          for (final entry in _retentionEntries) {
            final r = _retentionData(entry);
            if (r.isNotEmpty) {
              await txn.insert('retentions', {'transaction_id': id, ...r});
              debugPrint('[SAVE] retention inserted for tx=$id type=${r['type']}');
            }
          }
        }

        // Recalcular estado de pago de la factura vinculada
        if (_type == 'advance' && _payAgainstId != null) {
          await AppDatabase.recalcularPagado(txn, _payAgainstId!);
        }
        // Si editamos un income/expense, recalcular por si cambió el monto
        if (_editId != null && _type != 'advance') {
          await AppDatabase.recalcularPagado(txn, _editId!);
        }

        // Audit
        final auditUser = await AuthService.currentUser();
        if (auditUser != null) {
          await txn.insert('audit_log', {
            'user_id': auditUser['id'],
            'action': action,
            'entity_type': 'transaction',
            'entity_id': id,
            'new_values': jsonEncode(record),
          });
        }
      });

      debugPrint('[SAVE] transaction committed');
      safetyTimer.cancel();
      _amount.clear();
      _ivaBase.clear();
      _zeroBase.clear();
      _vendorCon.clear();
      _noteCon.clear();
      _facturaCon.clear();
      _paidAmountCon.clear();
      if (mounted) {
        setState(() {
          _type = 'expense';
          _hasInvoice = true;
          _payment = _paymentMethods.isNotEmpty ? _paymentMethods.first['name'] as String? ?? 'Efectivo' : 'Efectivo';
          _scope = 'business';
          _isPaid = false;
          _paidMethod = 'Pago completo';
          _invoiceDate = DateTime.now();
          _dueDate = null;
          _selectedContactId = null;
          _payAgainstId = null;
          _payAgainstRemaining = 0.0;
          _retentionEntries = [];
          _showRetentionForm = false;
        });
        final msg = _editId != null ? 'Registro actualizado' : 'Registro guardado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e, st) {
      debugPrint('[SAVE] error: $e\n$st');
      safetyTimer.cancel();
      if (mounted) {
        // Log types of record fields for debugging
        for (final entry in record.entries) {
          debugPrint('[SAVE] type of ${entry.key}: ${entry.value.runtimeType} = ${entry.value}');
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error al guardar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ocurrió un error inesperado. Intenta de nuevo.'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$e', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                ),
                const SizedBox(height: 12),
                const Text('Stacktrace:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      st.toString().split('\n').take(10).join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [FilledButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Cerrar'))],
          ),
        );
      }
    } finally {
      safetyTimer.cancel();
      if (mounted) setState(() => _saving = false);
      debugPrint('[SAVE] _saving=false');
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _ivaBase.dispose();
    _zeroBase.dispose();
    _vendorCon.dispose();
    _noteCon.dispose();
    _facturaCon.dispose();
    _paidAmountCon.dispose();
    super.dispose();
  }

  IconData _iconFromMotive(String name) {
    final map = <String, IconData>{
      'Materia Prima': Icons.precision_manufacturing_outlined,
      'Mano de Obra': Icons.engineering_outlined,
      'Servicios': Icons.handyman_outlined,
      'Herramientas': Icons.construction_outlined,
      'Personal': Icons.person_outline,
    };
    return map[name] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Abrir menú',
          onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text(_editId != null
            ? 'Editar $_typeLabel'
            : (_type == 'advance' ? 'Registrar Anticipo / Pago' : 'Nuevo registro')),
        actions: [
          IconButton(
            tooltip: 'Recargar datos',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
          // OCR pendiente: escáner de documentos (roadmap #11)
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Cargando datos...'),
                    if (_loadStep != null) ...[
                      const SizedBox(height: 8),
                      Text(_loadStep!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              )
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Error al cargar datos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_loadError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'income', icon: Icon(Icons.south_west), label: Text('Ingreso (+)')),
                  ButtonSegment(value: 'expense', icon: Icon(Icons.north_east), label: Text('Egreso (-)')),
                  ButtonSegment(value: 'advance', icon: Icon(Icons.schedule_outlined), label: Text('Anticipo')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  if (_type != 'advance') _payAgainstId = null;
                  if (_type == 'advance') _hasInvoice = false;
                }),
              ),
              const SizedBox(height: 14),
              if (_type != 'advance')
                AmountInput(controller: _amount, color: _stateColor, onChanged: (_) => setState(() {})),

              // ── Anticipo: pagar contra transacción existente ──
              if (_type == 'advance') ...[
                TextField(
                  controller: _amount,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto a pagar',
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle('Pagar / Cobrar contra'),
                if (_payableTransactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No hay transacciones pendientes', style: Theme.of(context).textTheme.bodySmall),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: _payAgainstId != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.search_outlined),
                      title: Text(_payAgainstId != null
                          ? _selectedPayableLabel
                          : 'Seleccionar factura'),
                      subtitle: _payAgainstId != null
                          ? Text('Saldo: ${currency(_payAgainstRemaining)}')
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openInvoicePicker(context),
                    ),
                  ),
                if (_payAgainstId != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.amber.withValues(alpha: .1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Saldo pendiente: ${currency(_payAgainstRemaining)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                  ),
                  if (amount > 0 && amount < _payAgainstRemaining)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Saldo restante: ${currency(_payAgainstRemaining - amount)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                ],
              ],

              // ── Motivo (solo Egreso) ──
              if (_type == 'expense') ...[
                const SizedBox(height: 18),
                const SectionTitle('Motivo'),
                HorizontalChoiceChips(
                  values: _motives.map((m) => m['name'] as String).toList(),
                  selected: _category,
                  onSelected: (value) => setState(() => _category = value),
                  leadingIcons: Map.fromEntries(
                    _motives.map((m) => MapEntry(m['name'] as String, _iconFromMotive(m['name'] as String))),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // ── Proyecto ──
              LabeledField(
                label: 'Proyecto',
                      child: DropdownButtonFormField<String>(
                          initialValue: _projects.isNotEmpty ? _project : null,
                          items: _projects.isNotEmpty
                              ? _projects.map((p) => DropdownMenuItem(
                                  value: p['name'] as String,
                                  child: Text(p['name'] as String),
                                )).toList()
                              : [const DropdownMenuItem(value: null, child: Text('Sin proyectos'))],
                  onChanged: (value) => setState(() => _project = value ?? _project),
                ),
              ),
              const SizedBox(height: 14),

              // ── Cliente / Proveedor ──
              LabeledField(
                label: _contactLabel,
                child: _contacts.isEmpty
                    ? TextFormField(
                        controller: _vendorCon,
                        decoration: InputDecoration(
                          hintText: 'Nombre del $_contactLabel',
                          prefixIcon: const Icon(Icons.storefront_outlined),
                        ),
                      )
                    : DropdownButtonFormField<int?>(
                        initialValue: _selectedContactId,
                        hint: Text('Seleccionar $_contactLabel'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('— Escribir manual —')),
                          ..._contacts.map((c) => DropdownMenuItem(
                            value: c['id'] as int,
                            child: Text(c['name'] as String),
                          )),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedContactId = v);
                          if (v != null) {
                            final c = _contacts.firstWhere((c) => c['id'] == v);
                            _vendorCon.text = c['name'] as String;
                          } else {
                            _vendorCon.clear();
                          }
                        },
                      ),
              ),
              const SizedBox(height: 14),

              // ── Ámbito ──
              SectionTitle(_type == 'income' ? 'Tipo de ingreso' : 'Tipo de egreso'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'business', label: Text('Trabajo')),
                  ButtonSegment(value: 'personal', label: Text('Personal')),
                ],
                selected: {_scope},
                onSelectionChanged: (v) => setState(() => _scope = v.first),
              ),
              const SizedBox(height: 14),

              // ── Comentarios ──
              LabeledField(
                label: 'Comentarios',
                child: TextFormField(
                  controller: _noteCon,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Detalles opcionales',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Factura ──
              if (_type != 'advance') ...[
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, icon: Icon(Icons.request_quote_outlined), label: Text('Con Factura')),
                          ButtonSegment(value: false, icon: Icon(Icons.payments_outlined), label: Text('Sin Factura')),
                        ],
                        selected: {_hasInvoice},
                        onSelectionChanged: (value) {
                          setState(() {
                            _hasInvoice = value.first;
                            if (!_hasInvoice) _showRetentionForm = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_hasInvoice) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facturaCon,
                    decoration: const InputDecoration(
                      labelText: 'N° de factura / documento',
                      hintText: '001-001-000000001',
                      prefixIcon: Icon(Icons.receipt_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text('Fecha de factura: ${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () => _pickDate(
                        initial: _invoiceDate,
                        onPicked: (d) => _invoiceDate = d,
                        helpText: 'Fecha de factura',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],


                // ── Pagada (con o sin factura) ──
            

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pagado'),
                  subtitle: const Text('Marca si ya realizaste el pago'),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v ?? false),
                ),
                if (_isPaid) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Pago completo', label: Text('Completo')),
                            ButtonSegment(value: 'Pago parcial', label: Text('Parcial')),
                          ],
                          selected: {_paidMethod},
                          onSelectionChanged: (v) => setState(() => _paidMethod = v.first),
                        ),
                      ),
                    ],
                  ),
                  if (_paidMethod == 'Pago parcial') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _paidAmountCon,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto pagado',
                        prefixText: '\$ ',
                        hintText: '0.00',
                      ),
                    ),
                  ],

                  // Método de pago (solo si pagada)
                  const SizedBox(height: 14),
                  const SectionTitle('Método de pago'),
                  HorizontalChoiceChips(
                    values: _paymentMethods.map((m) => m['name'] as String).toList(),
                    selected: _payment,
                    onSelected: (value) => setState(() => _payment = value),
                    leadingIcons: Map.fromEntries(
                      _paymentMethods.map((m) => MapEntry(m['name'] as String, _iconFromMotive(m['name'] as String))),
                    ),
                  ),

                  // ── Resumen de pago ──
                  const SizedBox(height: 12),
                  Card(
                    color: _stateColor.withValues(alpha: .08),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _summaryRow('Valor', currency(amount), scheme),
                          if (_hasInvoice && totalRetentions > 0) ...[
                            const SizedBox(height: 4),
                            _summaryRow('Retenciones', '-${currency(totalRetentions)}', scheme, valueColor: Colors.red),
                          ],
                          const Divider(height: 16),
                          _summaryRow('Neto recibido', currency(amount - totalRetentions), scheme,
                              bold: true, valueColor: _stateColor),
                          if (_paidMethod == 'Pago parcial' && paidAmount > 0 && paidAmount < amount) ...[
                            const SizedBox(height: 4),
                            _summaryRow('Pagado', currency(_effectivePaidAmount), scheme),
                            _summaryRow('Saldo pendiente', currency(amount - _effectivePaidAmount), scheme, valueColor: Colors.orange),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (!_isPaid) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(_dueDate != null
                          ? 'Vence: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Fecha de vencimiento (opcional)'),
                      subtitle: const Text('Si está a crédito, define cuándo vence'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(
                        initial: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                        onPicked: (d) => _dueDate = d,
                        helpText: 'Fecha de vencimiento',
                      ),
                    ),
                  ),
                ],

                // ── Retenciones (solo Con Factura) ──
                if (_hasInvoice) ...[
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Añadir retenciones'),
                    subtitle: const Text('Fuente, IVA, Servicios Profesionales'),
                    value: _showRetentionForm,
                    onChanged: (v) => setState(() => _showRetentionForm = v ?? false),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: _showRetentionForm
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TaxSubForm(
                              ivaBase: _ivaBase,
                              zeroBase: _zeroBase,
                              onBaseChanged: () => setState(() {}),
                              retentions: _retentionEntries,
                              onRetentionsChanged: (v) => setState(() => _retentionEntries = v),
                              sourceValues: _sourceRetentionValues,
                              ivaValues: _ivaRetentionValues,
                              profValues: _profRetentionValues,
                              ivaRate: _ivaRate,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],

              // ── Footer neto ──
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(_stateColor.withValues(alpha: .10), scheme.surface),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _stateColor.withValues(alpha: .22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: _stateColor),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Valor Neto en Efectivo', style: Theme.of(context).textTheme.labelLarge)),
                        Text(
                          currency(_type == 'advance' ? amount : netCash),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _stateColor,
                              ),
                        ),
                      ],
                    ),
                    if (_showRetentionForm && totalRetentions > 0) ...[
                      const SizedBox(height: 8),
                      Divider(),
                      Text('Retenciones: ${currency(totalRetentions)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (_isPaid && _paidMethod == 'Pago parcial' && paidAmount > 0 && paidAmount < amount) ...[
                      const SizedBox(height: 8),
                      Divider(),
                      Text('Pagado: ${currency(paidAmount)} · Pendiente: ${currency(amount - paidAmount)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: _stateColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando...' : (_type == 'advance' ? 'Guardar Anticipo' : 'Guardar $_typeLabel')),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme scheme, {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        Text(value, style: TextStyle(
          fontSize: bold ? 16 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: valueColor ?? scheme.onSurface,
        )),
      ],
    );
  }
}
