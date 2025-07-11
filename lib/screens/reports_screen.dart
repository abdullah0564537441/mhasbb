// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ⭐⭐ تم إضافة هذا الاستيراد
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/return_invoice.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/screens/placeholder_screen.dart'; // ⭐⭐ تم إضافة هذا الاستيراد

// ⭐⭐ تحديث enum ReportType
enum ReportType { sales, purchases, inventory, returns, vouchers }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _selectedReportType = ReportType.sales; // التقرير الافتراضي
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox;
  late Box<ReturnInvoice> returnsBox;
  late Box<Voucher> vouchersBox;

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    returnsBox = Hive.box<ReturnInvoice>('return_invoices_box');
    vouchersBox = Hive.box<Voucher>('vouchers_box');
  }

  // --- دوال اختيار التاريخ ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  // --- تقرير المبيعات ---
  List<Invoice> _generateSalesReport() {
    return invoicesBox.values
        .where((invoice) =>
            invoice.type == InvoiceType.sale &&
            invoice.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            invoice.date.isBefore(_endDate.add(const Duration(days: 1))))
        .toList()
        .cast<Invoice>()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- تقرير المشتريات ---
  List<Invoice> _generatePurchaseReport() {
    return invoicesBox.values
        .where((invoice) =>
            invoice.type == InvoiceType.purchase &&
            invoice.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            invoice.date.isBefore(_endDate.add(const Duration(days: 1))))
        .toList()
        .cast<Invoice>()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- تقرير المخزون ---
  List<Item> _generateInventoryReport() {
    return itemsBox.values.toList().cast<Item>()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ⭐⭐ تقرير المرتجعات
  List<ReturnInvoice> _generateReturnsReport() {
    return returnsBox.values
        .where((returnsInvoice) =>
            returnsInvoice.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            returnsInvoice.date.isBefore(_endDate.add(const Duration(days: 1))))
        .toList()
        .cast<ReturnInvoice>()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ⭐⭐ تقرير السندات (صرف وقبض)
  List<Voucher> _generateVouchersReport() {
    return vouchersBox.values
        .where((voucher) =>
            voucher.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            voucher.date.isBefore(_endDate.add(const Duration(days: 1))))
        .toList()
        .cast<Voucher>()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- بناء واجهة عرض التقرير المختار ---
  Widget _buildReportContent() {
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    if (_selectedReportType == ReportType.sales) {
      final salesInvoices = _generateSalesReport();
      double totalSales = salesInvoices.fold(
          0.0,
          (sum, invoice) => sum +
              invoice.items.fold(
                  0.0, (itemSum, item) => itemSum + (item.quantity * item.sellingPrice)));

      if (salesInvoices.isEmpty) {
        return const Center(child: Text('لا توجد مبيعات في الفترة المحددة.'));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'إجمالي المبيعات: ${numberFormat.format(totalSales)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: salesInvoices.length,
              itemBuilder: (context, index) {
                final invoice = salesInvoices[index];
                final invoiceTotal = invoice.items.fold(
                    0.0, (sum, item) => sum + (item.quantity * item.sellingPrice));
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الفاتورة: ${invoice.invoiceNumber}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                        Text('العميل: ${invoice.customerName ?? 'غير محدد'}'),
                        const SizedBox(height: 5),
                        Text('الإجمالي: ${numberFormat.format(invoiceTotal)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (_selectedReportType == ReportType.purchases) {
      final purchaseInvoices = _generatePurchaseReport();
      double totalPurchases = purchaseInvoices.fold(
          0.0,
          (sum, invoice) => sum +
              invoice.items.fold(
                  0.0, (itemSum, item) => itemSum + (item.quantity * item.purchasePrice)));

      if (purchaseInvoices.isEmpty) {
        return const Center(child: Text('لا توجد مشتريات في الفترة المحددة.'));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'إجمالي المشتريات: ${numberFormat.format(totalPurchases)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: purchaseInvoices.length,
              itemBuilder: (context, index) {
                final invoice = purchaseInvoices[index];
                final invoiceTotal = invoice.items.fold(
                    0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الفاتورة: ${invoice.invoiceNumber}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                        Text('المورد: ${invoice.supplierName ?? 'غير محدد'}'),
                        const SizedBox(height: 5),
                        Text('الإجمالي: ${numberFormat.format(invoiceTotal)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (_selectedReportType == ReportType.inventory) {
      final inventoryItems = _generateInventoryReport();
      double totalInventoryValue = inventoryItems.fold(
          0.0, (sum, item) => sum + (item.quantity * item.purchasePrice));

      if (inventoryItems.isEmpty) {
        return const Center(child: Text('المخزون فارغ.'));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'القيمة الإجمالية للمخزون: ${numberFormat.format(totalInventoryValue)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: inventoryItems.length,
              itemBuilder: (context, index) {
                final item = inventoryItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الصنف: ${item.name}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('الكمية المتوفرة: ${numberFormat.format(item.quantity)} ${item.unit}'),
                        Text('سعر الشراء: ${numberFormat.format(item.purchasePrice)}'),
                        Text('سعر البيع: ${numberFormat.format(item.sellingPrice)}'),
                        Text('القيمة في المخزون: ${numberFormat.format(item.quantity * item.purchasePrice)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    // ⭐⭐ واجهة تقرير المرتجعات
    else if (_selectedReportType == ReportType.returns) {
      final returnsInvoices = _generateReturnsReport();
      double totalReturnsValue = returnsInvoices.fold(
          0.0,
          (sum, returnInvoice) => sum +
              returnInvoice.items.fold(
                  0.0, (itemSum, item) => itemSum + (item.quantity * item.sellingPrice))); // افترض استخدام sellingPrice للمرتجعات

      if (returnsInvoices.isEmpty) {
        return const Center(child: Text('لا توجد مرتجعات في الفترة المحددة.'));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'إجمالي قيمة المرتجعات: ${numberFormat.format(totalReturnsValue)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.orange),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: returnsInvoices.length,
              itemBuilder: (context, index) {
                final returnsInvoice = returnsInvoices[index];
                final invoiceTotal = returnsInvoice.items.fold(
                    0.0, (sum, item) => sum + (item.quantity * item.sellingPrice)); // تأكد من الحساب الصحيح
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم فاتورة المرتجع: ${returnsInvoice.returnNumber}', // ⭐⭐ تم التعديل هنا
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(returnsInvoice.date)}'),
                        Text('العميل/المورد: ${returnsInvoice.customerName ?? returnsInvoice.supplierName ?? 'غير محدد'}'),
                        const SizedBox(height: 5),
                        Text('الإجمالي: ${numberFormat.format(invoiceTotal)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    // ⭐⭐ واجهة تقرير السندات
    else if (_selectedReportType == ReportType.vouchers) {
      final vouchers = _generateVouchersReport();
      double totalReceipts = vouchers.where((v) => v.type == VoucherType.income).fold(0.0, (sum, v) => sum + v.amount); // ⭐⭐ تم التعديل هنا
      double totalPayments = vouchers.where((v) => v.type == VoucherType.expense).fold(0.0, (sum, v) => sum + v.amount); // ⭐⭐ تم التعديل هنا
      double netBalance = totalReceipts - totalPayments;

      if (vouchers.isEmpty) {
        return const Center(child: Text('لا توجد سندات في الفترة المحددة.'));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'إجمالي سندات القبض: ${numberFormat.format(totalReceipts)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
                ),
                Text(
                  'إجمالي سندات الصرف: ${numberFormat.format(totalPayments)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
                ),
                Text(
                  'الرصيد الصافي: ${numberFormat.format(netBalance)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: netBalance >= 0 ? Colors.blue : Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم السند: ${voucher.voucherNumber}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(voucher.date)}'),
                        Text('النوع: ${voucher.type == VoucherType.income ? 'قبض' : 'صرف'}', // ⭐⭐ تم التعديل هنا
                            style: TextStyle(color: voucher.type == VoucherType.income ? Colors.green : Colors.red)), // ⭐⭐ تم التعديل هنا
                        Text('المبلغ: ${numberFormat.format(voucher.amount)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('البيان: ${voucher.description}', // تم إزالة ?? 'لا يوجد' لتجنب مشاكل إذا كان nullable في الموديل
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return const Center(child: Text('اختر نوع التقرير لعرض البيانات.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<ReportType>(
                  decoration: const InputDecoration(
                    labelText: 'اختر التقرير',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedReportType,
                  onChanged: (ReportType? newValue) {
                    setState(() {
                      _selectedReportType = newValue!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ReportType.sales,
                      child: Text('تقرير المبيعات'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.purchases,
                      child: Text('تقرير المشتريات'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.inventory,
                      child: Text('تقرير المخزون'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.returns,
                      child: Text('تقرير المرتجعات'),
                    ),
                    DropdownMenuItem(
                      value: ReportType.vouchers,
                      child: Text('تقرير السندات'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedReportType != ReportType.inventory)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'من تاريخ',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'إلى تاريخ',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('تحديث التقرير'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder<Box>(
              valueListenable: _getSelectedBoxListenables(),
              builder: (context, box, _) {
                return _buildReportContent();
              },
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لتحديد الصندوق الذي يجب الاستماع إليه
  ValueListenable _getSelectedBoxListenables() {
    switch (_selectedReportType) {
      case ReportType.sales:
      case ReportType.purchases:
        return invoicesBox.listenable();
      case ReportType.inventory:
        return itemsBox.listenable();
      case ReportType.returns:
        return returnsBox.listenable();
      case ReportType.vouchers:
        return vouchersBox.listenable();
      default:
        return invoicesBox.listenable();
    }
  }
}
