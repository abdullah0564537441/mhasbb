// lib/models/customer.dart
import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 6) // تم التأكد من أنه فريد (6 هو رقم جيد)
class Customer extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للعميل (أصبح final)

  @HiveField(1)
  String name; // اسم العميل (أصبح String عادي)

  @HiveField(2)
  String? phoneNumber;

  @HiveField(3)
  String? address; // عنوان العميل

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? notes;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.email,
    this.notes,
  });
}
