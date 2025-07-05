// lib/screens/sales_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ والأرقام
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart'; // للتأكد من استيراد InvoiceItem
import 'package:mhasbb/screens/add_edit_invoice_screen.dart'; // استيراد شاشة إضافة/تعديل فاتورة

class SalesInvoicesScreen extends StatefulWidget {
  const SalesInvoicesScreen({super.key});

  @override
  State<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends State<SalesInvoicesScreen> {
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
      total += item.quantity * item.sellingPrice; // استخدام sellingPrice من InvoiceItem
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
          content: Text('هل أنت متأكد أنك تريد حذف فاتورة المبيعات رقم "${invoice.invoiceNumber}"؟'),
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
        title: const Text('فواتير المبيعات'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: invoicesBox.listenable(),
        builder: (context, box, _) {
          final salesInvoices = box.values
              .where((invoice) => invoice.type == InvoiceType.sale)
              .toList()
              .cast<Invoice>();

          if (salesInvoices.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد فواتير مبيعات حتى الآن.\nاضغط على "+" لإضافة فاتورة مبيعات جديدة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: salesInvoices.length,
            itemBuilder: (context, index) {
              final invoice = salesInvoices[index];
              final total = _calculateInvoiceTotal(invoice); // ⭐ استخدام الدالة هنا
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
                    child: Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(
                    'فاتورة رقم: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التاريخ: ${dateFormat.format(invoice.date)}'),
                      if (invoice.customerName != null && invoice.customerName!.isNotEmpty)
                        Text('العميل: ${invoice.customerName}'),
                      Text('الإجمالي: ${numberFormat.format(total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)), // ⭐ استخدام 'total'
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditInvoiceScreen(invoice: invoice),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditInvoiceScreen(invoice: null)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
