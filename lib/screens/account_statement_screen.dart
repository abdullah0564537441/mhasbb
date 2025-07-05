// lib/screens/account_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_type.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';

// كلاس مساعد لتمثيل صف في كشف الحساب
// هذا ليس HiveType ولن يتم تخزينه في Hive مباشرة
enum TransactionType { debit, credit } // debit: مدين (لك)، credit: دائن (عليك)

class AccountStatementEntry {
  final DateTime date;
  final String description;
  final double debitAmount;  // المبلغ الذي زاد على العميل/المورد (يعني العميل/المورد مدين لك)
  final double creditAmount; // المبلغ الذي نقص من العميل/المورد (يعني العميل/المورد دائن لك)
  final double runningBalance; // الرصيد بعد هذه الحركة
  final String? relatedInvoiceId; // لربط الحركة بالفاتورة الأصلية

  AccountStatementEntry({
    required this.date,
    required this.description,
    this.debitAmount = 0.0,
    this.creditAmount = 0.0,
    required this.runningBalance,
    this.relatedInvoiceId,
  });
}

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  late Box<Invoice> invoicesBox;
  late Box<Customer> customersBox;
  late Box<Supplier> suppliersBox;

  String? _selectedPartyId; // ID للعميل أو المورد المختار
  String? _selectedPartyName; // اسم العميل أو المورد المختار
  bool _isCustomerSelected = true; // لتحديد ما إذا كان الاختيار عميل أم مورد

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    customersBox = Hive.box<Customer>('customers_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box');
    _initializeSelection();
  }

  void _initializeSelection() {
    if (customersBox.isNotEmpty) {
      _selectedPartyId = customersBox.values.first.id;
      _selectedPartyName = customersBox.values.first.name;
      _isCustomerSelected = true;
    } else if (suppliersBox.isNotEmpty) {
      _selectedPartyId = suppliersBox.values.first.id;
      _selectedPartyName = suppliersBox.values.first.name;
      _isCustomerSelected = false;
    }
  }

  List<AccountStatementEntry> _generateAccountStatement() {
    if (_selectedPartyId == null) {
      return [];
    }

    final List<Invoice> relevantInvoices;
    if (_isCustomerSelected) {
      relevantInvoices = invoicesBox.values
          .where((inv) => inv.customerId == _selectedPartyId)
          .toList();
    } else {
      relevantInvoices = invoicesBox.values
          .where((inv) => inv.supplierId == _selectedPartyId)
          .toList();
    }

    // فرز الفواتير حسب التاريخ لضمان تسلسل الرصيد الصحيح
    relevantInvoices.sort((a, b) => a.date.compareTo(b.date));

    List<AccountStatementEntry> statementEntries = [];
    double currentBalance = 0.0; // الرصيد التراكمي

    for (var invoice in relevantInvoices) {
      double totalInvoiceAmount = invoice.items.fold(0.0, (sum, item) {
        if (invoice.type == InvoiceType.sale) {
          return sum + (item.quantity * item.sellingPrice);
        } else if (invoice.type == InvoiceType.purchase) {
          // يمكن أن نستخدم سعر الشراء هنا أو نفس سعر البيع اعتمادًا على طريقة الحساب
          // للاحتفاظ بالبساطة في كشف الحساب، نستخدم إجمالي الفاتورة المدفوعة/المستحقة
          return sum + (item.quantity * item.purchasePrice); // أو sellingPrice إذا كانت فواتير الشراء تسجل بالسعر النهائي
        }
        return sum;
      });

      String description;
      double debit = 0.0;
      double credit = 0.0;

      if (invoice.type == InvoiceType.sale) {
        // فاتورة بيع: العميل مدين لك، المبلغ يزيد رصيد العميل لديك (يعني العميل عليه فلوس)
        debit = totalInvoiceAmount;
        currentBalance += totalInvoiceAmount;
        description = 'فاتورة مبيعات رقم ${invoice.invoiceNumber}';
      } else if (invoice.type == InvoiceType.purchase) {
        // فاتورة شراء: أنت مدين للمورد، المبلغ يزيد رصيد المورد عليك (يعني أنت عليك فلوس للمورد)
        credit = totalInvoiceAmount;
        currentBalance -= totalInvoiceAmount;
        description = 'فاتورة مشتريات رقم ${invoice.invoiceNumber}';
      } else {
        // أنواع فواتير أخرى إذا كانت موجودة (مثلاً مرتجع بيع، مرتجع شراء)
        description = 'حركة غير معروفة: ${invoice.invoiceNumber}';
      }

      statementEntries.add(
        AccountStatementEntry(
          date: invoice.date,
          description: description,
          debitAmount: debit,
          creditAmount: credit,
          runningBalance: currentBalance,
          relatedInvoiceId: invoice.id,
        ),
      );
    }
    return statementEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحساب'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'اختر نوع الطرف',
                      border: OutlineInputBorder(),
                    ),
                    value: _isCustomerSelected ? 'customer' : 'supplier',
                    onChanged: (value) {
                      setState(() {
                        _isCustomerSelected = (value == 'customer');
                        _selectedPartyId = null; // إعادة تعيين الاختيار عند تغيير النوع
                        _selectedPartyName = null;
                        // حاول اختيار أول عميل أو مورد بناءً على النوع الجديد
                        if (_isCustomerSelected && customersBox.isNotEmpty) {
                          _selectedPartyId = customersBox.values.first.id;
                          _selectedPartyName = customersBox.values.first.name;
                        } else if (!_isCustomerSelected && suppliersBox.isNotEmpty) {
                          _selectedPartyId = suppliersBox.values.first.id;
                          _selectedPartyName = suppliersBox.values.first.name;
                        }
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'customer',
                        child: Text('العميل'),
                      ),
                      DropdownMenuItem(
                        value: 'supplier',
                        child: Text('المورد'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ValueListenableBuilder<Box>(
                    valueListenable: _isCustomerSelected ? customersBox.listenable() : suppliersBox.listenable(),
                    builder: (context, box, _) {
                      final List<dynamic> parties = _isCustomerSelected
                          ? box.values.cast<Customer>().toList()
                          : box.values.cast<Supplier>().toList();

                      // إذا لم يتم اختيار طرف بعد أو الطرف المختار لم يعد موجودًا
                      if (_selectedPartyId == null || !parties.any((p) => p.id == _selectedPartyId)) {
                        if (parties.isNotEmpty) {
                          _selectedPartyId = parties.first.id;
                          _selectedPartyName = parties.first.name;
                        } else {
                          _selectedPartyId = null;
                          _selectedPartyName = null;
                        }
                      }

                      if (parties.isEmpty) {
                        return const DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'لا يوجد عملاء/موردين',
                            border: OutlineInputBorder(),
                          ),
                          items: [],
                          onChanged: null,
                          value: null,
                        );
                      }

                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'اختر العميل/المورد',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedPartyId,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedPartyId = newValue;
                            if (_isCustomerSelected) {
                              _selectedPartyName = customersBox.values.firstWhere((c) => c.id == newValue).name;
                            } else {
                              _selectedPartyName = suppliersBox.values.firstWhere((s) => s.id == newValue).name;
                            }
                          });
                        },
                        items: parties.map((party) {
                          return DropdownMenuItem<String>(
                            value: party.id,
                            child: Text(party.name),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedPartyId == null
                ? const Center(
                    child: Text('الرجاء اختيار عميل أو مورد لعرض كشف الحساب.'),
                  )
                : ValueListenableBuilder<Box<Invoice>>(
                    valueListenable: invoicesBox.listenable(),
                    builder: (context, box, _) {
                      final statementEntries = _generateAccountStatement();
                      final numberFormat = NumberFormat('#,##0.00', 'en_US');

                      if (statementEntries.isEmpty) {
                        return Center(
                          child: Text('لا توجد حركات لـ ${_selectedPartyName ?? "الطرف المختار"} حتى الآن.'),
                        );
                      }

                      // حساب الرصيد النهائي الإجمالي
                      final double finalBalance = statementEntries.last.runningBalance;

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: statementEntries.length,
                              itemBuilder: (context, index) {
                                final entry = statementEntries[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                                  elevation: 3.0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'التاريخ: ${DateFormat('yyyy-MM-dd').format(entry.date)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'البيان: ${entry.description}',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'مدين: ${numberFormat.format(entry.debitAmount)}',
                                                  style: TextStyle(
                                                    color: entry.debitAmount > 0 ? Colors.green[700] : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'دائن: ${numberFormat.format(entry.creditAmount)}',
                                                  style: TextStyle(
                                                    color: entry.creditAmount > 0 ? Colors.red[700] : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'الرصيد: ${numberFormat.format(entry.runningBalance)}',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: entry.runningBalance >= 0 ? Colors.blue : Colors.red,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // إجمالي الرصيد النهائي في الأسفل
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 5,
                              color: Theme.of(context).cardColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الرصيد النهائي:',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      numberFormat.format(finalBalance),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: finalBalance >= 0 ? Colors.blue : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
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
}
