// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mhasbb/screens/calculator_screen.dart';
import 'package:mhasbb/screens/reports_screen.dart';

// ⭐⭐ هذه هي الاستيرادات الصحيحة بناءً على أن كل ملفاتك تبدأ بحرف صغير ⭐⭐
import 'package:mhasbb/screens/sales_invoices_screen.dart';
import 'package:mhasbb/screens/purchase_invoices_screen.dart';
import 'package:mhasbb/screens/inventory_screen.dart';
import 'package:mhasbb/screens/account_statement_screen.dart'; // ⭐⭐ كل الأحرف صغيرة هنا ⭐⭐
import 'package:mhasbb/screens/customers_screen.dart';          // كل الأحرف صغيرة هنا
import 'package:mhasbb/screens/suppliers_screen.dart';          // كل الأحرف صغيرة هنا
import 'package:mhasbb/screens/returns_screen.dart';            // كل الأحرف صغيرة هنا
import 'package:mhasbb/screens/vouchers_screen.dart';
import 'package:mhasbb/screens/notes_screen.dart';              // كل الأحرف صغيرة هنا

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToSection(BuildContext context, String sectionName) {
    Widget screen;
    switch (sectionName) {
      case 'المبيعات':
        screen = const SalesInvoicesScreen();
        break;
      case 'المشتريات':
        screen = const PurchaseInvoicesScreen();
        break;
      case 'المخزون':
        screen = const InventoryScreen();
        break;
      case 'الحسابات':
        // اسم الكلاس نفسه داخل الملف عادة ما يبدأ بحرف كبير (PascalCase)
        // لذا، حتى لو كان اسم الملف account_statement_screen.dart، الكلاس داخله سيكون AccountStatementScreen
        screen = const AccountStatementScreen();
        break;
      case 'العملاء':
        screen = const CustomersScreen();
        break;
      case 'الموردين':
        screen = const SuppliersScreen();
        break;
      case 'المرتجعات':
        screen = const ReturnsScreen();
        break;
      case 'سندات الصرف والقبض':
        screen = const VouchersScreen();
        break;
      case 'التقارير':
        screen = const ReportsScreen();
        break;
      case 'الآلة الحاسبة':
        screen = const CalculatorScreen();
        break;
      case 'الملاحظات':
        screen = const NotesScreen();
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
            _buildCategoryCard(context, 'الحسابات', Icons.account_balance),
            _buildCategoryCard(context, 'العملاء', Icons.people),
            _buildCategoryCard(context, 'الموردين', Icons.local_shipping),
            _buildCategoryCard(context, 'المرتجعات', Icons.assignment_return),
            _buildCategoryCard(context, 'سندات الصرف والقبض', Icons.receipt_long),
            _buildCategoryCard(context, 'التقارير', Icons.assessment),
            _buildCategoryCard(context, 'الآلة الحاسبة', Icons.calculate),
            _buildCategoryCard(context, 'الملاحظات', Icons.notes),
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
