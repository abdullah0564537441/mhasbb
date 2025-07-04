import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {'title': 'فواتير البيع', 'icon': Icons.receipt_long, 'route': '/sales_invoices'},
      {'title': 'فواتير الشراء', 'icon': Icons.shopping_cart, 'route': '/purchase_invoices'},
      {'title': 'المخزون', 'icon': Icons.inventory, 'route': '/inventory'},
      {'title': 'العملاء', 'icon': Icons.people, 'route': '/customers'},
      {'title': 'الموردين', 'icon': Icons.store, 'route': '/suppliers'},
      {'title': 'كشف حساب', 'icon': Icons.account_balance_wallet, 'route': '/accounts'},
      {'title': 'التقارير', 'icon': Icons.bar_chart, 'route': '/reports'},
      {'title': 'الضريبة', 'icon': Icons.percent, 'route': '/tax'},
      {'title': 'الإعدادات', 'icon': Icons.settings, 'route': '/settings'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final section = sections[index];
            return GestureDetector(
              onTap: () {
                // التنقل الحقيقي إلى الشاشة المطلوبة
                Navigator.pushNamed(context, section['route'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      section['icon'] as IconData,
                      size: 45,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      section['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}