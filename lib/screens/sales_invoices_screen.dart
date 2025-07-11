// lib/screens/sales_invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_type.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/screens/add_edit_invoice_screen.dart';

class SalesInvoicesScreen extends StatefulWidget {
  const SalesInvoicesScreen({super.key});

  @override
  State<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends State<SalesInvoicesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير المبيعات'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث برقم الفاتورة أو اسم العميل',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                fillColor: Colors.white24,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Invoice>('invoices_box').listenable(),
        builder: (context, Box<Invoice> box, _) {
          final allSalesInvoices = box.values
              .where((invoice) => invoice.type == InvoiceType.sale)
              .toList();

          final filteredInvoices = allSalesInvoices.where((invoice) {
            final invoiceNumberLower = invoice.invoiceNumber.toLowerCase();
            final customerNameLower = invoice.customerName?.toLowerCase() ?? '';
            return invoiceNumberLower.contains(_searchQuery) ||
                   customerNameLower.contains(_searchQuery);
          }).toList();

          if (filteredInvoices.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'لا توجد فواتير مبيعات مسجلة حتى الآن.'
                    : 'لا توجد فواتير مبيعات مطابقة لبحثك.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          filteredInvoices.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredInvoices.length,
            itemBuilder: (context, index) {
              final invoice = filteredInvoices[index];
              final total = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.price)); // ⭐⭐ تم التصحيح هنا ⭐⭐
              final numberFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditInvoiceScreen(
                          invoice: invoice,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'فاتورة رقم: ${invoice.invoiceNumber}',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColor),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(invoice.date),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('العميل: ${invoice.customerName ?? 'غير محدد'}'),
                        Text('طريقة الدفع: ${invoice.paymentMethod == PaymentMethod.cash ? 'نقدي' : 'آجل'}'),
                        if (invoice.notes != null && invoice.notes!.isNotEmpty)
                          Text('ملاحظات: ${invoice.notes!}'),
                        const SizedBox(height: 8),
                        const Text('الأصناف:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...invoice.items.map((item) => Text(
                              '${item.itemName} (${item.quantity} ${item.unit} x ${numberFormat.format(item.price)})', // ⭐⭐ تم التصحيح هنا ⭐⭐
                              style: const TextStyle(fontSize: 14),
                            )).toList(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الإجمالي: ${numberFormat.format(total)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDeleteInvoice(context, invoice);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditInvoiceScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف فاتورة المبيعات'),
        content: Text('هل أنت متأكد أنك تريد حذف فاتورة المبيعات رقم ${invoice.invoiceNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await invoice.delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الفاتورة بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
