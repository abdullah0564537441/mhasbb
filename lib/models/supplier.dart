// lib/models/supplier.dart
import 'package:hive/hive.dart';

part 'supplier.g.dart';

@HiveType(typeId: 4) // ⭐ تأكد أن الـ typeId هذا فريد (مثلاً 4 للموردين)
class Supplier extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للمورد

  @HiveField(1)
  String name; // اسم المورد

  @HiveField(2)
  String? phoneNumber; // رقم هاتف المورد (اختياري)

  @HiveField(3)
  String? address; // عنوان المورد (اختياري)

  Supplier({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.address,
  });
}
