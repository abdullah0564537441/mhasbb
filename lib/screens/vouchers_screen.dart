// lib/screens/vouchers_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // لتوليد ID فريد

import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/screens/add_edit_voucher_screen.dart'; // ⭐⭐ سنضيف هذه الشاشة لاحقاً

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  late Box<Voucher> vouchersBox;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    vouchersBox = Hive.box<Voucher>('vouchers_box');
  }

  Future<void> _deleteVoucher(String voucherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا السند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vouchersBox.delete(voucherId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السند بنجاح.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سندات الصرف والقبض'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Voucher>>(
        valueListenable: vouchersBox.listenable(),
        builder: (context, box, _) {
          final vouchers = box.values.toList().cast<Voucher>();
          vouchers.sort((a, b) => b.date.compareTo(a.date)); // فرز حسب التاريخ الأحدث أولاً

          if (vouchers.isEmpty) {
            return const Center(
              child: Text('لا توجد سندات صرف أو قبض مدخلة حتى الآن.', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              final isExpense = voucher.type == VoucherType.expense;
              final numberFormat = NumberFormat('#,##0.00', 'en_US');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isExpense ? Colors.red[300]! : Colors.green[300]!,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditVoucherScreen(voucher: voucher),
                      ),
                    );
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
                              isExpense ? 'سند صرف' : 'سند قبض',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isExpense ? Colors.red[700] : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'رقم: ${voucher.voucherNumber}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المبلغ: ${numberFormat.format(voucher.amount)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: isExpense ? Colors.red[600] : Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(voucher.date)}'),
                        Text('البيان: ${voucher.description}'),
                        if (voucher.relatedPartyName != null && voucher.relatedPartyName!.isNotEmpty)
                          Text('الطرف: ${voucher.relatedPartyName}'),
                        Text('طريقة الدفع: ${voucher.paymentMethod}'),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteVoucher(voucher.id),
                          ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditVoucherScreen(voucher: null)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
