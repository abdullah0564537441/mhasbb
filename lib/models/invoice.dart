// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/models/invoice_type.dart';

part 'invoice.g.dart';

@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String invoiceNumber;

  @HiveField(2)
  late InvoiceType type;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late HiveList<InvoiceItem> items; // ⭐⭐ تم التعديل إلى HiveList ⭐⭐

  @HiveField(5)
  String? customerId;

  @HiveField(6)
  String? customerName;

  @HiveField(7)
  String? supplierId;

  @HiveField(8)
  String? supplierName;

  @HiveField(9)
  late PaymentMethod paymentMethod;

  @HiveField(10)
  String? originalInvoiceId;

  @HiveField(11)
  late double totalAmount;

  @HiveField(12) // ⭐⭐ تم إضافة هذا الحقل ⭐⭐
  String? notes;

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
    this.paymentMethod = PaymentMethod.cash,
    this.originalInvoiceId,
    required this.totalAmount,
    this.notes, // ⭐⭐ تم إضافة هذا للكونستراكتور ⭐⭐
  });
}
