import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// شاشة مؤقتة لكل قسم حتى نطورها لاحقًا
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('هذه شاشة $title')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('users'); // صندوق المستخدمين

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق محاسبة',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),

        // تعريف شاشات الأقسام مؤقتًا:
        '/sales_invoices': (context) => const PlaceholderScreen(title: 'فواتير البيع'),
        '/purchase_invoices': (context) => const PlaceholderScreen(title: 'فواتير الشراء'),
        '/inventory': (context) => const PlaceholderScreen(title: 'المخزون'),
        '/customers': (context) => const PlaceholderScreen(title: 'العملاء'),
        '/suppliers': (context) => const PlaceholderScreen(title: 'الموردين'),
        '/accounts': (context) => const PlaceholderScreen(title: 'كشف الحساب'),
        '/reports': (context) => const PlaceholderScreen(title: 'التقارير'),
        '/tax': (context) => const PlaceholderScreen(title: 'الضريبة'),
        '/settings': (context) => const PlaceholderScreen(title: 'الإعدادات'),
      },
    );
  }
}