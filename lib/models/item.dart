import 'package:hive/hive.dart';

part 'item.g.dart'; // هذا الملف سيتم توليده بواسطة build_runner

@HiveType(typeId: 0) // رقم TypeId فريد لهذا الكلاس (تأكد من عدم تكراره)
class Item extends HiveObject {
  @HiveField(0)
  late String id; // معرف فريد للمنتج
  
  @HiveField(1)
  late String name; // اسم المنتج

  @HiveField(2)
  late double purchasePrice; // سعر الشراء

  @HiveField(3)
  late double sellingPrice; // سعر البيع

  @HiveField(4)
  late int stock; // الكمية المتوفرة في المخزون

  Item({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
  });
}

