// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// استيراد الموديلات الضرورية
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/return_invoice.dart';
import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/invoice_type.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/models/payment_method.dart'; // ⭐⭐ تم إضافة هذا الاستيراد هنا ⭐⭐

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المبيعات'),
            Tab(text: 'المشتريات'),
            Tab(text: 'السندات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SalesReportsTab(),
          _PurchaseReportsTab(),
          _VoucherReportsTab(),
        ],
      ),
    );
  }
}

// =========================================================================
// Sales Reports Tab
// =========================================================================
class _SalesReportsTab extends StatefulWidget {
  const _SalesReportsTab();

  @override
  State<_SalesReportsTab> createState() => _SalesReportsTabState();
}

class _SalesReportsTabState extends State<_SalesReportsTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateRangePicker(),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Invoice>('invoices_box').listenable(),
              builder: (context, Box<Invoice> box, _) {
                final salesInvoices = box.values.where((inv) => inv.type == InvoiceType.sale).toList();
                final filteredSales = salesInvoices.where((invoice) {
                  final invoiceDate = invoice.date;
                  return (_startDate == null || invoiceDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
                         (_endDate == null || invoiceDate.isBefore(_endDate!.add(const Duration(days: 1))));
                }).toList();

                if (filteredSales.isEmpty) {
                  return const Center(child: Text('لا توجد فواتير مبيعات لعرضها.'));
                }

                final totalSales = filteredSales.fold<double>(0.0, (sum, invoice) => sum + invoice.totalAmount);

                return Column(
                  children: [
                    Text(
                      'إجمالي المبيعات: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalSales)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredSales[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('فاتورة رقم: ${invoice.invoiceNumber}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('العميل: ${invoice.customerName ?? 'غير محدد'}'),
                                  Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                                  Text('طريقة الدفع: ${invoice.paymentMethod == PaymentMethod.cash ? 'نقدي' : 'آجل'}'),
                                ],
                              ),
                              trailing: Text(
                                NumberFormat.currency(symbol: '', decimalDigits: 2).format(invoice.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'من تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _startDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_startDate!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'إلى تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _endDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_endDate!),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
        ),
      ],
    );
  }
}

// =========================================================================
// Purchase Reports Tab
// =========================================================================
class _PurchaseReportsTab extends StatefulWidget {
  const _PurchaseReportsTab();

  @override
  State<_PurchaseReportsTab> createState() => _PurchaseReportsTabState();
}

class _PurchaseReportsTabState extends State<_PurchaseReportsTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateRangePicker(),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Invoice>('invoices_box').listenable(),
              builder: (context, Box<Invoice> box, _) {
                final purchaseInvoices = box.values.where((inv) => inv.type == InvoiceType.purchase).toList();
                final filteredPurchases = purchaseInvoices.where((invoice) {
                  final invoiceDate = invoice.date;
                  return (_startDate == null || invoiceDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
                         (_endDate == null || invoiceDate.isBefore(_endDate!.add(const Duration(days: 1))));
                }).toList();

                if (filteredPurchases.isEmpty) {
                  return const Center(child: Text('لا توجد فواتير مشتريات لعرضها.'));
                }

                final totalPurchases = filteredPurchases.fold<double>(0.0, (sum, invoice) => sum + invoice.totalAmount);

                return Column(
                  children: [
                    Text(
                      'إجمالي المشتريات: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalPurchases)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredPurchases.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredPurchases[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('فاتورة رقم: ${invoice.invoiceNumber}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('المورد: ${invoice.supplierName ?? 'غير محدد'}'),
                                  Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                                  Text('طريقة الدفع: ${invoice.paymentMethod == PaymentMethod.cash ? 'نقدي' : 'آجل'}'),
                                ],
                              ),
                              trailing: Text(
                                NumberFormat.currency(symbol: '', decimalDigits: 2).format(invoice.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'من تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _startDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_startDate!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'إلى تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _endDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_endDate!),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
        ),
      ],
    );
  }
}

// =========================================================================
// Voucher Reports Tab
// =========================================================================
class _VoucherReportsTab extends StatefulWidget {
  const _VoucherReportsTab();

  @override
  State<_VoucherReportsTab> createState() => _VoucherReportsTabState();
}

class _VoucherReportsTabState extends State<_VoucherReportsTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateRangePicker(),
          const SizedBox(height: 10),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Voucher>('vouchers_box').listenable(),
              builder: (context, Box<Voucher> box, _) {
                final allVouchers = box.values.toList();
                final filteredVouchers = allVouchers.where((voucher) {
                  final voucherDate = voucher.date;
                  return (_startDate == null || voucherDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
                         (_endDate == null || voucherDate.isBefore(_endDate!.add(const Duration(days: 1))));
                }).toList();

                if (filteredVouchers.isEmpty) {
                  return const Center(child: Text('لا توجد سندات لعرضها.'));
                }

                final totalReceipts = filteredVouchers.where((v) => v.type == VoucherType.receipt).fold<double>(0.0, (sum, v) => sum + v.amount);
                final totalPayments = filteredVouchers.where((v) => v.type == VoucherType.payment).fold<double>(0.0, (sum, v) => sum + v.amount);
                final netBalance = totalReceipts - totalPayments;

                return Column(
                  children: [
                    Text(
                      'إجمالي سندات القبض: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalReceipts)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'إجمالي سندات الصرف: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalPayments)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    Text(
                      'الرصيد الصافي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(netBalance)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.blue : Colors.deepOrange),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredVouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = filteredVouchers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text('${voucher.type == VoucherType.receipt ? 'سند قبض' : 'سند صرف'} رقم: ${voucher.voucherNumber}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(voucher.date)}'),
                                  Text('البيان: ${voucher.description ?? 'لا يوجد بيان'}'),
                                  if (voucher.partyName != null && voucher.partyName!.isNotEmpty)
                                    Text('الطرف: ${voucher.partyName}'),
                                  Text('طريقة الدفع: ${voucher.paymentMethod == PaymentMethod.cash ? 'نقدي' : 'شيك/تحويل'}'),
                                ],
                              ),
                              trailing: Text(
                                NumberFormat.currency(symbol: '', decimalDigits: 2).format(voucher.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: voucher.type == VoucherType.receipt ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'من تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _startDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_startDate!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _endDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'إلى تاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _endDate == null
                    ? 'اختر تاريخ'
                    : DateFormat('yyyy-MM-dd').format(_endDate!),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
        ),
      ],
    );
  }
}
