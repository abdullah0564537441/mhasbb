// lib/models/item.dart
import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String unit;

  @HiveField(3)
  late double purchasePrice; // ⭐⭐ تم إضافة هذا الحقل ⭐⭐

  @HiveField(4)
  late double salePrice;     // ⭐⭐ تم إضافة هذا الحقل ⭐⭐

  @HiveField(5)
  late double currentStock;

  Item({
    required this.id,
    required this.name,
    required this.unit,
    required this.purchasePrice, // ⭐⭐ تم إضافة هذا للكونستراكتور ⭐⭐
    required this.salePrice,     // ⭐⭐ تم إضافة هذا للكونستراكتور ⭐⭐
    this.currentStock = 0.0,
  });
}
