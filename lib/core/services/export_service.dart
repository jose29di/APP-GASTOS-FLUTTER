import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class ExportService {
  ExportService._();

  static Future<String> exportToXls({int? year, int? month}) async {
    final excel = Excel.createExcel();

    await _addTransactionsSheet(excel);
    await _addContactsSheet(excel);
    await _addMonthlySummarySheet(excel, year, month);

    excel.delete('Sheet1');

    final dir = await getApplicationDocumentsDirectory();
    final suffix = year != null ? '_${year}_${month?.toString().padLeft(2, '0') ?? 'XX'}' : '';
    final path = '${dir.path}/export$suffix.xlsx';

    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al generar el archivo Excel');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  static Future<void> shareFile(String path) async {
    final file = XFile(path);
    await SharePlus.instance.share(
      ShareParams(files: [file], text: 'Exportación de datos'),
    );
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<CellValue?> values) {
    for (var col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.value = values[col];
    }
  }

  static Future<void> _addTransactionsSheet(Excel excel) async {
    final sheet = excel['Transacciones'];
    _writeRow(sheet, 0, [
      TextCellValue('ID'),
      TextCellValue('Tipo'),
      TextCellValue('Monto'),
      TextCellValue('Categoría'),
      TextCellValue('Proyecto'),
      TextCellValue('Tributa'),
      TextCellValue('Ámbito'),
      TextCellValue('Método Pago'),
      TextCellValue('Con Factura'),
      TextCellValue('N° Factura'),
      TextCellValue('Base IVA'),
      TextCellValue('Base 0%'),
      TextCellValue('Es Crédito'),
      TextCellValue('Vencimiento'),
      TextCellValue('Pagado'),
      TextCellValue('Monto Pagado'),
      TextCellValue('Fecha Pago'),
      TextCellValue('Proveedor'),
      TextCellValue('Notas'),
      TextCellValue('Fecha'),
      TextCellValue('Contacto'),
      TextCellValue('Identificación'),
      TextCellValue('Tipo Contacto'),
      TextCellValue('Teléfono'),
      TextCellValue('Email'),
    ]);

    final contacts = await AppDatabase.query('contacts');
    final contactMap = <int, Map<String, dynamic>>{};
    for (final c in contacts) {
      contactMap[c['id'] as int] = c;
    }

    final txns = await AppDatabase.query('transactions', orderBy: 'date DESC');
    var rowIndex = 1;
    for (final t in txns) {
      final scope = t['scope'] as String? ?? 'business';
      final contactId = t['contact_id'] as int?;
      final c = contactId != null ? contactMap[contactId] : null;
      _writeRow(sheet, rowIndex++, [
        IntCellValue(t['id'] as int),
        TextCellValue(t['type'] as String? ?? ''),
        DoubleCellValue((t['amount'] as num?)?.toDouble() ?? 0),
        TextCellValue(t['category'] as String? ?? ''),
        TextCellValue(t['project'] as String? ?? ''),
        TextCellValue(scope == 'business' ? 'Sí' : 'No'),
        TextCellValue(scope == 'business' ? 'Trabajo' : 'Personal'),
        TextCellValue(t['payment_method'] as String? ?? ''),
        TextCellValue((t['has_invoice'] as int?) == 1 ? 'Sí' : 'No'),
        TextCellValue(t['factura_number'] as String? ?? ''),
        DoubleCellValue((t['iva_base'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((t['zero_base'] as num?)?.toDouble() ?? 0),
        TextCellValue((t['is_credit'] as int?) == 1 ? 'Sí' : 'No'),
        TextCellValue(t['due_date'] as String? ?? ''),
        TextCellValue((t['is_paid'] as int?) == 1 ? 'Sí' : 'No'),
        DoubleCellValue((t['paid_amount'] as num?)?.toDouble() ?? 0),
        TextCellValue(t['paid_date'] as String? ?? ''),
        TextCellValue(t['vendor'] as String? ?? ''),
        TextCellValue(t['notes'] as String? ?? ''),
        TextCellValue(t['date'] as String? ?? ''),
        TextCellValue(c != null ? c['name'] as String? ?? '' : ''),
        TextCellValue(c != null ? c['identification'] as String? ?? '' : ''),
        TextCellValue(c != null ? c['category'] as String? ?? '' : ''),
        TextCellValue(c != null ? c['phone'] as String? ?? '' : ''),
        TextCellValue(c != null ? c['email'] as String? ?? '' : ''),
      ]);
    }
  }

  static Future<void> _addContactsSheet(Excel excel) async {
    final sheet = excel['Contactos'];
    _writeRow(sheet, 0, [
      TextCellValue('ID'),
      TextCellValue('Nombre'),
      TextCellValue('Identificación'),
      TextCellValue('Categoría'),
      TextCellValue('Teléfono'),
      TextCellValue('Email'),
      TextCellValue('Notas'),
    ]);

    final contacts = await AppDatabase.query('contacts', orderBy: 'name ASC');
    var rowIndex = 1;
    for (final c in contacts) {
      _writeRow(sheet, rowIndex++, [
        IntCellValue(c['id'] as int),
        TextCellValue(c['name'] as String? ?? ''),
        TextCellValue(c['identification'] as String? ?? ''),
        TextCellValue(c['category'] as String? ?? ''),
        TextCellValue(c['phone'] as String? ?? ''),
        TextCellValue(c['email'] as String? ?? ''),
        TextCellValue(c['notes'] as String? ?? ''),
      ]);
    }
  }

  static Future<void> _addMonthlySummarySheet(Excel excel, int? year, int? month) async {
    final sheet = excel['Resumen Mensual'];

    String dateFilter;
    List<dynamic> dateArgs;
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final firstDay = DateTime(y, m, 1);
    final lastDay = DateTime(y, m + 1, 1);
    dateFilter = 'date >= ? AND date < ?';
    dateArgs = [firstDay.toIso8601String(), lastDay.toIso8601String()];

    final ingreso = await AppDatabase.query('transactions',
        where: "type = 'income' AND $dateFilter", whereArgs: dateArgs);
    final egreso = await AppDatabase.query('transactions',
        where: "type = 'expense' AND $dateFilter", whereArgs: dateArgs);
    final anticipos = await AppDatabase.query('transactions',
        where: "type = 'advance' AND $dateFilter", whereArgs: dateArgs);

    double sum(List<Map<String, dynamic>> list, String field) =>
        list.fold<double>(0.0, (s, e) => s + ((e[field] as num?)?.toDouble() ?? 0.0));

    final totalIngresos = sum(ingreso, 'amount');
    final totalEgresos = sum(egreso, 'amount');
    final totalAnticipos = sum(anticipos, 'amount');

    final ivaBase = sum(ingreso, 'iva_base') + sum(egreso, 'iva_base');
    final zeroBase = sum(ingreso, 'zero_base') + sum(egreso, 'zero_base');

    _writeRow(sheet, 0, [TextCellValue('Concepto'), TextCellValue('Valor')]);
    _writeRow(sheet, 1, [TextCellValue('Mes'), TextCellValue('$m/$y')]);
    _writeRow(sheet, 2, [TextCellValue('Total Ingresos'), DoubleCellValue(totalIngresos)]);
    _writeRow(sheet, 3, [TextCellValue('Total Egresos'), DoubleCellValue(totalEgresos)]);
    _writeRow(sheet, 4, [TextCellValue('Total Anticipos'), DoubleCellValue(totalAnticipos)]);
    _writeRow(sheet, 5, [TextCellValue('Base IVA'), DoubleCellValue(ivaBase)]);
    _writeRow(sheet, 6, [TextCellValue('Base 0%'), DoubleCellValue(zeroBase)]);
    _writeRow(sheet, 7, [TextCellValue('Neto Caja Real'), DoubleCellValue(totalIngresos - totalEgresos - totalAnticipos)]);
    _writeRow(sheet, 8, [TextCellValue('Neto Tributario'), DoubleCellValue(totalIngresos - totalEgresos)]);
    _writeRow(sheet, 9, [TextCellValue('')]);
    _writeRow(sheet, 10, [TextCellValue('Retenciones'), TextCellValue('Valor')]);

    final retenciones = await AppDatabase.query('retentions');
    _writeRow(sheet, 11, [TextCellValue('Fuente'), DoubleCellValue(
        retenciones.where((r) => r['type'] == 'source').fold<double>(0.0, (s, r) => s + ((r['value'] as num?)?.toDouble() ?? 0)))]);
    _writeRow(sheet, 12, [TextCellValue('IVA'), DoubleCellValue(
        retenciones.where((r) => r['type'] == 'iva').fold<double>(0.0, (s, r) => s + ((r['value'] as num?)?.toDouble() ?? 0)))]);
    _writeRow(sheet, 13, [TextCellValue('Serv. Prof.'), DoubleCellValue(
        retenciones.where((r) => r['type'] == 'professional_service').fold<double>(0.0, (s, r) => s + ((r['value'] as num?)?.toDouble() ?? 0)))]);
  }
}
