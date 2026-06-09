import 'package:flutter/material.dart';

class TransactionRecord {
  TransactionRecord({
    required this.vendor,
    required this.project,
    required this.category,
    required this.note,
    required this.amount,
    required this.icon,
    required this.hasInvoice,
    required this.isIncome,
    this.paymentMethod = 'Efectivo',
    this.ivaBase = 0,
    this.zeroBase = 0,
    this.sourceRetention = '',
    this.ivaRetention = '',
    this.sourceRetentionValue = 0,
    this.ivaRetentionValue = 0,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String vendor;
  final String project;
  final String category;
  final String note;
  final double amount;
  final IconData icon;
  final bool hasInvoice;
  final bool isIncome;
  final String paymentMethod;
  final double ivaBase;
  final double zeroBase;
  final String sourceRetention;
  final String ivaRetention;
  final double sourceRetentionValue;
  final double ivaRetentionValue;
  final DateTime date;

  double get netCash => amount - sourceRetentionValue - ivaRetentionValue;
}
