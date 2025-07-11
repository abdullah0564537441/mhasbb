// lib/models/voucher.dart
import 'package:hive/hive.dart';
import 'package:mhasbb/models/voucher_type.dart'; // استيراد VoucherType
import 'package:mhasbb/models/payment_method.dart'; // استيراد PaymentMethod

part 'voucher.g.dart';

@HiveType(typeId: 8) // ⭐⭐ تأكد أن الـ typeId فريد وغير مستخدم ⭐⭐
class Voucher extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String voucherNumber;

  @HiveField(2)
  late VoucherType type; // قبض أو صرف

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late double amount;

  @HiveField(5)
  late PaymentMethod paymentMethod; // طريقة الدفع/القبض

  @HiveField(6)
  String? partyId; // معرف العميل أو المورد أو أي طرف آخر

  @HiveField(7)
  String? partyName; // اسم العميل أو المورد أو الطرف

  @HiveField(8)
  String? partyType; // نوع الطرف (مثال: 'Customer', 'Supplier', 'Other')

  @HiveField(9)
  String? notes;

  Voucher({
    required this.id,
    required this.voucherNumber,
    required this.type,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.partyId,
    this.partyName,
    this.partyType,
    this.notes,
  });
}
