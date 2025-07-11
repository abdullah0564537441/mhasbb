// lib/screens/returns_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // لاستخدام ValueListenableBuilder
import 'package:intl/intl.dart'; // لتنسيق التاريخ والأرقام

import 'package:mhasbb/models/return_invoice.dart'; // استيراد موديل المرتجع
import 'package:mhasbb/screens/add_edit_return_invoice_screen.dart'; // استيراد شاشة الإضافة/التعديل
import 'package:mhasbb/models/invoice_type.dart'; // ⭐⭐ مهم: استيراد InvoiceType ⭐⭐

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  // للبحث
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المرتجعات'),
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
                hintText: 'البحث برقم المرتجع أو اسم العميل/المورد',
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
        valueListenable: Hive.box<ReturnInvoice>('return_invoices_box').listenable(),
        builder: (context, Box<ReturnInvoice> box, _) {
          final allReturns = box.values.toList();

          // تصفية المرتجعات بناءً على البحث
          final filteredReturns = allReturns.where((ret) {
            final returnNumberLower = ret.returnNumber.toLowerCase();
            final customerNameLower = ret.customerName?.toLowerCase() ?? '';
            final supplierNameLower = ret.supplierName?.toLowerCase() ?? '';

            return returnNumberLower.contains(_searchQuery) ||
                   customerNameLower.contains(_searchQuery) ||
                   supplierNameLower.contains(_searchQuery);
          }).toList();

          if (filteredReturns.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'لا توجد مرتجعات مسجلة حتى الآن.'
                    : 'لا توجد مرتجعات مطابقة لبحثك.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // فرز المرتجعات من الأحدث إلى الأقدم
          filteredReturns.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredReturns.length,
            itemBuilder: (context, index) {
              final returnInvoice = filteredReturns[index];
              // ⭐⭐ تم التأكد من وجود InvoiceType هنا ⭐⭐
              final isSalesReturn = returnInvoice.originalInvoiceType == InvoiceType.salesReturn;
              final partyName = isSalesReturn ? returnInvoice.customerName : returnInvoice.supplierName;
              final returnTypeLabel = isSalesReturn ? 'مرتجع مبيعات' : 'مرتجع مشتريات';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () async {
                    // للتعديل على مرتجع موجود
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditReturnInvoiceScreen(
                          returnInvoice: returnInvoice, // ⭐⭐ تم التأكد من تمرير ReturnInvoice ⭐⭐
                        ),
                      ),
                    );
                    setState(() {}); // لتحديث القائمة بعد التعديل
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
                              '$returnTypeLabel - رقم: ${returnInvoice.returnNumber}',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColor),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(returnInvoice.date),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (partyName != null && partyName.isNotEmpty)
                          Text(
                            isSalesReturn ? 'العميل: $partyName' : 'المورد: $partyName',
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الإجمالي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(returnInvoice.totalAmount)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDeleteReturn(context, returnInvoice);
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
          // للانتقال إلى شاشة إضافة مرتجع جديد
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditReturnInvoiceScreen(),
            ),
          );
          setState(() {}); // لتحديث القائمة بعد إضافة مرتجع جديد
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // دالة لتأكيد الحذف
  void _confirmDeleteReturn(BuildContext context, ReturnInvoice returnInvoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المرتجع'),
        content: Text('هل أنت متأكد أنك تريد حذف المرتجع رقم ${returnInvoice.returnNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await returnInvoice.delete(); // حذف المرتجع من Hive
              if (mounted) {
                Navigator.pop(context); // إغلاق مربع الحوار
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المرتجع بنجاح')),
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
