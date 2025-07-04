// lib/screens/purchase_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mhasbb/models/invoice.dart'; // استيراد موديل الفاتورة
import 'package:mhasbb/screens/add_edit_purchase_invoice_screen.dart'; // سنقوم بإنشاء هذه الشاشة قريباً

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() => _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState extends State<PurchaseInvoicesScreen> {
  late Box<Invoice> invoicesBox;

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
  }

  // دالة لحذف فاتورة شراء
  void _confirmAndDeleteInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف فاتورة الشراء رقم "${invoice.invoiceNumber}"؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // ⭐ هنا يمكنك إضافة منطق إعادة الكميات إلى المخزون إذا تم حذف فاتورة شراء
                // حالياً، سنحذفها مباشرة للتبسيط
                await invoice.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف فاتورة الشراء بنجاح!')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // دالة لتنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير الشراء'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: invoicesBox.listenable(),
        builder: (context, box, _) {
          // تصفية الفواتير لعرض فواتير الشراء فقط
          final purchaseInvoices = box.values.where((invoice) => invoice.type == InvoiceType.purchase).toList();

          if (purchaseInvoices.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فواتير شراء حتى الآن.\nاضغط على "+" لإضافة فاتورة جديدة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: purchaseInvoices.length,
            itemBuilder: (context, index) {
              final invoice = purchaseInvoices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const Icon(Icons.shopping_bag, size: 40, color: Colors.green),
                  title: Text(
                    'فاتورة شراء رقم: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المورد: ${invoice.supplierName ?? 'غير محدد'}', style: TextStyle(color: Colors.grey[700])),
                      Text('التاريخ: ${_formatDate(invoice.invoiceDate)}', style: TextStyle(color: Colors.grey[700])),
                      Text('الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      // يمكنك عرض قائمة الأصناف هنا أو في شاشة تفاصيل الفاتورة
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // سيتم التنقل لشاشة التعديل عندما ننشئها
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditPurchaseInvoiceScreen(invoice: invoice),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmAndDeleteInvoice(context, invoice),
                      ),
                    ],
                  ),
                  onTap: () {
                    // يمكنك إضافة شاشة لعرض تفاصيل الفاتورة هنا
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // التنقل لإضافة فاتورة شراء جديدة
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditPurchaseInvoiceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
