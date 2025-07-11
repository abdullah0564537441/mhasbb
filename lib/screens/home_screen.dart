// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mhasbb/screens/calculator_screen.dart';
import 'package:mhasbb/screens/reports_screen.dart';
import 'package:mhasbb/screens/placeholder_screen.dart'; // ⭐⭐ تم إضافة هذا الاستيراد

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToSection(BuildContext context, String sectionName) {
    Widget screen;
    switch (sectionName) {
      case 'المبيعات':
        screen = const PlaceholderScreen(title: 'شاشة المبيعات'); // استبدل بشاشة المبيعات الحقيقية
        break;
      case 'المشتريات':
        screen = const PlaceholderScreen(title: 'شاشة المشتريات'); // استبدل بشاشة المشتريات الحقيقية
        break;
      case 'المخزون':
        screen = const PlaceholderScreen(title: 'شاشة المخزون'); // استبدل بشاشة المخزون الحقيقية
        break;
      case 'الحسابات':
        screen = const PlaceholderScreen(title: 'شاشة الحسابات'); // استبدل بشاشة الحسابات الحقيقية
        break;
      case 'العملاء':
        screen = const PlaceholderScreen(title: 'شاشة العملاء'); // استبدل بشاشة العملاء الحقيقية
        break;
      case 'الموردين':
        screen = const PlaceholderScreen(title: 'شاشة الموردين'); // استبدل بشاشة الموردين الحقيقية
        case 'المرتجعات':
        screen = const PlaceholderScreen(title: 'شاشة المرتجعات'); // استبدل بشاشة المرتجعات الحقيقية
        break;
      case 'سندات الصرف والقبض':
        screen = const PlaceholderScreen(title: 'شاشة سندات الصرف والقبض'); // استبدل بشاشة السندات الحقيقية
        break;
      case 'التقارير':
        screen = const ReportsScreen();
        break;
      case 'الآلة الحاسبة':
        screen = const CalculatorScreen();
        break;
      default:
        screen = PlaceholderScreen(title: sectionName);
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
