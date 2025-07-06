// lib/models/payment_method.dart
import 'package:hive/hive.dart';

part 'payment_method.g.dart';

@HiveType(typeId: 4) // تأكد أن هذا الـ typeId فريد وغير مستخدم
enum PaymentMethod {
  @HiveField(0)
  cash, // نقدي
  @HiveField(1)
  credit, // آجل (على الحساب)
  @HiveField(2)
  bankTransfer, // تحويل بنكي
}
