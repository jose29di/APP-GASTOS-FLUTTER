import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'package:gastos_erp_tracker/core/services/export_service.dart';
import 'package:gastos_erp_tracker/core/theme/app_colors.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';

class MonthlyCloseScreen extends StatefulWidget {
  const MonthlyCloseScreen({super.key});

  @override
  State<MonthlyCloseScreen> createState() => _MonthlyCloseScreenState();
}

class _MonthlyCloseScreenState extends State<MonthlyCloseScreen> {
  late int _year;
  late int _month;
  bool _loading = true;
  bool _exporting = false;

  double _totalIngresos = 0;
  double _totalEgresos = 0;
  double _totalAnticipos = 0;
  double _ivaBase = 0;
  double _zeroBase = 0;
  double _retencionFuente = 0;
  double _retencionIva = 0;
  double _retencionServProf = 0;
  int _countIngresos = 0;
  int _countEgresos = 0;
  int _countSinFactura = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final firstDay = DateTime(_year, _month, 1);
      final lastDay = DateTime(_year, _month + 1, 1);
      final dateFilter = 'date >= ? AND date < ?';
      final dateArgs = [firstDay.toIso8601String(), lastDay.toIso8601String()];

      final txns = await AppDatabase.query('transactions',
          where: dateFilter, whereArgs: dateArgs, orderBy: 'date DESC');

      double sum(List<Map<String, dynamic>> list, String field) =>
          list.fold<double>(0.0, (double s, Map<String, dynamic> e) => s + ((e[field] as num?)?.toDouble() ?? 0.0));

      final ingresos = txns.where((t) => t['type'] == 'income').toList();
      final egresos = txns.where((t) => t['type'] == 'expense').toList();
      final anticipos = txns.where((t) => t['type'] == 'advance').toList();

      _totalIngresos = sum(ingresos, 'amount');
      _totalEgresos = sum(egresos, 'amount');
      _totalAnticipos = sum(anticipos, 'amount');
      _ivaBase = sum(txns, 'iva_base');
      _zeroBase = sum(txns, 'zero_base');
      _countIngresos = ingresos.length;
      _countEgresos = egresos.length;
      _countSinFactura = txns.where((t) => (t['has_invoice'] as int?) == 0).length;

      final retenciones = await AppDatabase.query('retentions');
      _retencionFuente = retenciones
          .where((r) => r['type'] == 'source')
          .fold<double>(0.0, (double s, Map<String, dynamic> r) => s + ((r['value'] as num?)?.toDouble() ?? 0.0));
      _retencionIva = retenciones
          .where((r) => r['type'] == 'iva')
          .fold<double>(0.0, (double s, Map<String, dynamic> r) => s + ((r['value'] as num?)?.toDouble() ?? 0.0));
      _retencionServProf = retenciones
          .where((r) => r['type'] == 'professional_service')
          .fold<double>(0.0, (double s, Map<String, dynamic> r) => s + ((r['value'] as num?)?.toDouble() ?? 0.0));
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year, _month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccionar mes',
    );
    if (picked != null && mounted) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
      _loadData();
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final path = await ExportService.exportToXls(year: _year, month: _month);
      if (mounted) {
        await ExportService.shareFile(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exportado: $path'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error al exportar'),
            content: Text('$e'),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Mes'),
        actions: [
          IconButton(
            icon: Icon(_exporting ? Icons.hourglass_top : Icons.file_download_outlined),
            tooltip: 'Exportar XLS',
            onPressed: _exporting ? null : _export,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMonthHeader(scheme),
                  const SizedBox(height: 20),
                  _buildSummaryCard('Ingresos', _totalIngresos, AppColors.income, Icons.arrow_downward, _countIngresos, scheme),
                  const SizedBox(height: 10),
                  _buildSummaryCard('Egresos', _totalEgresos, AppColors.expense, Icons.arrow_upward, _countEgresos, scheme),
                  const SizedBox(height: 10),
                  _buildSummaryCard('Anticipos', _totalAnticipos, AppColors.violet, Icons.schedule_outlined, null, scheme),
                  const SizedBox(height: 20),
                  _buildTaxCard(scheme),
                  const SizedBox(height: 20),
                  _buildRetentionCard(scheme),
                  const SizedBox(height: 20),
                  _buildNetoCard(scheme),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: Icon(_exporting ? Icons.hourglass_top : Icons.file_download_outlined),
                      label: Text(_exporting ? 'Exportando...' : 'Exportar a Excel'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader(ColorScheme scheme) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.calendar_month_outlined, color: scheme.onPrimaryContainer),
        ),
        title: Text('${months[_month - 1]} $_year', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$_countIngresos ingresos · $_countEgresos egresos · $_countSinFactura sin factura'),
        trailing: const Icon(Icons.edit_calendar_outlined),
        onTap: _pickMonth,
      ),
    );
  }

  Widget _buildSummaryCard(String label, double total, Color color, IconData icon, int? count, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  if (count != null)
                    Text('$count registros', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(currency(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCard(ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.request_quote_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Bases Tributarias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: 20),
            _row('Base IVA', currency(_ivaBase), scheme),
            const SizedBox(height: 6),
            _row('Base Tarifa 0%', currency(_zeroBase), scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionCard(ColorScheme scheme) {
    final totalRet = _retencionFuente + _retencionIva + _retencionServProf;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent_outlined, color: AppColors.amber),
                const SizedBox(width: 8),
                Text('Retenciones', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: 20),
            _row('Fuente (Renta)', currency(_retencionFuente), scheme),
            const SizedBox(height: 6),
            _row('IVA', currency(_retencionIva), scheme),
            const SizedBox(height: 6),
            _row('Serv. Prof.', currency(_retencionServProf), scheme),
            const Divider(height: 16),
            _row('Total Retenciones', currency(totalRet), scheme, bold: true, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildNetoCard(ColorScheme scheme) {
    final cajaReal = _totalIngresos - _totalEgresos - _totalAnticipos;
    final tributario = _totalIngresos - _totalEgresos;
    return Card(
      color: AppColors.blue.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: AppColors.blue),
                const SizedBox(width: 8),
                Text('Resultado Neto', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: 20),
            _row('Caja Real (con anticipos)', currency(cajaReal), scheme, bold: true, color: AppColors.blue),
            const SizedBox(height: 6),
            _row('Balance Tributario (sin anticipos)', currency(tributario), scheme, bold: true, color: AppColors.blue),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, ColorScheme scheme, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        Text(value, style: TextStyle(
          fontSize: bold ? 15 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? scheme.onSurface,
        )),
      ],
    );
  }
}
