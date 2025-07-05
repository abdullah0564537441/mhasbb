// lib/models/customer.dart
import 'package:hive/hive.dart';

part 'customer.g.dart';

// ⭐⭐ هام: تأكد أن typeId هذا فريد ولم تستخدمه لأي كلاس أو enum آخر
// (على سبيل المثال، 6، طالما أنه ليس 0, 1, 2, 3, 4, 5، إلخ. وتأكد من أنه لا يتعارض مع أي شيء آخر لديك).
@HiveType(typeId: 6) // تأكد من أن هذا الرقم فريد!
class Customer extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للعميل (أصبح final)

  @HiveField(1)
  String name; // اسم العميل (أصبح String عادي)

  @HiveField(2)
  String? phoneNumber; // ⭐⭐ تأكد من أن الاسم هو 'phoneNumber' وليس 'phone'

  @HiveField(3)
  String? address; // عنوان العميل

  @HiveField(4) // ⭐⭐ حقل جديد: البريد الإلكتروني
  String? email;

  @HiveField(5) // ⭐⭐ حقل جديد: ملاحظات
  String? notes;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber, // ⭐⭐ تأكد من أن الاسم هنا هو 'phoneNumber' وليس 'phone'
    this.address,
    this.email,
    this.notes,
  });
}
