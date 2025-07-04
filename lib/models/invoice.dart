// lib/models/invoice.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/customer.dart'; // سيبقى هذا الموديل إذا كنا ما زلنا نستخدمه
import 'package:mhasbb/models/supplier.dart'; // ⭐ استيراد موديل المورد

part 'invoice.g.dart';

// تعريف نوع الفاتورة
enum InvoiceType {
  @HiveField(0)
  sale, // فاتورة بيع
  @HiveField(1)
  purchase, // فاتورة شراء
}

@HiveType(typeId: 3) // تأكد أن الـ typeId هذا فريد (مثلاً 3 للفواتير)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للفاتورة

  @HiveField(1)
  String invoiceNumber; // رقم الفاتورة
  
  @HiveField(2)
  String? customerName; // ⭐ اسم العميل (يمكن أن يكون null لفواتير الشراء)
  
  @HiveField(3)
  String? supplierName; // ⭐ اسم المورد (يمكن أن يكون null لفواتير البيع)

  @HiveField(4)
  DateTime invoiceDate; // تاريخ الفاتورة
  
  @HiveField(5)
  List<InvoiceItem> items; // قائمة الأصناف في هذه الفاتورة
  
  @HiveField(6)
  double totalAmount; // إجمالي مبلغ الفاتورة

  @HiveField(7) // ⭐ حقل جديد لتمييز نوع الفاتورة
  InvoiceType type; 

  Invoice({
    required this.id,
    required this.invoiceNumber,
    this.customerName, // يمكن أن يكون null
    this.supplierName, // يمكن أن يكون null
    required this.invoiceDate,
    required this.items,
    required this.totalAmount,
    this.type = InvoiceType.sale, // ⭐ القيمة الافتراضية هي بيع
  });
}
