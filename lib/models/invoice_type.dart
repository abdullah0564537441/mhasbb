// lib/models/invoice_type.dart
import 'package:hive/hive.dart';

part 'invoice_type.g.dart'; // ⭐⭐ هذا السطر هو الأهم والذي كان مفقوداً

@HiveType(typeId: 5) // ⭐ تم التأكد أن الـ typeId هذا فريد
enum InvoiceType {
  @HiveField(0)
  sale, // فاتورة مبيعات
  @HiveField(1)
  purchase, // فاتورة مشتريات
}
