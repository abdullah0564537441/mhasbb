// lib/models/invoice_item.dart
import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 2) // تأكد أن الـ typeId هذا فريد (مثلاً 2 لأصناف الفاتورة)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  final String itemId; // ID الصنف من المخزون (final لأنه معرف لا يتغير بعد الإنشاء)

  @HiveField(1)
  String itemName; // اسم الصنف وقت البيع
  
  @HiveField(2)
  double quantity; // الكمية (غير final للسماح بالتعديل)
  
  @HiveField(3)
  String unit; // الوحدة (غير final للسماح بالتعديل)

  @HiveField(4)
  double sellingPrice; // سعر البيع الفعلي وقت البيع (غير final للسماح بالتعديل)

  @HiveField(5) // ⭐ جديد: إضافة حقل لسعر الشراء
  double purchasePrice; // سعر الشراء الفعلي وقت الشراء (غير final للسماح بالتعديل)


  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.sellingPrice,
    required this.purchasePrice, // ⭐ جديد: يجب أن يكون مطلوباً في الباني
  });
}
