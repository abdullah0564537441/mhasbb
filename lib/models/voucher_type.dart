// lib/models/voucher_type.dart
import 'package:hive/hive.dart';

part 'voucher_type.g.dart';

@HiveType(typeId: 7) // تأكد من أن هذا الـ typeId فريد
enum VoucherType {
  @HiveField(0)
  expense, // سند صرف
  @HiveField(1)
  income,  // سند قبض
}
