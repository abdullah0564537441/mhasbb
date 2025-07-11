// lib/screens/sales_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/screens/add_edit_invoice_screen.dart'; // تأكد من وجوده

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

  Future<void> _deleteInvoice(Invoice invoice) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف فاتورة رقم ${invoice.invoiceNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await invoice.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الفاتورة بنجاح!')),
      );
    }
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
              child: Text('لا توجد فواتير مبيعات حتى الآن.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: salesInvoices.length,
            itemBuilder: (context, index) {
              final invoice = salesInvoices[index];
              final total = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.sellingPrice));
              final numberFormat = NumberFormat('#,##0.00', 'en_US');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الفاتورة: ${invoice.invoiceNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}',
                      ),
                      Text(
                        'العميل: ${invoice.customerName ?? 'غير محدد'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'بنود الفاتورة:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      ...invoice.items.map((item) => Text(
                            '${item.itemName} (${item.quantity} ${item.unit} x ${numberFormat.format(item.sellingPrice)})',
                          )).toList(),
                      const Divider(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الإجمالي الكلي: ${numberFormat.format(total)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => AddEditInvoiceScreen(invoice: invoice)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInvoice(invoice),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditInvoiceScreen(invoice: null)),
          );
        },
        label: const Text('إضافة فاتورة مبيعات'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
