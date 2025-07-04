import 'package:hive/hive.dart';

part 'customer.g.dart'; // هذا الملف سيتم توليده بواسطة build_runner

@HiveType(typeId: 1) // رقم TypeId فريد لهذا الكلاس (تأكد من عدم تكراره)
class Customer extends HiveObject {
  @HiveField(0)
  late String id; // معرف فريد للعميل
  
  @HiveField(1)
  late String name; // اسم العميل

  @HiveField(2)
  late String? phone; // رقم هاتف العميل (يمكن أن يكون فارغًا)

  @HiveField(3)
  late String? address; // عنوان العميل (يمكن أن يكون فارغًا)

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });
}

