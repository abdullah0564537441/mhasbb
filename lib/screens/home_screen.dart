// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mhasbb/screens/calculator_screen.dart';
import 'package:mhasbb/screens/reports_screen.dart';

// ⭐⭐ يجب عليك استيراد شاشاتك الأصلية هنا ⭐⭐
// أمثلة:
import 'package:mhasbb/screens/sales_screen.dart';       // افترض هذا هو اسم شاشتك الأصلية للمبيعات
import 'package:mhasbb/screens/purchases_screen.dart';    // افترض هذا هو اسم شاشتك الأصلية للمشتريات
import 'package:mhasbb/screens/inventory_screen.dart';    // افترض هذا هو اسم شاشتك الأصلية للمخزون
// import 'package:mhasbb/screens/accounts_screen.dart';     // ⭐⭐ تم حذف هذا الاستيراد: لا توجد شاشة للحسابات
import 'package:mhasbb/screens/customers_screen.dart';    // افترض هذا هو اسم شاشتك الأصلية للعملاء
import 'package:mhasbb/screens/suppliers_screen.dart';    // افترض هذا هو اسم شاشتك الأصلية للموردين
import 'package:mhasbb/screens/returns_screen.dart';      // افترض هذا هو اسم شاشتك الأصلية للمرتجعات
import 'package:mhasbb/screens/vouchers_screen.dart';     // افترض هذا هو اسم شاشتك الأصلية للسندات

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToSection(BuildContext context, String sectionName) {
    Widget screen;
    switch (sectionName) {
      case 'المبيعات':
        screen = const SalesScreen(); // ⭐⭐ استبدل بـ SalesScreen() أو اسم شاشتك الفعلية
        break;
      case 'المشتريات':
        screen = const PurchasesScreen(); // ⭐⭐ استبدل بـ PurchasesScreen() أو اسم شاشتك الفعلية
        break;
      case 'المخزون':
        screen = const InventoryScreen(); // ⭐⭐ استبدل بـ InventoryScreen() أو اسم شاشتك الفعلية
        break;
      // case 'الحسابات': // ⭐⭐ تم حذف هذه الحالة: لا توجد شاشة للحسابات
      //   screen = const AccountsScreen();
      //   break;
      case 'العملاء':
        screen = const CustomersScreen(); // ⭐⭐ استبدل بـ CustomersScreen() أو اسم شاشتك الفعلية
        break;
      case 'الموردين':
        screen = const SuppliersScreen(); // ⭐⭐ استبدل بـ SuppliersScreen() أو اسم شاشتك الفعلية
        break; // ⭐⭐ إضافة break; هنا للحالة السابقة 'الموردين' (كان مفقودًا)
      case 'المرتجعات':
        screen = const ReturnsScreen(); // ⭐⭐ استبدل بـ ReturnsScreen() أو اسم شاشتك الفعلية
        break;
      case 'سندات الصرف والقبض':
        screen = const VouchersScreen(); // ⭐⭐ استبدل بـ VouchersScreen() أو اسم شاشتك الفعلية
        break;
      case 'التقارير':
        screen = const ReportsScreen(); // هذا صحيح، هو ReportScreen
        break;
      case 'الآلة الحاسبة':
        screen = const CalculatorScreen(); // هذا صحيح، هو CalculatorScreen
        break;
      default:
        screen = const Center(child: Text('الشاشة غير متوفرة!'));
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُحاسب'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildCategoryCard(context, 'المبيعات', Icons.shopping_cart),
            _buildCategoryCard(context, 'المشتريات', Icons.shopping_basket),
            _buildCategoryCard(context, 'المخزون', Icons.inventory),
            // _buildCategoryCard(context, 'الحسابات', Icons.account_balance), // ⭐⭐ تم حذف هذه البطاقة: لا توجد شاشة للحسابات
            _buildCategoryCard(context, 'العملاء', Icons.people),
            _buildCategoryCard(context, 'الموردين', Icons.local_shipping),
            _buildCategoryCard(context, 'المرتجعات', Icons.assignment_return),
            _buildCategoryCard(context, 'سندات الصرف والقبض', Icons.receipt_long),
            _buildCategoryCard(context, 'التقارير', Icons.assessment),
            _buildCategoryCard(context, 'الآلة الحاسبة', Icons.calculate),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _navigateToSection(context, title),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
