// lib/screens/add_edit_purchase_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/models/invoice_type.dart';

class AddEditPurchaseInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const AddEditPurchaseInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditPurchaseInvoiceScreen> createState() => _AddEditPurchaseInvoiceScreenState();
}

class _AddEditPurchaseInvoiceScreenState extends State<AddEditPurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  List<InvoiceItem> _invoiceItems = []; // قائمة الأصناف في الفاتورة

  List<Supplier> _suppliers = [];
  List<Item> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _selectedDate = widget.invoice!.date;
      _selectedSupplierId = widget.invoice!.supplierId;
      _selectedSupplierName = widget.invoice!.supplierName;
      _selectedPaymentMethod = widget.invoice!.paymentMethod;
      _invoiceItems = List.from(widget.invoice!.items);
      _notesController.text = widget.invoice!.notes ?? ''; // ⭐⭐ تم التصحيح هنا ⭐⭐
    } else {
      _invoiceNumberController.text = 'PUR-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    }
  }

  Future<void> _loadData() async {
    final supplierBox = Hive.box<Supplier>('suppliers_box');
    final itemBox = Hive.box<Item>('items_box');
    setState(() {
      _suppliers = supplierBox.values.toList();
      _availableItems = itemBox.values.toList();
    });
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
      });
    }
  }

  void _addItem() {
    setState(() {
      _invoiceItems.add(InvoiceItem(
        id: const Uuid().v4(), // ⭐⭐ تم التصحيح هنا ⭐⭐
        itemId: '',
        itemName: '',
        quantity: 1,
        price: 0.0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final invoiceBox = Hive.box<Invoice>('invoices_box');
      final totalAmount = _calculateTotalAmount();

      // تحويل List<InvoiceItem> إلى HiveList<InvoiceItem>
      final HiveList<InvoiceItem> hiveInvoiceItems = HiveList<InvoiceItem>(invoiceBox)..addAll(_invoiceItems);

      if (widget.invoice == null) {
        final newInvoice = Invoice(
          id: const Uuid().v4(),
          invoiceNumber: _invoiceNumberController.text,
          type: InvoiceType.purchase,
          date: _selectedDate,
          items: hiveInvoiceItems, // ⭐⭐ تم التصحيح هنا ⭐⭐
          supplierId: _selectedSupplierId,
          supplierName: _selectedSupplierName,
          paymentMethod: _selectedPaymentMethod,
          totalAmount: totalAmount,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null, // ⭐⭐ تم التصحيح هنا ⭐⭐
        );
        await invoiceBox.put(newInvoice.id, newInvoice);
      } else {
        widget.invoice!.invoiceNumber = _invoiceNumberController.text;
        widget.invoice!.date = _selectedDate;
        widget.invoice!.supplierId = _selectedSupplierId;
        widget.invoice!.supplierName = _selectedSupplierName;
        widget.invoice!.paymentMethod = _selectedPaymentMethod;
        widget.invoice!.items = hiveInvoiceItems; // ⭐⭐ تم التصحيح هنا ⭐⭐
        widget.invoice!.totalAmount = totalAmount;
        widget.invoice!.notes = _notesController.text.isNotEmpty ? _notesController.text : null; // ⭐⭐ تم التصحيح هنا ⭐⭐
        await widget.invoice!.save();
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ فاتورة المشتريات بنجاح. الإجمالي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalAmount)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة مشتريات' : 'تعديل فاتورة مشتريات'),
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
                    decoration: const InputDecoration(
                      labelText: 'رقم الفاتورة',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الفاتورة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الفاتورة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'المورد',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('اختر المورد'),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSupplierId = newValue;
                        _selectedSupplierName = _suppliers.firstWhere((s) => s.id == newValue).name;
                      });
                    },
                    items: _suppliers.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier.id,
                        child: Text(supplier.name),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار المورد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<PaymentMethod>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPaymentMethod = newValue!;
                      });
                    },
                    items: PaymentMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method == PaymentMethod.cash ? 'نقدي' : 'آجل'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'الأصناف:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoiceItems.length,
                    itemBuilder: (context, index) {
                      final item = _invoiceItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: item.itemId.isEmpty ? null : item.itemId, // ⭐⭐ تم التصحيح هنا ⭐⭐
                                      decoration: const InputDecoration(
                                        labelText: 'الصنف',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      hint: const Text('اختر الصنف'),
                                      onChanged: (newValue) {
                                        setState(() {
                                          final selectedItem = _availableItems.firstWhere((i) => i.id == newValue);
                                          item.itemId = newValue!;
                                          item.itemName = selectedItem.name;
                                          item.price = selectedItem.purchasePrice; // سعر الشراء
                                        });
                                      },
                                      items: _availableItems.map((availableItem) {
                                        return DropdownMenuItem(
                                          value: availableItem.id,
                                          child: Text(availableItem.name),
                                        );
                                      }).toList(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء اختيار الصنف';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: item.quantity.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'الكمية',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'كمية صحيحة مطلوبة';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    item.quantity = double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: item.price.toStringAsFixed(2),
                                decoration: const InputDecoration(
                                  labelText: 'سعر الوحدة',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) < 0) {
                                    return 'سعر صحيح مطلوب';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    item.price = double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'الإجمالي الفرعي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(item.quantity * item.price)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة صنف'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إجمالي الفاتورة: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(_calculateTotalAmount())}',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _saveInvoice,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الفاتورة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
