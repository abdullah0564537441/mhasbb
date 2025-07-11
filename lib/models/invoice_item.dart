// lib/models/invoice_item.dart
import 'package:hive/hive.dart';

part 'invoice_item.g.dart';

@HiveType(typeId: 2)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String itemId;

  @HiveField(2)
  late String itemName;

  @HiveField(3)
  late double quantity;

  @HiveField(4)
  late double price;

  @HiveField(5) // ⭐⭐ تم إضافة هذا الحقل لوحدة الصنف في فاتورة ⭐⭐
  late String unit;

  InvoiceItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.unit, // ⭐⭐ تم إضافة هذا للكونستراكتور ⭐⭐
  });
}
