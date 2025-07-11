// lib/models/return_invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart'; // استيراد موديل أصناف الفاتورة/المرتجع
import 'package:mhasbb/models/invoice.dart'; // لاستخدام InvoiceType إذا أردت التمييز بين مرتجع بيع وشراء

part 'return_invoice.g.dart';

@HiveType(typeId: 10) // ⭐⭐ هام: تأكد أن هذا الـ typeId فريد وغير مستخدم في أي موديل Hive آخر
class ReturnInvoice extends HiveObject {
  @HiveField(0)
  String id; // معرف فريد للمرتجع (UUID)

  @HiveField(1)
  String returnNumber; // رقم فاتورة المرتجع (يمكن أن يكون مختلفًا عن رقم الفاتورة الأصلية)

  @HiveField(2)
  DateTime date; // تاريخ المرتجع

  @HiveField(3)
  String? originalInvoiceNumber; // رقم الفاتورة الأصلية التي تم إرجاعها منها (اختياري)

  @HiveField(4)
  InvoiceType? originalInvoiceType; // نوع الفاتورة الأصلية (بيع/شراء) للمرتجع (اختياري)
                                     // هذا يساعد في التمييز بين مرتجعات البيع ومرتجعات الشراء

  @HiveField(5)
  String? customerName; // اسم العميل إذا كان مرتجع مبيعات
  @HiveField(6)
  String? supplierName; // اسم المورد إذا كان مرتجع مشتريات

  @HiveField(7)
  HiveList<InvoiceItem> items; // قائمة الأصناف المرتجعة وكمياتها وأسعارها

  @HiveField(8)
  double totalAmount; // إجمالي قيمة المرتجع

  @HiveField(9)
  String? notes; // أي ملاحظات إضافية حول المرتجع

  ReturnInvoice({
    required this.id,
    required this.returnNumber,
    required this.date,
    this.originalInvoiceNumber,
    this.originalInvoiceType,
    this.customerName,
    this.supplierName,
    required this.items,
    required this.totalAmount,
    this.notes,
  });
}
