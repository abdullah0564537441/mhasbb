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
  late double purchasePrice;

  @HiveField(4)
  late double salePrice;

  @HiveField(5)
  late double currentStock; // ⭐⭐ تم تغيير الاسم إلى currentStock إذا كان قد تم تغييره سابقا ⭐⭐

  Item({
    required this.id,
    required this.name,
    required this.unit,
    required this.purchasePrice,
    required this.salePrice,
    this.currentStock = 0.0, // ⭐⭐ تم تغيير الاسم هنا ⭐⭐
  });
}
