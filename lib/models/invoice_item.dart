// lib/models/invoice_item.dart
import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 2)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  late String id; // ⭐⭐ تم إضافة هذا الحقل ⭐⭐

  @HiveField(1)
  late String itemId;

  @HiveField(2)
  late String itemName;

  @HiveField(3)
  late double quantity;

  @HiveField(4)
  late double price; // ⭐⭐ تم التأكد من late ⭐⭐

  InvoiceItem({
    required this.id, // ⭐⭐ تم إضافة هذا للكونستراكتور ⭐⭐
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });
}
