// lib/main.dart (تحديث)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// ... استيرادات الشاشات الأخرى
import 'package:mhasbb/screens/vouchers_screen.dart'; // ⭐⭐ سنضيف هذه الشاشة لاحقاً

// استيراد موديلات Hive الجديدة
import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';

// ... استيرادات موديلات Hive الأخرى

// ... (بقية كود PlaceholderScreen)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    prefs = await SharedPreferences.getInstance();

    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // تسجيل جميع محولات (adapters) Hive لموديلات البيانات
    Hive.registerAdapter(InvoiceTypeAdapter());
    Hive.registerAdapter(ItemAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(SupplierAdapter());
    Hive.registerAdapter(VoucherTypeAdapter()); // ⭐⭐ تسجيل محول VoucherType
    Hive.registerAdapter(VoucherAdapter());      // ⭐⭐ تسجيل محول Voucher


    // فتح جميع صناديق Hive (Boxes)
    await Hive.openBox<Item>('items_box');
    await Hive.openBox<Customer>('customers_box');
    await Hive.openBox<Invoice>('invoices_box');
    await Hive.openBox<Supplier>('suppliers_box');
    await Hive.openBox<Voucher>('vouchers_box'); // ⭐⭐ فتح صندوق السندات

    print('✅ App Initialization Complete: SharedPreferences, Hive, and Hive Boxes are ready.');
  } catch (e, stacktrace) {
    print('❌ Critical Error during App Initialization: $e');
    print('Stacktrace: $stacktrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... (بقية الثيم وإعدادات MaterialApp)

      home: FutureBuilder<bool>(
        // ... (بقية كود FutureBuilder)
      ),

      routes: {
        // ... مسارات أخرى
        '/accounts': (context) => const AccountStatementScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/vouchers': (context) => const VouchersScreen(), // ⭐⭐ إضافة مسار شاشة السندات
        '/tax': (context) => const PlaceholderScreen(title: 'الضريبة'),
        '/settings': (context) => const PlaceholderScreen(title: 'الإعدادات'),
      },
    );
  }

  Future<bool> _checkPasswordStatus() async {
    final storedPassword = prefs.getString('app_password');
    return storedPassword != null && storedPassword.isNotEmpty;
  }
}
