// lib/models/voucher_type.dart
import 'package:hive/hive.dart';

part 'voucher_type.g.dart';

@HiveType(typeId: 7) // تأكد أن الـ typeId فريد
enum VoucherType {
  @HiveField(0)
  receipt, // سند قبض
  @HiveField(1)
  payment, // سند صرف
}
