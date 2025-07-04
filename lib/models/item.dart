import 'package:hive/hive.dart';

part 'item.g.dart'; // تأكد أن هذا السطر موجود لتوليد الكود الخاص بـ Hive

@HiveType(typeId: 0) // ⭐ تأكد أن الـ typeId هذا فريد لكل موديل (0 للأصناف)
class Item extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للصنف (مثلاً UUID)

  @HiveField(1)
  String name; // اسم الصنف

  @HiveField(2)
  double quantity; // ⭐ أضف الكمية

  @HiveField(3)
  String unit; // ⭐ أضف الوحدة (مثال: قطعة، كجم)

  @HiveField(4)
  double purchasePrice; // ⭐ أضف سعر الشراء

  @HiveField(5)
  double sellingPrice; // ⭐ أضف سعر البيع

  Item({
    required this.id,
    required this.name,
    required this.quantity, // ⭐ أضفها إلى المنشئ
    required this.unit,     // ⭐ أضفها إلى المنشئ
    required this.purchasePrice, // ⭐ أضفها إلى المنشئ
    required this.sellingPrice,  // ⭐ أضفها إلى المنشئ
  });
}
