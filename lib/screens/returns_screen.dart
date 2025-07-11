// lib/screens/returns_screen.dart
import 'package:flutter/material.dart';
// تأكد من استيراد شاشة إضافة/تعديل المرتجعات
// تأكد من أن اسم هذا الملف في مجلد screens/ يبدأ بحرف صغير: add_edit_return_invoice_screen.dart
import 'package:mhasbb/screens/add_edit_return_invoice_Screen.dart'; // ⭐⭐ تأكد من هذا الاستيراد ⭐⭐
// إذا كان لديك موديل ReturnInvoice، قم باستيراده
// import 'package:mhasbb/models/return_invoice.dart';
// إذا كنت تستخدم Hive، ستحتاج إلى Hive_flutter
// import 'package:hive_flutter/hive_flutter.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  // هنا ستحتفظ بقائمة المرتجعات، مبدئياً هي قائمة وهمية
  List<Map<String, String>> _dummyReturns = [
    {'id': 'RET001', 'date': '2024-07-08', 'customer': 'العميل أ', 'amount': '150.00'},
    {'id': 'RET002', 'date': '2024-07-07', 'customer': 'العميل ب', 'amount': '250.50'},
  ];

  // دالة لجلب المرتجعات من Hive (إذا كنت تستخدمه)
  // @override
  // void initState() {
  //   super.initState();
  //   _loadReturns();
  // }
  //
  // void _loadReturns() {
  //   final returnInvoiceBox = Hive.box<ReturnInvoice>('return_invoices_box');
  //   setState(() {
  //     _dummyReturns = returnInvoiceBox.values.map((returnInvoice) {
  //       return {
  //         'id': returnInvoice.id ?? '', // افترض أن لديك حقل id في الموديل
  //         'date': returnInvoice.date.toIso8601String().split('T')[0], // افترض أن لديك حقل date
  //         'customer': returnInvoice.customerName ?? '', // افترض أن لديك حقل customerName
  //         'amount': returnInvoice.totalAmount.toStringAsFixed(2), // افترض أن لديك حقل totalAmount
  //       };
  //     }).toList();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة المرتجعات'),
        centerTitle: true,
      ),
      body: _dummyReturns.isEmpty
          ? const Center(
              child: Text('لا توجد مرتجعات لعرضها حاليًا.'),
            )
          : ListView.builder(
              itemCount: _dummyReturns.length,
              itemBuilder: (context, index) {
                final returnItem = _dummyReturns[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                    title: Text('مرتجع رقم: ${returnItem['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العميل: ${returnItem['customer']}'),
                        Text('التاريخ: ${returnItem['date']}'),
                      ],
                    ),
                    trailing: Text(
                      '${returnItem['amount']} ر.س',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    onTap: () {
                      // هنا يمكنك الانتقال إلى شاشة تفاصيل المرتجع أو تعديله
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditReturnInvoiceScreen(
                            // يمكنك تمرير بيانات المرتجع الحالي هنا إذا كنت تريد التعديل
                            // returnInvoiceId: returnItem['id'],
                          ),
                        ),
                      ).then((_) {
                        // عند العودة من شاشة الإضافة/التعديل، قم بتحديث القائمة
                        // _loadReturns(); // قم بإلغاء التعليق إذا كنت تستخدم Hive
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // الانتقال إلى شاشة إضافة/تعديل فاتورة مرتجع جديدة
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditReturnInvoiceScreen()),
          ).then((_) {
            // عند العودة من شاشة الإضافة، قم بتحديث القائمة
            // _loadReturns(); // قم بإلغاء التعليق إذا كنت تستخدم Hive
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة مرتجع جديد',
      ),
    );
  }
}
