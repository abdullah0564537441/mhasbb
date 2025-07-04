// lib/models/supplier.dart
import 'package:hive/hive.dart';

part 'supplier.g.dart';

@HiveType(typeId: 4) // ⭐ تأكد أن الـ typeId هذا فريد (4 هو جيد للموردين)
class Supplier extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للمورد، يفضل أن يكون ثابتًا بعد الإنشاء

  @HiveField(1)
  String name; // اسم المورد (قابل للتعديل)

  @HiveField(2)
  String? phoneNumber; // رقم هاتف المورد (اختياري وقابل للتعديل)

  @HiveField(3)
  String? address; // عنوان المورد (اختياري وقابل للتعديل)

  @HiveField(4) // ⭐ حقل جديد: البريد الإلكتروني للمورد
  String? email; // البريد الإلكتروني للمورد (اختياري وقابل للتعديل)

  @HiveField(5) // ⭐ حقل جديد: ملاحظات إضافية عن المورد
  String? notes; // ملاحظات إضافية عن المورد (اختياري وقابل للتعديل)

  Supplier({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.email, // ⭐ أضف هذا في المُنشئ
    this.notes, // ⭐ أضف هذا في المُنشئ
  });
}
