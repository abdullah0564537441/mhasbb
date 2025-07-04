import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // لإضافة path_provider لتهيئة Hive بشكل صحيح

// استيراد الشاشات الرئيسية
import 'package:mhasbb/screens/home_screen.dart'; // HomeScreen سيكون الشاشة الرئيسية
import 'package:mhasbb/screens/login_screen.dart';
import 'package:mhasbb/screens/sales_invoices_screen.dart';
import 'package:mhasbb/screens/add_edit_invoice_screen.dart';
import 'package:mhasbb/screens/inventory_screen.dart'; // شاشة المخزون (التي هي ItemsScreen في الواقع)
import 'package:mhasbb/screens/purchase_invoices_screen.dart'; // استيراد شاشة فواتير الشراء
import 'package:mhasbb/screens/suppliers_screen.dart'; // استيراد شاشة الموردين

// استيراد موديلات Hive
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/supplier.dart'; // استيراد موديل المورد

// ---
// تعريف متغير SharedPreferences العام
late SharedPreferences prefs;

// شاشة مؤقتة لكل قسم (ستظل موجودة لغير المكتملة)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'هذه شاشة $title',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة SharedPreferences
    prefs = await SharedPreferences.getInstance();

    // تهيئة Hive باستخدام المسار الصحيح
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // تسجيل جميع محولات (adapters) Hive لموديلات البيانات
    // تأكد أن أرقام TypeId فريدة ولا تتكرر بين الموديلات!
    Hive.registerAdapter(ItemAdapter());         // TypeId: 0
    Hive.registerAdapter(CustomerAdapter());     // TypeId: 1
    Hive.registerAdapter(InvoiceItemAdapter());  // TypeId: 2
    Hive.registerAdapter(InvoiceTypeAdapter());  // TypeId: (موجود داخل InvoiceAdapter)
    Hive.registerAdapter(InvoiceAdapter());      // TypeId: 3
    Hive.registerAdapter(SupplierAdapter());     // TypeId: 4 - محول المورد الجديد

    // فتح جميع صناديق Hive (Boxes) التي ستخزن البيانات
    await Hive.openBox<Item>('items_box');
    await Hive.openBox<Customer>('customers_box');
    await Hive.openBox<Invoice>('invoices_box');
    await Hive.openBox<Supplier>('suppliers_box'); // فتح صندوق الموردين الجديد

    print('✅ App Initialization Complete: SharedPreferences, Hive, and Hive Boxes are ready.');
  } catch (e, stacktrace) {
    print('❌ Critical Error during App Initialization: $e');
    print('Stacktrace: $stacktrace');
    // يمكنك عرض رسالة خطأ للمستخدم هنا أو تسجيلها في خدمة مراقبة الأخطاء
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
      title: 'تطبيق إدارة المبيعات والمخزون',
      debugShowCheckedModeBanner: false,

      // تحديد الثيم العام للتطبيق
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: const CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.indigo),
          floatingLabelStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.indigo[800], fontSize: 24, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 16),
          labelLarge: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // تحديد الشاشة الأولية بناءً على حالة كلمة المرور
      home: FutureBuilder<bool>(
        future: _checkPasswordStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              ),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('حدث خطأ: ${snapshot.error}'),
              ),
            );
          }
          // بعد تسجيل الدخول، ننتقل إلى HomeScreen مباشرة
          return snapshot.data == true ? const HomeScreen() : const LoginScreen();
        },
      ),

      // تعريف المسارات الرئيسية (login و home) وإضافة مسارات شاشات الأقسام
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(), // مسار /home يشير الآن إلى HomeScreen
        '/sales_invoices': (context) => const SalesInvoicesScreen(),
        '/add_edit_invoice': (context) => const AddEditInvoiceScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/purchase_invoices': (context) => const PurchaseInvoicesScreen(),
        '/customers': (context) => const PlaceholderScreen(title: 'العملاء'),
        '/suppliers': (context) => const SuppliersScreen(),
        '/accounts': (context) => const PlaceholderScreen(title: 'كشف الحساب'),
        '/reports': (context) => const PlaceholderScreen(title: 'التقارير'),
        '/tax': (context) => const PlaceholderScreen(title: 'الضريبة'),
        '/settings': (context) => const PlaceholderScreen(title: 'الإعدادات'),
      },
    );
  }

  // دالة مساعدة للتحقق من حالة كلمة المرور باستخدام SharedPreferences
  Future<bool> _checkPasswordStatus() async {
    final storedPassword = prefs.getString('app_password');
    return storedPassword != null && storedPassword.isNotEmpty;
  }
}
