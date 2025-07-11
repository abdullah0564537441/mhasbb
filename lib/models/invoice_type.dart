// lib/models/invoice_type.dart
import 'package:hive/hive.dart';

part 'invoice_type.g.dart'; // هذا الملف سيتم توليده بواسطة build_runner

@HiveType(typeId: 5) // تأكد أن typeId فريد وغير مستخدم لموديل آخر
enum InvoiceType {
  @HiveField(0)
  sale, // فاتورة مبيعات
  @HiveField(1)
  purchase, // فاتورة مشتريات
  @HiveField(2)
  salesReturn, // مرتجع مبيعات
  @HiveField(3)
  purchaseReturn, // مرتجع مشتريات
}
