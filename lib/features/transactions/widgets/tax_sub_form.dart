import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';
import 'package:gastos_erp_tracker/shared/widgets/horizontal_choice_chips.dart';

class RetentionEntry {
  String type;
  String rateName;
  String? customBaseText;

  RetentionEntry({required this.type, this.rateName = '', this.customBaseText});

  double? get customBase {
    if (customBaseText == null || customBaseText!.isEmpty) return null;
    return double.tryParse(customBaseText!.replaceAll(',', '.'));
  }
}

class TaxSubForm extends StatelessWidget {
  const TaxSubForm({
    required this.ivaBase,
    required this.zeroBase,
    required this.onBaseChanged,
    required this.retentions,
    required this.onRetentionsChanged,
    required this.sourceValues,
    required this.ivaValues,
    required this.profValues,
    this.ivaRate = 0.12,
    super.key,
  });

  final TextEditingController ivaBase;
  final TextEditingController zeroBase;
  final VoidCallback onBaseChanged;
  final List<RetentionEntry> retentions;
  final ValueChanged<List<RetentionEntry>> onRetentionsChanged;
  final List<String> sourceValues;
  final List<String> ivaValues;
  final List<String> profValues;
  final double ivaRate;

  List<String> _valuesForType(String type) {
    switch (type) {
      case 'source': return sourceValues;
      case 'iva': return ivaValues;
      case 'professional_service': return profValues;
      default: return [];
    }
  }

  double _rateValue(String rateName) {
    if (rateName == 'Otro' || rateName.isEmpty) return 0;
    return (double.tryParse(rateName.replaceAll('%', '')) ?? 0) / 100;
  }

  double _autoBase(String type, double ivaBaseVal) {
    switch (type) {
      case 'source': return ivaBaseVal;
      case 'iva': return ivaBaseVal * ivaRate;
      case 'professional_service': return ivaBaseVal;
      default: return 0;
    }
  }

  double _entryBase(RetentionEntry r, double ivaBaseVal) {
    return r.customBase ?? _autoBase(r.type, ivaBaseVal);
  }

  double totalByType(String type) {
    final ivaBaseVal = double.tryParse(ivaBase.text.replaceAll(',', '.')) ?? 0;
    double total = 0;
    for (final r in retentions) {
      if (r.type == type) {
        total += _entryBase(r, ivaBaseVal) * _rateValue(r.rateName);
      }
    }
    return total;
  }

  double get totalRetentions =>
      totalByType('source') + totalByType('iva') + totalByType('professional_service');

  String _typeLabel(String type) {
    switch (type) {
      case 'source': return 'Fuente (Renta)';
      case 'iva': return 'IVA';
      case 'professional_service': return 'Serv. Prof.';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'source': return Icons.monetization_on_outlined;
      case 'iva': return Icons.receipt_long_outlined;
      case 'professional_service': return Icons.work_outline;
      default: return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ivaBaseVal = double.tryParse(ivaBase.text.replaceAll(',', '.')) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Datos tributarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ivaBase,
                  onChanged: (_) => onBaseChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Base IVA'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: zeroBase,
                  onChanged: (_) => onBaseChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Base Tarifa 0%'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (ivaRate != 0.12)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Cálculo con IVA ${(ivaRate * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),

          // ── Lista de retenciones ──
          if (retentions.isNotEmpty) ...[
            ...List.generate(retentions.length, (i) {
              final r = retentions[i];
              final base = _entryBase(r, ivaBaseVal);
              final rate = _rateValue(r.rateName);
              final value = base * rate;
              final typeValues = _valuesForType(r.type);
              final baseCon = TextEditingController(text: r.customBaseText ?? '');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_typeIcon(r.type), size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text('Retención ${_typeLabel(r.type)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        SizedBox(
                          width: 28, height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              final list = [...retentions];
                              list.removeAt(i);
                              onRetentionsChanged(list);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: r.type,
                            items: const [
                              DropdownMenuItem(value: 'source', child: Text('Fuente (Renta)')),
                              DropdownMenuItem(value: 'iva', child: Text('IVA')),
                              DropdownMenuItem(value: 'professional_service', child: Text('Serv. Prof.')),
                            ],
                            onChanged: (v) {
                              final list = [...retentions];
                              list[i] = RetentionEntry(type: v ?? 'source');
                              onRetentionsChanged(list);
                            },
                            decoration: const InputDecoration(labelText: 'Tipo', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: baseCon,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Base',
                              hintText: 'auto: ${currency(_autoBase(r.type, ivaBaseVal))}',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final list = [...retentions];
                              list[i] = RetentionEntry(type: r.type, rateName: r.rateName, customBaseText: v);
                              onRetentionsChanged(list);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HorizontalChoiceChips(
                      values: typeValues,
                      selected: r.rateName,
                      onSelected: (v) {
                        final list = [...retentions];
                        list[i] = RetentionEntry(type: r.type, rateName: v, customBaseText: r.customBaseText);
                        onRetentionsChanged(list);
                      },
                    ),
                    if (value > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Valor: ${currency(value)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                      ),
                  ],
                ),
              );
            }),
          ],

          // ── Botón agregar ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final list = [...retentions];
                list.add(RetentionEntry(type: 'source'));
                onRetentionsChanged(list);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar retención'),
            ),
          ),
          const SizedBox(height: 14),

          // ── Totales ──
          if (retentions.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            ...['source', 'iva', 'professional_service'].where((t) => totalByType(t) > 0).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(_typeIcon(t), size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('Ret. ${_typeLabel(t)}: ', style: Theme.of(context).textTheme.bodySmall),
                  Text(currency(totalByType(t)), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            )),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.summarize_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Total retenciones: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(currency(totalRetentions), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.red)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
