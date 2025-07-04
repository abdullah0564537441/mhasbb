import 'package:hive/hive.dart';
import 'package:mhasbb/models/invoice_item.dart'; // تأكد من المسار الصحيح واسم المشروع (mhasbb)
import 'package:mhasbb/models/customer.dart'; // تأكد من المسار الصحيح واسم المشروع (mhasbb)

part 'invoice.g.dart'; // هذا الملف سيتم توليده بواسطة build_runner

@HiveType(typeId: 3) // رقم TypeId فريد لهذا الكلاس (تأكد من عدم تكراره)
class Invoice extends HiveObject {
  @HiveField(0)
  late String id; // معرف فريد للفاتورة (عادةً ما يتم إنشاؤه تلقائيًا)
  
  @HiveField(1)
  late DateTime invoiceDate; // تاريخ الفاتورة

  @HiveField(2)
  late Customer customer; // العميل المرتبط بهذه الفاتورة

  @HiveField(3)
  late List<InvoiceItem> items; // قائمة الأصناف في الفاتورة

  // حساب إجمالي الفاتورة من مجموع totals لكل عنصر
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.total);

  Invoice({
    required this.id,
    required this.invoiceDate,
    required this.customer,
    required this.items,
  });
}

