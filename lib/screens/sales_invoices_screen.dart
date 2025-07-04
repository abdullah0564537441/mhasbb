import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // سنستخدمه هنا لعرض البيانات

// ⭐ استيراد الموديلات اللازمة
import 'package:mhasbb/models/invoice.dart'; // استيراد موديل الفاتورة
import 'package:mhasbb/models/customer.dart'; // استيراد موديل العميل (لفاتورة البيع)

// ⭐ استيراد شاشة إضافة/تعديل الفاتورة
import 'package:mhasbb/screens/add_edit_invoice_screen.dart';

// شاشة عرض فواتير البيع الرئيسية
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
    // الحصول على مثيل صندوق الفواتير عند تهيئة الشاشة
    invoicesBox = Hive.box<Invoice>('invoices_box');
  }

  // دالة لعرض نافذة التأكيد وحذف الفاتورة
  void _confirmAndDeleteInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه الفاتورة؟'),
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
      // هذا سيضمن تحديث الواجهة تلقائيًا عند إضافة/حذف/تعديل الفواتير
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
                  leading: const Icon(Icons.receipt, size: 40, color: Colors.indigo),
                  title: Text(
                    'فاتورة رقم: ${invoice.id}', // استخدم invoice.id مباشرة
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('العميل: ${invoice.customer.name}', style: TextStyle(color: Colors.grey[700])),
                      Text('التاريخ: ${invoice.invoiceDate.toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[700])),
                      Text('الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  // إضافة زر الحذف هنا
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // لجعل Row تأخذ أقل مساحة ممكنة
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey), // زر تعديل
                        onPressed: () {
                          // ⭐ الانتقال إلى شاشة تفاصيل/تعديل الفاتورة وتمرير الفاتورة
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditInvoiceScreen(invoice: invoice),
                            ),
                          );
                          print('View/Edit invoice: ${invoice.id}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), // زر الحذف
                        onPressed: () {
                          _confirmAndDeleteInvoice(context, invoice); // استدعاء دالة التأكيد والحذف
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // يمكنك إزالة هذا الـ onTap إذا كنت تفضل أن يكون التفاعل عبر الأزرار فقط
                    // أو يمكنك تركه للانتقال إلى شاشة التفاصيل
                    print('Tapped on invoice: ${invoice.id}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النقر على الفاتورة (يمكنك تعديل هذا السلوك)')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ⭐ الانتقال إلى شاشة إضافة فاتورة جديدة فارغة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditInvoiceScreen(), // للانتقال إلى شاشة إضافة فاتورة جديدة
            ),
          );
          print('Add New Invoice button pressed');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
