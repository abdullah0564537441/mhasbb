import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تعريف قائمة الأقسام التي ستظهر في الشاشة الرئيسية
    // كل قسم يحتوي على عنوان، أيقونة، ومسار (route) للانتقال إليه
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
        centerTitle: true, // لتوسيط العنوان في AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0), // مسافة بادئة حول الشبكة
        child: GridView.builder(
          itemCount: sections.length, // عدد العناصر في الشبكة هو عدد الأقسام
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 أعمدة في كل صف
            mainAxisSpacing: 15, // المسافة الرأسية بين العناصر
            crossAxisSpacing: 15, // المسافة الأفقية بين العناصر
            childAspectRatio: 1, // نسبة العرض إلى الارتفاع لكل عنصر (1 تعني مربع)
          ),
          itemBuilder: (context, index) {
            final section = sections[index]; // الحصول على بيانات القسم الحالي
            return GestureDetector(
              onTap: () {
                // عند النقر على القسم، يتم التنقل إلى المسار المحدد له
                // يجب تعريف هذه المسارات في MaterialApp في ملف main.dart
                Navigator.pushNamed(context, section['route'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100, // لون خلفية البطاقة
                  borderRadius: BorderRadius.circular(15), // زوايا دائرية للبطاقة
                  boxShadow: [ // ظل خفيف للبطاقة لإعطاء عمق
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتويات عمودياً
                  children: [
                    Icon(
                      section['icon'] as IconData, // أيقونة القسم
                      size: 45,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(height: 10), // مسافة بين الأيقونة والنص
                    Text(
                      section['title'] as String, // عنوان القسم
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
