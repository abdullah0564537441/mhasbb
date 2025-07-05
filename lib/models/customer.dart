// lib/models/customer.dart
import 'package:hive/hive.dart';

part 'customer.g.dart';

// ⭐⭐ هام: تأكد أن typeId هذا فريد ولم تستخدمه لأي كلاس أو enum آخر
// استخدم رقمًا لم يتم استخدامه مسبقًا
@HiveType(typeId: 1) // تأكد من أن هذا الرقم فريد!
class Customer extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للعميل (أصبح final)

  @HiveField(1)
  String name; // اسم العميل (أصبح String عادي)

  @HiveField(2)
  String? phoneNumber; // ⭐⭐ تم تغيير الاسم من 'phone' إلى 'phoneNumber' ليتوافق مع الشاشات

  @HiveField(3)
  String? address; // عنوان العميل

  @HiveField(4) // ⭐⭐ حقل جديد: البريد الإلكتروني
  String? email;

  @HiveField(5) // ⭐⭐ حقل جديد: ملاحظات
  String? notes;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber, // ⭐⭐ تم تغيير الاسم هنا أيضًا
    this.address,
    this.email, // ⭐⭐ أضف هذا في المُنشئ
    this.notes, // ⭐⭐ أضف هذا في المُنشئ
  });
}
