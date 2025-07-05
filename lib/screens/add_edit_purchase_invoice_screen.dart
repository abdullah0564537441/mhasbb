// lib/screens/add_edit_purchase_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/invoice_type.dart'; // ⭐ تم إضافة هذا السطر

class AddEditPurchaseInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const AddEditPurchaseInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditPurchaseInvoiceScreen> createState() => _AddEditPurchaseInvoiceScreenState();
}

class _AddEditPurchaseInvoiceScreenState extends State<AddEditPurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid uuid = const Uuid();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _dateController;
  Supplier? _selectedSupplier;
  final List<InvoiceItem> _invoiceItems = [];

  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox;
  late Box<Supplier> suppliersBox;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box');

    if (widget.invoice == null) {
      _invoiceNumberController = TextEditingController(text: _generateNextInvoiceNumber());
      _selectedDate = DateTime.now();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    } else {
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _selectedDate = widget.invoice!.date;
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _invoiceItems.addAll(List<InvoiceItem>.from(widget.invoice!.items));
      if (widget.invoice!.supplierId != null) {
        _selectedSupplier = suppliersBox.get(widget.invoice!.supplierId);
      }
    }
  }

  String _generateNextInvoiceNumber() {
    final allInvoices = invoicesBox.values.toList();
    final purchaseInvoices = allInvoices.where((inv) => inv.type == InvoiceType.purchase).toList(); // ⭐ استخدام InvoiceType.purchase
    if (purchaseInvoices.isEmpty) {
      return 'PO-0001';
    }
    int maxNumber = 0;
    for (var invoice in purchaseInvoices) {
      if (invoice.invoiceNumber.startsWith('PO-')) {
        try {
          int currentNumber = int.parse(invoice.invoiceNumber.substring(3));
          if (currentNumber > maxNumber) {
            maxNumber = currentNumber;
          }
        } catch (e) {
          // Ignore errors if format is incorrect
        }
      }
    }
    return 'PO-${(maxNumber + 1).toString().padLeft(4, '0')}';
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
    Item? selectedItemObject;
    double tempQuantity = 1.0;
    final TextEditingController _purchasePriceController = TextEditingController();

    final _itemFormKey = GlobalKey<FormState>();
    final TextEditingController _itemSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة صنف لفاتورة الشراء'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              if (selectedItemObject != null && _purchasePriceController.text.isEmpty) {
                _purchasePriceController.text = selectedItemObject!.purchasePrice.toStringAsFixed(2);
              }

              return Form(
                key: _itemFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<Item>(
                        displayStringForOption: (Item option) => option.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Item>.empty();
                          }
                          return itemsBox.values.where((item) {
                            return item.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (Item selection) {
                          setState(() {
                            selectedItemObject = selection;
                            _itemSearchController.text = selection.name;
                            _purchasePriceController.text = selection.purchasePrice.toStringAsFixed(2);
                            tempQuantity = 1.0;
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted) {
                          _itemSearchController.text = fieldTextEditingController.text;
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: InputDecoration(
                              labelText: 'البحث عن صنف',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty || selectedItemObject == null || selectedItemObject!.name.toLowerCase() != value.toLowerCase()) {
                                return 'الرجاء اختيار صنف موجود من القائمة';
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (BuildContext context,
                            AutocompleteOnSelected<Item> onSelected,
                            Iterable<Item> options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: SizedBox(
                                height: 200.0,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Item option = options.elementAt(index);
                                    return GestureDetector(
                                      onTap: () {
                                        onSelected(option);
                                      },
                                      child: ListTile(
                                        title: Text(option.name),
                                        subtitle: Text('سعر الشراء: ${option.purchasePrice.toStringAsFixed(2)}'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'الكمية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: tempQuantity.toString(),
                        onChanged: (value) {
                          tempQuantity = double.tryParse(value) ?? 1.0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                            return 'الرجاء إدخال كمية صحيحة أكبر من 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purchasePriceController,
                        decoration: InputDecoration(
                          labelText: 'سعر الشراء',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! < 0) {
                            return 'الرجاء إدخال سعر صحيح';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
                _purchasePriceController.dispose();
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_itemFormKey.currentState!.validate()) {
                  _itemFormKey.currentState!.save();

                  if (selectedItemObject != null) {
                    final newItem = InvoiceItem(
                      itemId: selectedItemObject!.id,
                      itemName: selectedItemObject!.name,
                      quantity: temp
