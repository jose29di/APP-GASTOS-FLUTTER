import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/core/theme/app_colors.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';
import 'package:gastos_erp_tracker/features/analytics/models/chart_segment.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/bar_comparison_chart.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/chart_panel.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/donut_chart.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/kpi_card.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/legend_dot.dart';
import 'package:gastos_erp_tracker/features/analytics/widgets/threshold_progress.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? parentScaffoldKey;
  const AnalyticsDashboardScreen({super.key, this.parentScaffoldKey});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _taxMode = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.currentUser();
      if (user != null) {
        final data = await AppDatabase.query(
          'transactions',
          where: 'owner_id = ?',
          whereArgs: [user['id']],
        );
        if (mounted) _transactions = data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _totalIncome => _transactions
      .where((t) => t['type'] == 'income')
      .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _totalExpense => _transactions
      .where((t) => t['type'] == 'expense')
      .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _totalAdvances => _transactions
      .where((t) => t['type'] == 'advance')
      .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _netProfit => _totalIncome - _totalExpense - _totalAdvances;

  double get _deductible => _transactions
      .where((t) => t['type'] == 'expense' && (t['has_invoice'] as int?) == 1)
      .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  double get _nonDeductible => _transactions
      .where((t) => t['type'] == 'expense' && (t['has_invoice'] as int?) == 0)
      .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

  List<ChartSegment> get _donutSegments {
    final expenses = _transactions.where((t) => t['type'] == 'expense').toList();
    final total = expenses.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    if (total == 0) return [];

    final byCat = <String, double>{};
    for (final e in expenses) {
      final cat = e['category'] as String? ?? 'Otros';
      byCat.update(cat, (v) => v + ((e['amount'] as num?)?.toDouble() ?? 0), ifAbsent: () => (e['amount'] as num?)?.toDouble() ?? 0);
    }

    final colors = {
      'Materia Prima': AppColors.expense,
      'Mano de Obra': AppColors.amber,
      'Personal': AppColors.blue,
      'Servicios': AppColors.violet,
      'Herramientas': AppColors.expense,
      'Anticipo': AppColors.violet,
      'Ingreso': AppColors.income,
    };

    return byCat.entries.map((e) => ChartSegment(
      colors[e.key] ?? AppColors.expense,
      e.value / total,
      label: e.key,
    )).toList();
  }

  static const _deductibleLimits = <String, double>{
    'Alimentación': 3000,
    'Salud': 2000,
    'Vivienda': 4000,
    'Educación': 3500,
    'Vestimenta': 2500,
  };

  List<MapEntry<String, double>> get _deductibleProgress {
    final totals = <String, double>{};
    for (final limit in _deductibleLimits.keys) {
      totals[limit] = _transactions
          .where((t) => t['type'] == 'expense' && t['category'] == limit)
          .fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
    }
    return totals.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, e.value / (_deductibleLimits[e.key] ?? 1)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir menú',
            onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
          ),
          title: const Text('Balance'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final income = _totalIncome;
    final expense = _totalExpense;
    final advances = _totalAdvances;
    final profit = _netProfit;
    final deductible = _taxMode ? _deductible : expense;
    final nonDeductible = _taxMode ? _nonDeductible : math.max(0.0, expense - _deductible).toDouble();
    final donut = _donutSegments;
    final dedProgress = _deductibleProgress;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Abrir menú',
          onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
        ),
        title: const Text('Balance'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.wallet_outlined), label: Text('Caja Real')),
                ButtonSegment(value: true, icon: Icon(Icons.account_balance_outlined), label: Text('Balance Tributario')),
              ],
              selected: {_taxMode},
              onSelectionChanged: (value) => setState(() => _taxMode = value.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: KpiCard(label: 'Ingresos', value: currency(income), color: AppColors.income, icon: Icons.south_west)),
                const SizedBox(width: 10),
                Expanded(child: KpiCard(label: 'Egresos', value: currency(expense), color: AppColors.expense, icon: Icons.north_east)),
              ],
            ),
            const SizedBox(height: 10),
            KpiCard(
              label: 'Utilidad neta real',
              value: currency(profit),
              color: profit >= 0 ? AppColors.income : AppColors.expense,
              icon: Icons.trending_up_outlined,
              large: true,
            ),
            if (advances > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: KpiCard(
                  label: 'Anticipos activos',
                  value: currency(advances),
                  color: AppColors.violet,
                  icon: Icons.schedule_outlined,
                ),
              ),
            if (donut.isNotEmpty) ...[
              const SizedBox(height: 16),
              ChartPanel(
                title: 'Egresos por motivo',
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: DonutChart(segments: donut),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: donut.map((s) => LegendDot(
                          color: s.color,
                          label: s.label ?? 'Otro',
                          value: '${(s.value * 100).round()}%',
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ChartPanel(
              title: 'Deducible vs. no deducible',
              child: SizedBox(
                height: 180,
                child: BarComparisonChart(deductible: deductible, nonDeductible: nonDeductible),
              ),
            ),
            const SizedBox(height: 14),
            if (dedProgress.isNotEmpty)
              ChartPanel(
                title: 'Termómetro de Deducibles',
                child: Column(
                  children: dedProgress.map((e) {
                    final limit = _deductibleLimits[e.key] ?? 1;
                    final actual = e.value * limit;
                    final colors = {
                      'Alimentación': AppColors.income,
                      'Salud': AppColors.blue,
                      'Vivienda': AppColors.amber,
                      'Educación': AppColors.violet,
                      'Vestimenta': AppColors.expense,
                    };
                    return ThresholdProgress(
                      label: e.key,
                      value: e.value.clamp(0.0, 1.0),
                      amount: '${currency(actual)} / ${currency(limit)}',
                      color: colors[e.key] ?? AppColors.blue,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
