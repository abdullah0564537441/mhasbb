import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // لاستخدام DateFormat لتنسيق التاريخ

// استيراد موديل الفاتورة (Invoice)
import 'package:mhasbb/models/invoice.dart';
// استيراد شاشة إضافة/تعديل الفاتورة
import 'package:mhasbb/screens/add_edit_invoice_screen.dart';

class SalesInvoicesScreen extends StatefulWidget {
  const SalesInvoicesScreen({super.key});

  @override
  State<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends State<SalesInvoicesScreen> {
  late Box<Invoice> invoicesBox; // صندوق Hive الخاص بالفواتير

  @override
  void initState() {
    super.initState();
    // فتح صندوق الفواتير عند تهيئة الشاشة
    invoicesBox = Hive.box<Invoice>('invoices_box');
  }

  // دالة لعرض نافذة التأكيد وحذف الفاتورة
  void _confirmAndDeleteInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف الفاتورة رقم "${invoice.invoiceNumber}"؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('لا', style: TextStyle(color: Colors.indigo)),
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق نافذة التأكيد
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // لون أحمر لزر الحذف
                foregroundColor: Colors.white,
              ),
              child: const Text('نعم، احذف', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // حذف الفاتورة من Hive باستخدام مفتاحها (key)
                if (invoice.key != null) {
                  invoicesBox.delete(invoice.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الفاتورة بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('خطأ: لا يمكن العثور على مفتاح الفاتورة للحذف.')),
                  );
                }
                Navigator.of(context).pop(); // إغلاق نافذة التأكيد
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير البيع'),
        centerTitle: true,
      ),
      // استخدام ValueListenableBuilder لمراقبة التغييرات في صندوق Hive
      body: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: invoicesBox.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فواتير بيع حتى الآن.\nاضغط على "+" لإضافة فاتورة جديدة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // عرض قائمة الفواتير الموجودة
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final invoice = box.getAt(index); // الحصول على الفاتورة من الصندوق

              // تأكد أن الفاتورة ليست null قبل محاولة عرضها
              if (invoice == null) {
                return const SizedBox.shrink(); // لا تعرض شيئًا إذا كانت الفاتورة null
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const Icon(Icons.receipt_long, size: 40, color: Colors.blueGrey),
                  title: Text(
                    'فاتورة رقم: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // ⭐ التعديل هنا: استخدم customerName مباشرة
                      Text('العميل: ${invoice.customerName}', style: TextStyle(color: Colors.grey[700])),
                      Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}', style: TextStyle(color: Colors.grey[700])),
                      Text('الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () {
                          // الانتقال إلى شاشة تعديل الفاتورة وتمرير الفاتورة
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditInvoiceScreen(invoice: invoice), // تمرير الفاتورة للتعديل
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmAndDeleteInvoice(context, invoice); // استدعاء دالة التأكيد والحذف
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // يمكنك فتح شاشة تفاصيل الفاتورة هنا
                    print('Tapped on invoice: ${invoice.invoiceNumber}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // الانتقال إلى شاشة إضافة فاتورة جديدة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditInvoiceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
