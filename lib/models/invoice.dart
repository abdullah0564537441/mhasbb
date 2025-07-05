// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/invoice_type.dart';

part 'invoice.g.dart';

@HiveType(typeId: 3) // تم التأكد من أنه فريد
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
