// lib/screens/vouchers_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/screens/add_edit_voucher_screen.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السندات'),
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
                hintText: 'البحث برقم السند أو الوصف أو الطرف',
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
        valueListenable: Hive.box<Voucher>('vouchers_box').listenable(),
        builder: (context, Box<Voucher> box, _) {
          final allVouchers = box.values.toList();

          final filteredVouchers = allVouchers.where((voucher) {
            final voucherNumberLower = voucher.voucherNumber.toLowerCase();
            final descriptionLower = voucher.description?.toLowerCase() ?? '';
            final partyNameLower = voucher.partyName?.toLowerCase() ?? '';

            return voucherNumberLower.contains(_searchQuery) ||
                   descriptionLower.contains(_searchQuery) ||
                   partyNameLower.contains(_searchQuery);
          }).toList();

          if (filteredVouchers.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'لا توجد سندات مسجلة حتى الآن.'
                    : 'لا توجد سندات مطابقة لبحثك.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          filteredVouchers.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredVouchers.length,
            itemBuilder: (context, index) {
              final voucher = filteredVouchers[index];
              final isReceipt = voucher.type == VoucherType.receipt;
              final voucherTypeLabel = isReceipt ? 'سند قبض' : 'سند صرف';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditVoucherScreen(
                          voucher: voucher,
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
                              '$voucherTypeLabel - رقم: ${voucher.voucherNumber}',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColor),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(voucher.date),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('البيان: ${voucher.description ?? 'لا يوجد بيان'}'), // ⭐⭐ تم التصحيح هنا ⭐⭐
                        if (voucher.partyName != null && voucher.partyName!.isNotEmpty) // ⭐⭐ تم التصحيح هنا ⭐⭐
                          Text('الطرف: ${voucher.partyName}'), // ⭐⭐ تم التصحيح هنا ⭐⭐
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المبلغ: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(voucher.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isReceipt ? Colors.green : Colors.red,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDeleteVoucher(context, voucher);
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
              builder: (context) => const AddEditVoucherScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteVoucher(BuildContext context, Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السند'),
        content: Text('هل أنت متأكد أنك تريد حذف السند رقم ${voucher.voucherNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await voucher.delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف السند بنجاح')),
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
