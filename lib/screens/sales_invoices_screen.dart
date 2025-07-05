// lib/screens/sales_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_type.dart';
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
    print('DEBUG: SalesInvoicesScreen - initState called.'); // ⭐ الطباعة 1
    try {
      invoicesBox = Hive.box<Invoice>('invoices_box');
      print('DEBUG: SalesInvoicesScreen - invoicesBox initialized successfully.'); // ⭐ الطباعة 2
    } catch (e, stacktrace) {
      print('ERROR: SalesInvoicesScreen - Failed to initialize invoicesBox: $e'); // ⭐ الطباعة 3 (خطأ)
      print('STACKTRACE: $stacktrace'); // ⭐ الطباعة 4 (تتبع الخطأ)
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    print('DEBUG: SalesInvoicesScreen - _deleteInvoice called for invoice: ${invoice.invoiceNumber}'); // ⭐ الطباعة 5
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
      try {
        await invoice.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الفاتورة بنجاح!')),
        );
        print('DEBUG: SalesInvoicesScreen - Invoice ${invoice.invoiceNumber} deleted successfully.'); // ⭐ الطباعة 6
      } catch (e, stacktrace) {
        print('ERROR: SalesInvoicesScreen - Failed to delete invoice ${invoice.invoiceNumber}: $e'); // ⭐ الطباعة 7 (خطأ)
        print('STACKTRACE: $stacktrace'); // ⭐ الطباعة 8 (تتبع الخطأ)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الفاتورة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: SalesInvoicesScreen - build method called.'); // ⭐ الطباعة 9
    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير المبيعات'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Invoice>>(
        valueListenable: invoicesBox.listenable(),
        builder: (context, box, _) {
          print('DEBUG: ValueListenableBuilder - builder function started.'); // ⭐ الطباعة 10
          List<Invoice> salesInvoices = [];
          try {
            salesInvoices = box.values
                .where((invoice) {
                  print('DEBUG: Filtering invoice ${invoice.invoiceNumber} with type ${invoice.type}. Expected: ${InvoiceType.sale}'); // ⭐ الطباعة 11
                  return invoice.type == InvoiceType.sale;
                })
                .toList()
                .cast<Invoice>();
            print('DEBUG: ValueListenableBuilder - Filtered ${salesInvoices.length} sales invoices.'); // ⭐ الطباعة 12
          } catch (e, stacktrace) {
            print('ERROR: ValueListenableBuilder - Failed to filter invoices: $e'); // ⭐ الطباعة 13 (خطأ)
            print('STACKTRACE: $stacktrace'); // ⭐ الطباعة 14 (تتبع الخطأ)
            return const Center(child: Text('حدث خطأ أثناء تحميل الفواتير.')); // ⭐ رسالة خطأ للمستخدم
          }

          if (salesInvoices.isEmpty) {
            print('DEBUG: SalesInvoicesScreen - salesInvoices is empty. Displaying empty message.'); // ⭐ الطباعة 15
            return const Center(
              child: Text('لا توجد فواتير مبيعات حتى الآن.'),
            );
          }

          print('DEBUG: SalesInvoicesScreen - salesInvoices is NOT empty. Building ListView.'); // ⭐ الطباعة 16
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: salesInvoices.length,
            itemBuilder: (context, index) {
              final invoice = salesInvoices[index];
              print('DEBUG: Building item for invoice number: ${invoice.invoiceNumber}, index: $index'); // ⭐ الطباعة 17

              double total = 0.0;
              try {
                total = invoice.items.fold(0.0, (sum, item) {
                  // ⭐ الطباعة 18: تحقق من قيم الصنف قبل الحساب
                  print('DEBUG: Calculating total for item: ${item.itemName}, qty: ${item.quantity}, price: ${item.sellingPrice}');
                  return sum + (item.quantity * item.sellingPrice);
                });
                print('DEBUG: Total for invoice ${invoice.invoiceNumber} calculated: $total'); // ⭐ الطباعة 19
              } catch (e, stacktrace) {
                print('ERROR: SalesInvoicesScreen - Failed to calculate total for invoice ${invoice.invoiceNumber}: $e'); // ⭐ الطباعة 20 (خطأ)
                print('STACKTRACE: $stacktrace'); // ⭐ الطباعة 21 (تتبع الخطأ)
                return Card(child: ListTile(title: Text('خطأ في فاتورة رقم ${invoice.invoiceNumber}'))); // ⭐ رسالة خطأ للعنصر
              }

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
                      // التعامل مع العملاء
                      Text(
                        'العميل: ${invoice.customerName ?? 'غير محدد'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'بنود الفاتورة:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      // ⭐ الطباعة 22: تحقق من بنود الفاتورة
                      ...invoice.items.map((item) {
                        if (item == null) {
                          print('ERROR: Found null item in invoice ${invoice.invoiceNumber} items list!'); // ⭐ الطباعة 23
                          return const Text('صنف غير صالح');
                        }
                        return Text(
                          '${item.itemName} (${item.quantity} ${item.unit} x ${numberFormat.format(item.sellingPrice)})',
                        );
                      }).toList(),
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
                              print('DEBUG: Navigating to AddEditInvoiceScreen for invoice: ${invoice.invoiceNumber}'); // ⭐ الطباعة 24
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
          print('DEBUG: Navigating to AddEditInvoiceScreen to add new invoice.'); // ⭐ الطباعة 25
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
