import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // لاستخدام SharedPreferences

// استيراد الشاشات المكتملة التي سيتم التنقل إليها
import 'package:mhasbb/screens/login_screen.dart';
import 'package:mhasbb/screens/sales_invoices_screen.dart';
import 'package:mhasbb/screens/inventory_screen.dart'; // شاشة المخزون
import 'package:mhasbb/screens/purchase_invoices_screen.dart'; // شاشة فواتير الشراء
import 'package:mhasbb/main.dart'; // لاستخدام PlaceholderScreen (للأقسام غير المكتملة)


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // دالة لتسجيل الخروج
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_password'); // حذف كلمة المرور المحفوظة
    // العودة إلى شاشة تسجيل الدخول وإزالة جميع المسارات السابقة
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // دالة للتنقل بين الأقسام المختلفة
  void _navigateToSection(BuildContext context, String sectionName) {
    switch (sectionName) {
      case 'فواتير البيع':
        // هذا القسم مكتمل
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesInvoicesScreen()));
        break;
      case 'فواتير الشراء':
        // هذا القسم مكتمل
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseInvoicesScreen()));
        break;
      case 'المخزون':
        // هذا القسم مكتمل
        Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
        break;
      case 'العملاء':
      case 'الموردين':
      case 'كشف الحساب':
      case 'التقارير':
      case 'الضريبة':
      case 'الإعدادات':
        // استخدام PlaceholderScreen للأقسام التي لم يتم إنشاؤها بعد
        Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceholderScreen(title: sectionName)));
        break;
      default:
        // في حالة وجود قسم غير معروف، لا تفعل شيئًا أو عرض رسالة خطأ
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشاشة الرئيسية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // عمودين في كل صف
          crossAxisSpacing: 16.0, // المسافة الأفقية بين العناصر
          mainAxisSpacing: 16.0, // المسافة الرأسية بين العناصر
          children: [
            _buildSectionCard(context, 'فواتير البيع', Icons.receipt, Colors.blueAccent),
            _buildSectionCard(context, 'فواتير الشراء', Icons.shopping_cart, Colors.green),
            _buildSectionCard(context, 'المخزون', Icons.inventory_2, Colors.teal),
            _buildSectionCard(context, 'العملاء', Icons.people, Colors.orange),
            _buildSectionCard(context, 'الموردين', Icons.local_shipping, Colors.purple),
            _buildSectionCard(context, 'كشف الحساب', Icons.account_balance_wallet, Colors.redAccent),
            _buildSectionCard(context, 'التقارير', Icons.bar_chart, Colors.brown),
            _buildSectionCard(context, 'الضريبة', Icons.calculate, Colors.lime),
            _buildSectionCard(context, 'الإعدادات', Icons.settings, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToSection(context, title),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
