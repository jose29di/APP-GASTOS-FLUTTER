import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/domain/models/transaction_record.dart';

class DemoFinanceRepository {
  final List<TransactionRecord> _transactions = [
    TransactionRecord(
      vendor: 'Ferretería Central',
      project: 'Proyecto Cliente X',
      category: 'Materia Prima',
      note: 'Cemento, varilla y aditivos para losa. Retenciones calculadas sobre base IVA.',
      amount: 1198.26,
      icon: Icons.precision_manufacturing_outlined,
      hasInvoice: true,
      isIncome: false,
      paymentMethod: 'Tarjeta',
      ivaBase: 900,
      zeroBase: 298.26,
      sourceRetention: '1.75%',
      ivaRetention: '30%',
      sourceRetentionValue: 900 * 0.0175,
      ivaRetentionValue: 900 * 0.12 * 0.30,
    ),
    TransactionRecord(
      vendor: 'Cliente María Torres',
      project: 'Remodelación Taller',
      category: 'Ingreso',
      note: 'Abono por avance de obra recibido por transferencia bancaria.',
      amount: 3200,
      icon: Icons.south_west,
      hasInvoice: true,
      isIncome: true,
      paymentMethod: 'Transferencia',
    ),
    TransactionRecord(
      vendor: 'Maestro Juan',
      project: 'Proyecto Cliente X',
      category: 'Mano de Obra',
      note: 'Jornal de tres trabajadores, pago en efectivo sin comprobante formal.',
      amount: 260,
      icon: Icons.engineering_outlined,
      hasInvoice: false,
      isIncome: false,
      paymentMethod: 'Efectivo',
    ),
    TransactionRecord(
      vendor: 'Supermercado Ideal',
      project: 'Personal',
      category: 'Personal',
      note: 'Alimentación deducible clasificada para control anual de límites.',
      amount: 84.75,
      icon: Icons.person_outline,
      hasInvoice: true,
      isIncome: false,
      paymentMethod: 'Tarjeta',
      ivaBase: 84.75,
      sourceRetention: '1%',
      ivaRetention: '10%',
      sourceRetentionValue: 84.75 * 0.01,
      ivaRetentionValue: 84.75 * 0.12 * 0.10,
    ),
  ];

  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  int get count => _transactions.length;

  void add(TransactionRecord record) {
    _transactions.insert(0, record);
  }

  void removeAt(int index) {
    if (index >= 0 && index < _transactions.length) {
      _transactions.removeAt(index);
    }
  }

  void clear() => _transactions.clear();
}
