// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// استيراد الشاشات الرئيسية
import 'package:mhasbb/screens/home_screen.dart';

// ⭐⭐ استيراد جميع موديلات Hive
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/models/return_invoice.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/models/invoice_type.dart'; // ⭐⭐ أضف هذا السطر ⭐⭐

// متغير عام لـ SharedPreferences (إذا كنت تستخدمه)
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // تهيئة SharedPreferences
    prefs = await SharedPreferences.getInstance();

    // تهيئة Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // ⭐⭐ تسجيل جميع محولات (adapters) Hive
    // تأكد من أن الـ typeId لكل محول فريد وغير مستخدم
    Hive.registerAdapter(InvoiceTypeAdapter()); // TypeId 0 (أو حسب تعريفك)
    Hive.registerAdapter(ItemAdapter()); // TypeId 1
    Hive.registerAdapter(CustomerAdapter()); // TypeId 2
    Hive.registerAdapter(InvoiceItemAdapter()); // TypeId 3
    Hive.registerAdapter(InvoiceAdapter()); // TypeId 4
    Hive.registerAdapter(SupplierAdapter()); // TypeId 5
    Hive.registerAdapter(VoucherTypeAdapter()); // TypeId 7 (من ملف voucher_type.dart)
    Hive.registerAdapter(VoucherAdapter()); // TypeId 8 (من ملف voucher.dart)
    Hive.registerAdapter(PaymentMethodAdapter()); // TypeId 6 (افترض وجوده)
    Hive.registerAdapter(ReturnInvoiceAdapter()); // TypeId 9 (من ملف return_invoice.dart)


    // ⭐⭐ فتح جميع صناديق Hive (Boxes)
    await Hive.openBox<Item>('items_box');
    await Hive.openBox<Customer>('customers_box');
    await Hive.openBox<Invoice>('invoices_box');
    await Hive.openBox<Supplier>('suppliers_box');
    await Hive.openBox<Voucher>('vouchers_box');
    await Hive.openBox<ReturnInvoice>('return_invoices_box');

    print('✅ App Initialization Complete...');
  } catch (e, stacktrace) {
    print('❌ Critical Error during App Initialization: $e');
    print('Stacktrace: $stacktrace');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mhasbb App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
