// lib/screens/add_edit_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/customer.dart';

class AddEditInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const AddEditInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid uuid = const Uuid();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _dateController;
  Customer? _selectedCustomer;
  final List<InvoiceItem> _invoiceItems = [];

  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox;
  late Box<Customer> customersBox;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    customersBox = Hive.box<Customer>('customers_box');

    if (widget.invoice == null) {
      // فاتورة جديدة
      _invoiceNumberController = TextEditingController(text: _generateNextInvoiceNumber());
      _selectedDate = DateTime.now();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    } else {
      // تعديل فاتورة موجودة
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _selectedDate = widget.invoice!.date; // ⭐ تم التعديل هنا: invoiceDate إلى date
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _invoiceItems.addAll(widget.invoice!.items); // تم إزالة final من 'items' في Invoice
      if (widget.invoice!.customerId != null) {
        _selectedCustomer = customersBox.get(widget.invoice!.customerId);
      }
    }
  }

  String _generateNextInvoiceNumber() {
    final allInvoices = invoicesBox.values.toList();
    final salesInvoices = allInvoices.where((inv) => inv.type == InvoiceType.sale).toList();
    if (salesInvoices.isEmpty) {
      return 'INV-0001';
    }
    // البحث عن أعلى رقم فاتورة مبيعات حالي
    int maxNumber = 0;
    for (var invoice in salesInvoices) {
      if (invoice.invoiceNumber.startsWith('INV-')) {
        try {
          int currentNumber = int.parse(invoice.invoiceNumber.substring(4));
          if (currentNumber > maxNumber) {
            maxNumber = currentNumber;
          }
        } catch (e) {
          // تجاهل الأخطاء إذا كان التنسيق غير صحيح
        }
      }
    }
    return 'INV-${(maxNumber + 1).toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  void _addInvoiceItem() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedItemName;
        double quantity = 1.0;
        double sellingPrice = 0.0; // سعر البيع لبند الفاتورة

        return AlertDialog(
          title: const Text('إضافة صنف للفاتورة'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'الصنف',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      value: selectedItemName,
                      items: itemsBox.values.map((item) {
                        return DropdownMenuItem(
                          value: item.name,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedItemName = value;
                          final selectedItem = itemsBox.values.firstWhere((item) => item.name == selectedItemName);
                          sellingPrice = selectedItem.sellingPrice; // ⭐ استخدام sellingPrice من موديل Item
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار صنف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: quantity.toString(),
                      onChanged: (value) {
                        quantity = double.tryParse(value) ?? 1.0;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                          return 'الرجاء إدخال كمية صحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'سعر البيع',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: sellingPrice.toStringAsFixed(2),
                      onChanged: (value) {
                        sellingPrice = double.tryParse(value) ?? 0.0;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0) {
                          return 'الرجاء إدخال سعر صحيح';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedItemName != null && quantity > 0 && sellingPrice >= 0) {
                  final newItem = InvoiceItem(
                    itemId: itemsBox.values.firstWhere((item) => item.name == selectedItemName!).id,
                    itemName: selectedItemName!,
                    quantity: quantity,
                    sellingPrice: sellingPrice,
                    unit: itemsBox.values.firstWhere((item) => item.name == selectedItemName!).unit,
                  );
                  setState(() {
                    _invoiceItems.add(newItem);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += item.quantity * item.sellingPrice; // ⭐ تم التعديل هنا: استخدام sellingPrice
    }
    return total;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String invoiceNumber = _invoiceNumberController.text.trim();
      final String? customerId = _selectedCustomer?.id;
      final String? customerName = _selectedCustomer?.name;

      if (widget.invoice == null) {
        // إضافة فاتورة جديدة
        final newInvoice = Invoice(
          id: uuid.v4(),
          invoiceNumber: invoiceNumber,
          type: InvoiceType.sale, // نوع الفاتورة: بيع
          date: _selectedDate,
          items: _invoiceItems,
          customerId: customerId,
          customerName: customerName,
          supplierId: null, // فاتورة بيع لا تحتاج supplierId
          supplierName: null, // فاتورة بيع لا تحتاج supplierName
        );
        await invoicesBox.put(newInvoice.id, newInvoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة فاتورة المبيعات بنجاح!')),
        );
      } else {
        // تحديث فاتورة موجودة
        final existingInvoice = widget.invoice!;
        existingInvoice.invoiceNumber = invoiceNumber;
        existingInvoice.date = _selectedDate;
        existingInvoice.items = _invoiceItems;
        existingInvoice.customerId = customerId;
        existingInvoice.customerName = customerName;

        await existingInvoice.save();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث فاتورة المبيعات بنجاح!')),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة مبيعات' : 'تعديل فاتورة مبيعات'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الفاتورة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال رقم الفاتورة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<Box<Customer>>(
                    valueListenable: customersBox.listenable(),
                    builder: (context, box, _) {
                      final customers = box.values.toList().cast<Customer>();
                      return DropdownButtonFormField<Customer>(
                        decoration: InputDecoration(
                          labelText: 'العميل (اختياري)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        value: _selectedCustomer,
                        items: [
                          const DropdownMenuItem<Customer>(
                            value: null,
                            child: Text('بدون عميل'),
                          ),
                          ...customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer,
                              child: Text(customer.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (customer) {
                          setState(() {
                            _selectedCustomer = customer;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addInvoiceItem,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة صنف'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'بنود الفاتورة:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _invoiceItems.isEmpty
                      ? const Text('لا توجد أصناف في الفاتورة حتى الآن.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _invoiceItems.length,
                          itemBuilder: (context, index) {
                            final item = _invoiceItems[index];
                            final itemTotal = item.quantity * item.sellingPrice;
                            final numberFormat = NumberFormat('#,##0.00', 'en_US');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: Text(item.itemName),
                                subtitle: Text(
                                  'الكمية: ${item.quantity} ${item.unit} x السعر: ${numberFormat.format(item.sellingPrice)} = الإجمالي: ${numberFormat.format(itemTotal)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeInvoiceItem(index),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                  Text(
                    'الإجمالي الكلي للفاتورة: ${NumberFormat('#,##0.00', 'en_US').format(_calculateTotal())}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveInvoice,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  widget.invoice == null ? 'حفظ فاتورة المبيعات' : 'تحديث فاتورة المبيعات',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
