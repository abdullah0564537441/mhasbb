// lib/screens/purchase_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ والأرقام
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart'; // للتأكد من استيراد InvoiceItem
import 'package:mhasbb/screens/add_edit_purchase_invoice_screen.dart'; // استيراد شاشة إضافة/تعديل فاتورة الشراء

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

  // دالة لحساب الإجمالي الكلي للفاتورة
  double _calculateInvoiceTotal(Invoice invoice) {
    double total = 0.0;
    for (var item in invoice.items) {
      // ⭐ تم التعديل هنا: استخدام item.sellingPrice بدلاً من item.price
      total += item.quantity * item.sellingPrice;
    }
    return total;
  }

  // دالة لتأكيد وحذف الفاتورة
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
                await invoice.delete(); // حذف الفاتورة من Hive
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الفاتورة بنجاح!')),
                );
                Navigator.of(context).pop();
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
        title: const Text('فواتير الشراء'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: invoicesBox.listenable(),
        builder: (context, box, _) {
          final purchaseInvoices = box.values
              .where((invoice) => invoice.type == InvoiceType.purchase)
              .toList()
              .cast<Invoice>();

          if (purchaseInvoices.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فواتير شراء حتى الآن.\nاضغط على "+" لإضافة فاتورة شراء جديدة.',
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
              final total = _calculateInvoiceTotal(invoice);
              final dateFormat = DateFormat('yyyy-MM-dd'); // تنسيق التاريخ
              final numberFormat = NumberFormat('#,##0.00', 'en_US'); // تنسيق الأرقام

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(
                    'فاتورة رقم: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التاريخ: ${dateFormat.format(invoice.date)}'),
                      if (invoice.supplierName != null && invoice.supplierName!.isNotEmpty)
                        Text('المورد: ${invoice.supplierName}'),
                      Text('الإجمالي: ${numberFormat.format(total)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // التنقل لشاشة التعديل مع تمرير الفاتورة الحالية
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
            MaterialPageRoute(builder: (context) => const AddEditPurchaseInvoiceScreen(invoice: null)), // تم التعديل
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
