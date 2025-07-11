// lib/screens/account_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ والعملة
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/return_invoice.dart';
import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/invoice_type.dart';
import 'package:mhasbb/models/voucher_type.dart';

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPartyType; // 'Customer' أو 'Supplier' أو 'All'
  String? _selectedPartyId; // معرف العميل أو المورد المحدد

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    final customerBox = Hive.box<Customer>('customers_box');
    final supplierBox = Hive.box<Supplier>('suppliers_box');
    setState(() {
      _customers = customerBox.values.toList();
      _suppliers = supplierBox.values.toList();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // دالة لتصفية وجلب الحركات
  List<Map<String, dynamic>> _getFilteredTransactions() {
    final invoiceBox = Hive.box<Invoice>('invoices_box');
    final returnInvoiceBox = Hive.box<ReturnInvoice>('return_invoices_box');
    final voucherBox = Hive.box<Voucher>('vouchers_box');

    List<Map<String, dynamic>> transactions = [];

    // جلب الفواتير (مبيعات ومشتريات)
    for (var invoice in invoiceBox.values) {
      if ((_startDate == null || invoice.date.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null || invoice.date.isBefore(_endDate!.add(const Duration(days: 1))))) {

        bool matchesParty = false;
        if (_selectedPartyType == 'Customer' && invoice.type == InvoiceType.sale && invoice.customerId == _selectedPartyId) {
          matchesParty = true;
        } else if (_selectedPartyType == 'Supplier' && invoice.type == InvoiceType.purchase && invoice.supplierId == _selectedPartyId) {
          matchesParty = true;
        } else if (_selectedPartyType == 'All' || _selectedPartyType == null) {
          matchesParty = true; // إذا لم يتم تحديد طرف معين
        }

        if (matchesParty &&
            ((_selectedPartyType == 'Customer' && invoice.type == InvoiceType.sale) ||
             (_selectedPartyType == 'Supplier' && invoice.type == InvoiceType.purchase) ||
             _selectedPartyType == null || _selectedPartyType == 'All')) { // إضافة شرط التحقق من نوع الفاتورة عند تصفية 'الكل'
          transactions.add({
            'date': invoice.date,
            'description': (invoice.type == InvoiceType.sale)
                ? 'فاتورة مبيعات رقم ${invoice.invoiceNumber}'
                : 'فاتورة مشتريات رقم ${invoice.invoiceNumber}',
            'type': (invoice.type == InvoiceType.sale) ? 'Sale' : 'Purchase',
            'amount': invoice.totalAmount,
            'partyName': (invoice.type == InvoiceType.sale) ? invoice.customerName : invoice.supplierName,
            'isDebit': (invoice.type == InvoiceType.sale), // المبيعات دائنة (على العميل)، المشتريات مدينة (علينا)
          });
        }
      }
    }

    // جلب المرتجعات (مرتجع مبيعات ومرتجع مشتريات)
    for (var returnInvoice in returnInvoiceBox.values) {
      if ((_startDate == null || returnInvoice.date.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null || returnInvoice.date.isBefore(_endDate!.add(const Duration(days: 1))))) {

        bool matchesParty = false;
        if (_selectedPartyType == 'Customer' && returnInvoice.originalInvoiceType == InvoiceType.salesReturn && returnInvoice.customerName == _customers.firstWhere((c) => c.id == _selectedPartyId, orElse: () => Customer(id: '', name: '')).name) { // البحث بالاسم هنا
          matchesParty = true;
        } else if (_selectedPartyType == 'Supplier' && returnInvoice.originalInvoiceType == InvoiceType.purchaseReturn && returnInvoice.supplierName == _suppliers.firstWhere((s) => s.id == _selectedPartyId, orElse: () => Supplier(id: '', name: '')).name) { // البحث بالاسم هنا
          matchesParty = true;
        } else if (_selectedPartyType == 'All' || _selectedPartyType == null) {
          matchesParty = true;
        }

        if (matchesParty &&
            ((_selectedPartyType == 'Customer' && returnInvoice.originalInvoiceType == InvoiceType.salesReturn) ||
             (_selectedPartyType == 'Supplier' && returnInvoice.originalInvoiceType == InvoiceType.purchaseReturn) ||
             _selectedPartyType == null || _selectedPartyType == 'All')) {
          transactions.add({
            'date': returnInvoice.date,
            'description': (returnInvoice.originalInvoiceType == InvoiceType.salesReturn)
                ? 'مرتجع مبيعات رقم ${returnInvoice.returnNumber}'
                : 'مرتجع مشتريات رقم ${returnInvoice.returnNumber}',
            'type': (returnInvoice.originalInvoiceType == InvoiceType.salesReturn) ? 'SalesReturn' : 'PurchaseReturn',
            'amount': returnInvoice.totalAmount,
            'partyName': (returnInvoice.originalInvoiceType == InvoiceType.salesReturn) ? returnInvoice.customerName : returnInvoice.supplierName,
            'isDebit': (returnInvoice.originalInvoiceType == InvoiceType.purchaseReturn), // مرتجع المشتريات دائن (علينا)، مرتجع المبيعات مدين (للعميل)
          });
        }
      }
    }


    // جلب السندات (قبض وصرف)
    for (var voucher in voucherBox.values) {
      if ((_startDate == null || voucher.date.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null || voucher.date.isBefore(_endDate!.add(const Duration(days: 1))))) {

        bool matchesParty = false;
        if (_selectedPartyType == 'Customer' && voucher.partyType == 'Customer' && voucher.partyId == _selectedPartyId) {
          matchesParty = true;
        } else if (_selectedPartyType == 'Supplier' && voucher.partyType == 'Supplier' && voucher.partyId == _selectedPartyId) {
          matchesParty = true;
        } else if (_selectedPartyType == 'All' || _selectedPartyType == null) {
          matchesParty = true;
        }

        if (matchesParty) {
          transactions.add({
            'date': voucher.date,
            'description': (voucher.type == VoucherType.receipt)
                ? 'سند قبض رقم ${voucher.voucherNumber}'
                : 'سند صرف رقم ${voucher.voucherNumber}',
            'type': (voucher.type == VoucherType.receipt) ? 'Receipt' : 'Payment',
            'amount': voucher.amount,
            'partyName': voucher.partyName,
            'isDebit': (voucher.type == VoucherType.payment), // سند الصرف مدين، سند القبض دائن
          });
        }
      }
    }

    // فرز الحركات حسب التاريخ
    transactions.sort((a, b) => a['date'].compareTo(b['date']));

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> transactions = _getFilteredTransactions();

    // حساب الرصيد الافتتاحي
    double openingBalance = 0.0;
    // (هنا يمكن إضافة منطق لحساب رصيد افتتاحي من حركات سابقة إن وجد)
    // حالياً، سنبدأ من الصفر

    // حساب الرصيد الحالي
    double currentBalance = openingBalance;
    for (var t in transactions) {
      if (t['isDebit']) {
        currentBalance += t['amount']; // مدين: يزيد الرصيد المستحق لنا أو يقل الرصيد المستحق علينا
      } else {
        currentBalance -= t['amount']; // دائن: يقل الرصيد المستحق لنا أو يزيد الرصيد المستحق علينا
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحساب'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // اختيار نوع الطرف (عميل / مورد / الكل)
                DropdownButtonFormField<String>(
                  value: _selectedPartyType,
                  hint: const Text('اختر نوع الطرف'),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPartyType = newValue;
                      _selectedPartyId = null; // إعادة تعيين الطرف عند تغيير النوع
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('الكل')),
                    DropdownMenuItem(value: 'Customer', child: Text('عميل')),
                    DropdownMenuItem(value: 'Supplier', child: Text('مورد')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'نوع الطرف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // اختيار الطرف (عميل أو مورد محدد)
                if (_selectedPartyType == 'Customer' || _selectedPartyType == 'Supplier')
                  DropdownButtonFormField<String>(
                    value: _selectedPartyId,
                    hint: Text('اختر ${_selectedPartyType == 'Customer' ? 'العميل' : 'المورد'}'),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPartyId = newValue;
                      });
                    },
                    items: (_selectedPartyType == 'Customer' ? _customers : _suppliers)
                        .map((party) => DropdownMenuItem(
                              value: party.id,
                              child: Text(party.name),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: (_selectedPartyType == 'Customer' ? 'العميل' : 'المورد'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 10),

                // تحديد نطاق التاريخ
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'من تاريخ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _startDate == null
                                ? 'اختر تاريخ البداية'
                                : DateFormat('yyyy-MM-dd').format(_startDate!),
                          ),
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
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _endDate == null
                                ? 'اختر تاريخ النهاية'
                                : DateFormat('yyyy-MM-dd').format(_endDate!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // تحديث الـ UI بناءً على الفلاتر الجديدة
                    });
                  },
                  child: const Text('تطبيق الفلاتر'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الرصيد الافتتاحي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(openingBalance)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'الرصيد الحالي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(currentBalance)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentBalance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('لا توجد حركات لعرضها بالفلاتر المحددة.'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      // تحديد لون النص ونوع الحركة (مدين/دائن)
                      Color textColor = transaction['isDebit'] ? Colors.green.shade700 : Colors.red.shade700;
                      String debitCreditLabel = transaction['isDebit'] ? 'مدين' : 'دائن';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(transaction['date']),
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                transaction['description'],
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (transaction['partyName'] != null && transaction['partyName'].isNotEmpty)
                                Text(
                                  'الطرف: ${transaction['partyName']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(transaction['amount'])} ($debitCreditLabel)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
