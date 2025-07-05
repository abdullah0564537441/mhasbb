// lib/models/item.dart
import 'package:hive/hive.dart';

part 'item.g.dart'; // تأكد أن هذا السطر موجود لتوليد الكود الخاص بـ Hive

@HiveType(typeId: 0) // ⭐ تأكد أن الـ typeId هذا فريد لكل موديل (0 للأصناف)
class Item extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للصنف (مثلاً UUID)، يبقى final لأنه معرف ثابت

  @HiveField(1)
  String name; // اسم الصنف

  @HiveField(2)
  double quantity; // الكمية المتوفرة في المخزون (غير final للسماح بالتعديل)

  @HiveField(3)
  String unit; // وحدة القياس (مثال: قطعة، كجم) (غير final للسماح بالتعديل)

  @HiveField(4)
  double purchasePrice; // سعر الشراء (غير final للسماح بالتعديل)

  @HiveField(5)
  double sellingPrice; // سعر البيع (غير final للسماح بالتعديل)

  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
  });
}
