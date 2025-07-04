import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart'; // تأكد من استيراد InvoiceItem

part 'invoice.g.dart';

@HiveType(typeId: 3) // ⭐ تأكد أن الـ typeId هذا فريد (مثلاً 3 للفواتير)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للفاتورة

  @HiveField(1)
  String invoiceNumber; // ⭐ أضف رقم الفاتورة
  
  @HiveField(2)
  String customerName; // ⭐ أضف اسم العميل
  
  @HiveField(3)
  DateTime invoiceDate; // تاريخ الفاتورة
  
  @HiveField(4)
  List<InvoiceItem> items; // قائمة الأصناف في هذه الفاتورة
  
  @HiveField(5)
  double totalAmount; // إجمالي مبلغ الفاتورة

  Invoice({
    required this.id,
    required this.invoiceNumber, // ⭐ أضفها إلى المنشئ
    required this.customerName,  // ⭐ أضفها إلى المنشئ
    required this.invoiceDate,
    required this.items,
    required this.totalAmount,
  });
}
