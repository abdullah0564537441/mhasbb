// lib/models/invoice_type.dart
import 'package:hive/hive.dart';

// ⭐⭐ هذا السطر هو الأهم والذي كان مفقوداً
part 'invoice_type.g.dart';

// ⭐⭐ هام: تأكد أن typeId هذا فريد ولم تستخدمه لأي كلاس أو enum آخر
// اختر رقمًا لا يتعارض مع typeId: 3 لـ Invoice أو أي typeId آخر لديك.
// على سبيل المثال، إذا كانت لديك typeId 0, 1, 2, 3 استخدم 4 أو 20.
@HiveType(typeId: 4) // مثال: استخدم رقمًا فريدًا
enum InvoiceType {
  @HiveField(0)
  sale, // فاتورة مبيعات
  @HiveField(1)
  purchase, // فاتورة مشتريات
}
