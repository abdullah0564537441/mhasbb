// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/invoice_type.dart'; // ⭐⭐ أضف هذا السطر

part 'invoice.g.dart';

// تم إزالة تعريف enum InvoiceType من هنا

@HiveType(typeId: 3) // تأكد أن الـ typeId هذا فريد
class Invoice extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  InvoiceType type;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  List<InvoiceItem> items;

  @HiveField(5)
  String? customerId;
  @HiveField(6)
  String? customerName;

  @HiveField(7)
  String? supplierId;
  @HiveField(8)
  String? supplierName;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.date,
    required this.items,
    this.customerId,
    this.customerName,
    this.supplierId,
    this.supplierName,
  });
}
