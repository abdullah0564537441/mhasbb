// lib/models/voucher.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/voucher_type.dart'; // استيراد الـ enum الجديد

part 'voucher.g.dart';

@HiveType(typeId: 8) // تأكد من أن هذا الـ typeId فريد
class Voucher extends HiveObject {
  @HiveField(0)
  final String id; // معرف فريد للسند (UUID)

  @HiveField(1)
  String voucherNumber; // رقم السند

  @HiveField(2)
  VoucherType type; // نوع السند (صرف/قبض)

  @HiveField(3)
  DateTime date; // تاريخ السند

  @HiveField(4)
  double amount; // المبلغ الكلي للسند

  @HiveField(5)
  String description; // وصف أو بيان السند

  // الحساب المرتبط بالسند (مثلاً عميل، مورد، مصروف، إيراد)
  // يمكننا استخدام معرف ونوع لربطه بكيانات أخرى
  @HiveField(6)
  String? relatedPartyId; // معرف الطرف المرتبط (اختياري)
  @HiveField(7)
  String? relatedPartyName; // اسم الطرف المرتبط (للتسهيل في العرض)

  @HiveField(8)
  String paymentMethod; // طريقة الدفع/القبض (نقدي، بنكي، شيك)

  Voucher({
    required this.id,
    required this.voucherNumber,
    required this.type,
    required this.date,
    required this.amount,
    required this.description,
    this.relatedPartyId,
    this.relatedPartyName,
    required this.paymentMethod,
  });
}
