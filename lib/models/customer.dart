// lib/models/customer.dart
import 'package:hive/hive.dart';

part 'customer.g.dart';

// ⭐⭐ هام: تغيير typeId إلى رقم فريد لم تستخدمه بعد
// (مثلاً 6، طالما أنه ليس 0, 1, 2, 3, 4, 5)
// يجب أن يكون فريدًا عن InvoiceType, Invoice, Item, Supplier، إلخ.
@HiveType(typeId: 6)
class Customer extends HiveObject {
  @HiveField(0)
  final String id; // ⭐⭐ اجعله 'final' لأن المعرف لا يتغير بعد الإنشاء
  
  @HiveField(1)
  String name; // ⭐⭐ اجعله 'String' بدلاً من 'late String' ليكون قابلاً للتعديل ومُهيأً

  @HiveField(2)
  String? phoneNumber; // ⭐⭐ تغيير الاسم من 'phone' إلى 'phoneNumber' للتوافق مع شاشة العملاء
  // وكذلك اجعله 'String?' للتعبير عن أنه اختياري (يمكن أن يكون null)

  @HiveField(3)
  String? address; // ⭐⭐ اجعله 'String?'

  @HiveField(4) // ⭐⭐ حقل جديد: البريد الإلكتروني للمورد
  String? email; // البريد الإلكتروني للعميل (اختياري وقابل للتعديل)

  @HiveField(5) // ⭐⭐ حقل جديد: ملاحظات إضافية عن المورد
  String? notes; // ملاحظات إضافية عن العميل (اختياري وقابل للتعديل)

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber, // ⭐⭐ تغيير الاسم هنا أيضًا
    this.address,
    this.email, // ⭐⭐ أضف هذا في المُنشئ
    this.notes, // ⭐⭐ أضف هذا في المُنشئ
  });
}
