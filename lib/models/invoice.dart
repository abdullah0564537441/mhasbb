// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/payment_method.dart'; // تأكد من استيرادها
import 'package:mhasbb/models/invoice_type.dart'; // ⭐⭐ هذا الاستيراد مهم الآن ⭐⭐

part 'invoice.g.dart';

@HiveType(typeId: 3) // تأكد أن هذا الـ typeId فريد وغير مستخدم لنماذج أخرى
class Invoice extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String invoiceNumber;

  @HiveField(2)
  late InvoiceType type; // نوع الفاتورة (بيع، شراء، مرتجع بيع، مرتجع شراء)

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late List<InvoiceItem> items;

  @HiveField(5)
  String? customerId;

  @HiveField(6)
  String? customerName;

  @HiveField(7)
  String? supplierId;

  @HiveField(8)
  String? supplierName;

  @HiveField(9) // ⭐ حقل طريقة الدفع (نقد، آجل، تحويل بنكي)
  late PaymentMethod paymentMethod;

  @HiveField(10) // ⭐ حقل جديد لربط المرتجع بالفاتورة الأصلية
  String? originalInvoiceId;

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
    this.paymentMethod = PaymentMethod.cash, // قيمة افتراضية لطريقة الدفع
    this.originalInvoiceId, // تهيئة الحقل الجديد
  });
}

// ⭐⭐ تم حذف تعريف enum InvoiceType من هنا ⭐⭐
// يجب أن يكون تعريف enum InvoiceType في ملف lib/models/invoice_type.dart فقط.
