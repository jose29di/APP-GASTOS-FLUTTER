import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/theme/app_colors.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';
import 'package:gastos_erp_tracker/shared/widgets/status_badge.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({required this.data, this.onTap, super.key});

  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  IconData _icon(String type, String category) {
    if (type == 'income') return Icons.south_west;
    if (type == 'advance') return Icons.schedule_outlined;
    switch (category) {
      case 'Materia Prima': return Icons.precision_manufacturing_outlined;
      case 'Mano de Obra': return Icons.engineering_outlined;
      case 'Servicios': return Icons.handyman_outlined;
      case 'Herramientas': return Icons.construction_outlined;
      case 'Personal': return Icons.person_outline;
      default: return Icons.receipt_long_outlined;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'income': return AppColors.income;
      case 'advance': return AppColors.violet;
      default: return AppColors.expense;
    }
  }

  String _typePrefix(String type) {
    switch (type) {
      case 'income': return '+';
      case 'advance': return '⏱️';
      default: return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = data['type'] as String? ?? 'expense';
    final color = _color(type);
    final hasInvoice = (data['has_invoice'] as int?) == 1;
    final isPaid = (data['is_paid'] as int?) == 1;
    final vendor = (data['vendor'] as String?) ?? (data['notes'] as String?) ?? 'Sin especificar';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final project = data['project'] as String? ?? '';
    final notes = data['notes'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final isCredit = (data['is_credit'] as int?) == 1;
    final dueDate = data['due_date'] as String?;

    return Card(
      color: scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon(type, category), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${_typePrefix(type)}${currency(amount)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (project.isNotEmpty)
                      Text(project, style: Theme.of(context).textTheme.bodySmall),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(
                          icon: hasInvoice ? Icons.request_quote_outlined : Icons.payments_outlined,
                          label: hasInvoice ? 'Con Factura' : 'Sin Factura',
                        ),
                        if (isCredit)
                          StatusBadge(
                            icon: Icons.schedule_outlined,
                            label: isPaid ? 'Pagado' : 'Pendiente',
                          ),
                        if (isCredit && !isPaid && dueDate != null)
                          StatusBadge(
                            icon: Icons.event_outlined,
                            label: dueDate.length >= 10 ? dueDate.substring(0, 10) : dueDate,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
