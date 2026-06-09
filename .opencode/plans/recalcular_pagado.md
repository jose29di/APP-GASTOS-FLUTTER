# Plan: Integridad referencial — Recálculo de pagos al borrar/editar transacciones

## 1. `lib/core/database/app_database.dart`

Añadir después del método `transaction`:

```dart
  static Future<void> recalcularPagado(dynamic db, int transactionId) async {
    final advances = await db.query('transactions',
      where: 'related_transaction_id = ? AND type = ?',
      whereArgs: [transactionId, 'advance']);
    final totalPaid = advances.fold<double>(0, (s, a) => s + (a['paid_amount'] as num).toDouble());
    final orig = await db.query('transactions',
      where: 'id = ?', whereArgs: [transactionId]);
    if (orig.isEmpty) return;
    final origAmount = (orig.first['amount'] as num).toDouble();
    await db.update('transactions',
      {'is_paid': totalPaid >= origAmount ? 1 : 0},
      where: 'id = ?', whereArgs: [transactionId]);
  }
```

## 2. `lib/features/transactions/transaction_form_screen.dart`

### 2a. Ocultar "Pagado" + "Método de pago" en anticipos

Envolver desde `// ── Pagada (con o sin factura) ──` hasta el cierre del `if (_isPaid)` con:

```dart
              // ── Pagada (solo income/expense) ──
              if (_type != 'advance') ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  ...
                ),
                if (_isPaid) ...[
                  ... (método de pago, monto pagado, resumen)
                ],
              ],
```

Buscar la línea exacta `// ── Pagada (con o sin factura) ──` y reemplazar desde ahí hasta justo antes del footer neto.

### 2b. Recálculo al guardar

Dentro del `transaction` en `_save()`, después del bloque que maneja anticipos (líneas ~556-570), añadir:

```dart
        // Recalcular estado de pago de la factura vinculada
        if (_type == 'advance' && _payAgainstId != null) {
          await AppDatabase.recalcularPagado(txn, _payAgainstId!);
        }
        // Si editamos un income/expense, recalcular por si cambió el monto
        if (_editId != null && _type != 'advance') {
          await AppDatabase.recalcularPagado(txn, _editId!);
        }
```

Nota: el bloque existente (líneas 556-570) ya actualiza `is_paid` si el total pagado >= amount, pero `recalcularPagado` es más robusto porque también marca `is_paid = 0` si ya no se cubre. Se puede reemplazar el bloque existente por la llamada a `recalcularPagado`.

## 3. `lib/features/history/smart_history_screen.dart` (o donde esté `_confirmDelete`)

### 3a. Prevenir borrado si tiene anticipos vinculados

Dentro de `await AppDatabase.transaction`, ANTES de borrar:

```dart
          // Verificar si tiene anticipos vinculados
          if (tx['type'] != 'advance') {
            final linked = await txn.query('transactions',
              where: 'related_transaction_id = ?',
              whereArgs: [id]);
            if (linked.isNotEmpty) {
              throw Exception(
                'No se puede eliminar: tiene ${linked.length} anticipo(s) vinculado(s).'
                ' Elimina primero los anticipos.'
              );
            }
          }
```

### 3b. Recalcular factura vinculada al borrar anticipo

Después de borrar el registro (después de `txn.delete('transactions', ...)`):

```dart
          // Si es anticipo, recalcular estado de pago de la factura
          if (tx['type'] == 'advance' && tx['related_transaction_id'] != null) {
            await AppDatabase.recalcularPagado(txn, tx['related_transaction_id']);
          }
```

### 3c. Capturar error y mostrarlo al usuario

Envolver el catch en `_confirmDelete` para mostrar el mensaje de error:

```dart
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error al borrar'),
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
              ],
            ),
          );
        }
      }
```
