// lib/screens/add_edit_return_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:mhasbb/models/return_invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/invoice_type.dart';

class AddEditReturnInvoiceScreen extends StatefulWidget {
  final ReturnInvoice? returnInvoice;

  const AddEditReturnInvoiceScreen({super.key, this.returnInvoice});

  @override
  State<AddEditReturnInvoiceScreen> createState() => _AddEditReturnInvoiceScreenState();
}

class _AddEditReturnInvoiceScreenState extends State<AddEditReturnInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _returnNumberController = TextEditingController();
  final _originalInvoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  InvoiceType? _selectedInvoiceType;
  String? _selectedPartyType;
  String? _selectedPartyId;
  String? _selectedPartyName;

  List<InvoiceItem> _returnItems = [];

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  List<Item> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.returnInvoice != null) {
      _returnNumberController.text = widget.returnInvoice!.returnNumber;
      _selectedDate = widget.returnInvoice!.date;
      _originalInvoiceNumberController.text = widget.returnInvoice!.originalInvoiceNumber ?? '';
      _notesController.text = widget.returnInvoice!.notes ?? '';
      _selectedInvoiceType = widget.returnInvoice!.originalInvoiceType;
      _returnItems = List.from(widget.returnInvoice!.items);

      if (widget.returnInvoice!.customerName != null) {
        _selectedPartyType = 'Customer';
        _selectedPartyName = widget.returnInvoice!.customerName;
        _selectedPartyId = _customers.firstWhere((c) => c.name == _selectedPartyName, orElse: () => Customer(id: '', name: '')).id;
      } else if (widget.returnInvoice!.supplierName != null) {
        _selectedPartyType = 'Supplier';
        _selectedPartyName = widget.returnInvoice!.supplierName;
        _selectedPartyId = _suppliers.firstWhere((s) => s.name == _selectedPartyName, orElse: () => Supplier(id: '', name: '')).id;
      }
    } else {
      _returnNumberController.text = 'RET-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    }
  }

  Future<void> _loadData() async {
    final customerBox = Hive.box<Customer>('customers_box');
    final supplierBox = Hive.box<Supplier>('suppliers_box');
    final itemBox = Hive.box<Item>('items_box');
    setState(() {
      _customers = customerBox.values.toList();
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
      _returnItems.add(InvoiceItem(
        id: const Uuid().v4(),
        itemId: '',
        itemName: '',
        quantity: 1,
        price: 0.0,
        unit: '', // ⭐⭐ تم إضافة هذا الحقل هنا ⭐⭐
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _returnItems.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _returnItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  Future<void> _saveReturnInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final returnInvoiceBox = Hive.box<ReturnInvoice>('return_invoices_box');
      final totalAmount = _calculateTotalAmount();

      // تحويل List<InvoiceItem> إلى HiveList<InvoiceItem>
      final HiveList<InvoiceItem> hiveReturnItems = HiveList<InvoiceItem>(returnInvoiceBox)..addAll(_returnItems);

      if (widget.returnInvoice == null) {
        // إضافة مرتجع جديد
        final newReturn = ReturnInvoice(
          id: const Uuid().v4(),
          returnNumber: _returnNumberController.text,
          date: _selectedDate,
          originalInvoiceNumber: _originalInvoiceNumberController.text.isNotEmpty ? _originalInvoiceNumberController.text : null,
          originalInvoiceType: _selectedInvoiceType!,
          customerName: _selectedPartyType == 'Customer' ? _selectedPartyName : null,
          supplierName: _selectedPartyType == 'Supplier' ? _selectedPartyName : null,
          items: hiveReturnItems,
          totalAmount: totalAmount,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        await returnInvoiceBox.put(newReturn.id, newReturn);
      } else {
        // تعديل مرتجع موجود
        widget.returnInvoice!.returnNumber = _returnNumberController.text;
        widget.returnInvoice!.date = _selectedDate;
        widget.returnInvoice!.originalInvoiceNumber = _originalInvoiceNumberController.text.isNotEmpty ? _originalInvoiceNumberController.text : null;
        widget.returnInvoice!.notes = _notesController.text.isNotEmpty ? _notesController.text : null;
        widget.returnInvoice!.originalInvoiceType = _selectedInvoiceType!;
        widget.returnInvoice!.customerName = _selectedPartyType == 'Customer' ? _selectedPartyName : null;
        widget.returnInvoice!.supplierName = _selectedPartyType == 'Supplier' ? _selectedPartyName : null;
        widget.returnInvoice!.items = hiveReturnItems;
        widget.returnInvoice!.totalAmount = totalAmount;
        await widget.returnInvoice!.save();
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ المرتجع بنجاح. الإجمالي: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(totalAmount)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.returnInvoice == null ? 'إضافة مرتجع' : 'تعديل مرتجع'),
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
                    controller: _returnNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم المرتجع',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم المرتجع';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ المرتجع',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _originalInvoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الفاتورة الأصلية (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<InvoiceType>(
                    value: _selectedInvoiceType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المرتجع',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('اختر نوع المرتجع (بيع/شراء)'),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedInvoiceType = newValue;
                        _selectedPartyType = null;
                        _selectedPartyId = null;
                        _selectedPartyName = null;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: InvoiceType.salesReturn, child: Text('مرتجع مبيعات')),
                      DropdownMenuItem(value: InvoiceType.purchaseReturn, child: Text('مرتجع مشتريات')),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار نوع المرتجع';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_selectedInvoiceType == InvoiceType.salesReturn)
                    DropdownButtonFormField<String>(
                      value: _selectedPartyId,
                      decoration: const InputDecoration(
                        labelText: 'العميل',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اختر العميل'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPartyId = newValue;
                          _selectedPartyName = _customers.firstWhere((c) => c.id == newValue).name;
                          _selectedPartyType = 'Customer';
                        });
                      },
                      items: _customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text(customer.name),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء اختيار العميل';
                        }
                        return null;
                      },
                    ),
                  if (_selectedInvoiceType == InvoiceType.purchaseReturn)
                    DropdownButtonFormField<String>(
                      value: _selectedPartyId,
                      decoration: const InputDecoration(
                        labelText: 'المورد',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اختر المورد'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPartyId = newValue;
                          _selectedPartyName = _suppliers.firstWhere((s) => s.id == newValue).name;
                          _selectedPartyType = 'Supplier';
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
                  const SizedBox(height: 20),
                  Text(
                    'الأصناف المرتجعة:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _returnItems.length,
                    itemBuilder: (context, index) {
                      final item = _returnItems[index];
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
                                      value: item.itemId.isEmpty ? null : item.itemId,
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
                                          item.unit = selectedItem.unit; // ⭐⭐ تم إضافة هذا هنا ⭐⭐
                                          // سعر الصنف عند المرتجع يعتمد على نوع الفاتورة الأصلية
                                          if (_selectedInvoiceType == InvoiceType.salesReturn) {
                                            item.price = selectedItem.salePrice;
                                          } else if (_selectedInvoiceType == InvoiceType.purchaseReturn) {
                                            item.price = selectedItem.purchasePrice;
                                          }
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
                                  labelText: 'الكمية المرتجعة',
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
                                  labelText: 'سعر الوحدة عند المرتجع',
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
                      label: const Text('إضافة صنف مرتجع'),
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
                    'إجمالي المرتجع: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(_calculateTotalAmount())}',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _saveReturnInvoice,
                icon: const Icon(Icons.save),
                label: const Text('حفظ المرتجع'),
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
    _returnNumberController.dispose();
    _originalInvoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
