import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 2) // ⭐ تأكد أن الـ typeId هذا فريد (مثلاً 2 لأصناف الفاتورة)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  final String itemId; // ID الصنف من المخزون

  @HiveField(1)
  String itemName; // اسم الصنف وقت البيع
  
  @HiveField(2)
  double quantity; // ⭐ تأكد أنه من نوع double (يمكن أن يكون 1.0، 2.5، إلخ)
  
  @HiveField(3)
  String unit; // ⭐ أضف الوحدة

  @HiveField(4)
  double sellingPrice; // سعر البيع الفعلي وقت البيع

  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit, // ⭐ أضفها إلى المنشئ
    required this.sellingPrice,
  });
}
