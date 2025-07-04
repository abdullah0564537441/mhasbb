import 'package:hive/hive.dart';

part 'invoice_item.g.dart'; // هذا الملف سيتم توليده بواسطة build_runner

@HiveType(typeId: 2) // رقم TypeId فريد لهذا الكلاس (تأكد من عدم تكراره)
class InvoiceItem extends HiveObject {
  @HiveField(0)
  late String itemId; // معرف الصنف (المنتج)
  
  @HiveField(1)
  late String itemName; // اسم الصنف (للسهولة في العرض)

  @HiveField(2)
  late double sellingPrice; // السعر الذي تم بيع الصنف به في هذه الفاتورة

  @HiveField(3)
  late int quantity; // الكمية المباعة من هذا الصنف

  // يمكن إضافة Total لهذا العنصر الواحد (السعر * الكمية)
  double get total => sellingPrice * quantity;

  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.sellingPrice,
    required this.quantity,
  });
}

