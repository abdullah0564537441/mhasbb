// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart'; // تأكد من استيراد InvoiceItem هنا

part 'invoice.g.dart';

enum InvoiceType {
  @HiveField(0)
  sale, // فاتورة مبيعات
  @HiveField(1)
  purchase, // فاتورة مشتريات
}

@HiveType(typeId: 3) // تأكد أن الـ typeId هذا فريد
class Invoice extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للفاتورة، يفضل أن يكون ثابتًا بعد الإنشاء

  @HiveField(1)
  String invoiceNumber; // رقم الفاتورة

  @HiveField(2)
  InvoiceType type; // نوع الفاتورة: بيع أو شراء

  @HiveField(3)
  DateTime date; // تم إزالة final لتصبح قابلة للتعديل

  @HiveField(4)
  List<InvoiceItem> items; // تم إزالة final لتصبح قابلة للتعديل

  @HiveField(5)
  String? customerId; // تم إزالة final لتصبح قابلة للتعديل
  @HiveField(6)
  String? customerName; // تم إزالة final لتصبح قابلة للتعديل

  @HiveField(7)
  String? supplierId; // تم إزالة final لتصبح قابلة للتعديل
  @HiveField(8)
  String? supplierName; // تم إزالة final لتصبح قابلة للتعديل

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
