// lib/screens/add_edit_purchase_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_type.dart'; // ⭐ أضف هذا السطر ⭐
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/supplier.dart'; // تأكد من استيراد المورد
import 'package:mhasbb/models/payment_method.dart'; // ⭐ أضف هذا السطر

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

  // لوضع التعديل: تخزين الكميات الأصلية لاستعادتها
  final Map<String, double> _originalItemQuantities = {};

  // ⭐ متغير جديد لطريقة الدفع
  late PaymentMethod _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box'); // تأكد من تهيئة صندوق الموردين

    if (widget.invoice == null) {
      _invoiceNumberController = TextEditingController(text: _generateNextInvoiceNumber());
      _selectedDate = DateTime.now();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _selectedPaymentMethod = PaymentMethod.cash; // ⭐ قيمة افتراضية جديدة لفاتورة جديدة
    } else {
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _selectedDate = widget.invoice!.date;
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _invoiceItems.addAll(List<InvoiceItem>.from(widget.invoice!.items));
      if (widget.invoice!.supplierId != null) {
        _selectedSupplier = suppliersBox.get(widget.invoice!.supplierId);
      }
      _selectedPaymentMethod = widget.invoice!.paymentMethod; // ⭐ تحميل طريقة الدفع الموجودة
      // ملء الكميات الأصلية لوضع التعديل
      for (var item in widget.invoice!.items) {
        _originalItemQuantities[item.itemId] = item.quantity;
      }
    }
  }

  String _generateNextInvoiceNumber() {
    final allInvoices = invoicesBox.values.toList();
    final purchaseInvoices = allInvoices.where((inv) => inv.type == InvoiceType.purchase).toList(); // استخدام InvoiceType.purchase
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
    final TextEditingController _quantityController = TextEditingController(text: '1.0');

    final _itemFormKey = GlobalKey<FormState>();
    final TextEditingController _itemSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة صنف للفاتورة'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInDialog) {
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
                          setStateInDialog(() {
                            selectedItemObject = selection;
                            _itemSearchController.text = selection.name;
                            _purchasePriceController.text = selection.purchasePrice.toStringAsFixed(2);
                            tempQuantity = 1.0;
                            _quantityController.text = '1.0';
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
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'الكمية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          tempQuantity = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                            return 'الرجاء إدخال كمية صحيحة أكبر من 0';
                          }
                          return null; // لا يوجد تحقق من المخزون في فاتورة الشراء (نحن نضيف للمخزون)
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
                _quantityController.dispose();
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_itemFormKey.currentState!.validate()) {
                  if (selectedItemObject != null) {
                    final existingItemIndex = _invoiceItems.indexWhere((item) => item.itemId == selectedItemObject!.id);

                    if (existingItemIndex != -1) {
                      setState(() {
                        _invoiceItems[existingItemIndex] = InvoiceItem(
                          itemId: selectedItemObject!.id,
                          itemName: selectedItemObject!.name,
                          quantity: _invoiceItems[existingItemIndex].quantity + tempQuantity,
                          sellingPrice: selectedItemObject!.sellingPrice, // لا نغير سعر البيع هنا
                          purchasePrice: double.tryParse(_purchasePriceController.text) ?? selectedItemObject!.purchasePrice,
                          unit: selectedItemObject!.unit,
                        );
                      });
                    } else {
                      final newItem = InvoiceItem(
                        itemId: selectedItemObject!.id,
                        itemName: selectedItemObject!.name,
                        quantity: tempQuantity,
                        sellingPrice: selectedItemObject!.sellingPrice,
                        purchasePrice: double.tryParse(_purchasePriceController.text) ?? selectedItemObject!.purchasePrice,
                        unit: selectedItemObject!.unit,
                      );
                      setState(() {
                        _invoiceItems.add(newItem);
                      });
                    }
                    Navigator.of(context).pop();
                    _purchasePriceController.dispose();
                    _quantityController.dispose();
                  }
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
      total += item.quantity * item.purchasePrice; // هنا نحسب بناءً على سعر الشراء
    }
    return total;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_invoiceItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إضافة صنف واحد على الأقل للفاتورة.')),
        );
        return;
      }

      _formKey.currentState!.save();

      final String invoiceNumber = _invoiceNumberController.text.trim();
      final String? supplierId = _selectedSupplier?.id;
      final String? supplierName = _selectedSupplier?.name;

      try {
        if (widget.invoice == null) {
          // فاتورة شراء جديدة: إضافة للمخزون
          for (var invoiceItem in _invoiceItems) {
            final itemInStock = itemsBox.get(invoiceItem.itemId);
            if (itemInStock != null) {
              itemInStock.quantity += invoiceItem.quantity; // زيادة المخزون
              await itemInStock.save();
            }
          }

          final newInvoice = Invoice(
            id: uuid.v4(),
            invoiceNumber: invoiceNumber,
            type: InvoiceType.purchase, // فاتورة شراء
            date: _selectedDate,
            items: _invoiceItems.toList(),
            customerId: null,
            customerName: null,
            supplierId: supplierId,
            supplierName: supplierName,
            paymentMethod: _selectedPaymentMethod, // ⭐ حفظ طريقة الدفع
          );
          await invoicesBox.put(newInvoice.id, newInvoice);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة فاتورة الشراء بنجاح!')),
          );
        } else {
          // فاتورة شراء موجودة: استعادة الكميات القديمة ثم تطبيق الجديدة
          // 1. أولاً: نقص الكميات الأصلية من المخزون
          for (var entry in _originalItemQuantities.entries) {
            final itemId = entry.key;
            final originalQty = entry.value;
            final itemInStock = itemsBox.get(itemId);
            if (itemInStock != null) {
              itemInStock.quantity -= originalQty; // نقص المخزون
              await itemInStock.save();
            }
          }

          // 2. ثانياً: إضافة الكميات الجديدة إلى المخزون
          for (var invoiceItem in _invoiceItems) {
            final itemInStock = itemsBox.get(invoiceItem.itemId);
            if (itemInStock != null) {
              itemInStock.quantity += invoiceItem.quantity; // إضافة إلى المخزون
              await itemInStock.save();
            }
          }

          final existingInvoice = widget.invoice!;
          existingInvoice.invoiceNumber = invoiceNumber;
          existingInvoice.date = _selectedDate;
          existingInvoice.items = _invoiceItems.toList();
          existingInvoice.supplierId = supplierId;
          existingInvoice.supplierName = supplierName;
          existingInvoice.paymentMethod = _selectedPaymentMethod; // ⭐ تحديث طريقة الدفع

          await existingInvoice.save();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث فاتورة الشراء بنجاح!')),
          );
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ الفاتورة: $e')),
        );
        debugPrint('Hive Save Error: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إكمال جميع الحقول المطلوبة بشكل صحيح.')),
      );
    }
  }

  // دالة مساعدة لتحويل قيمة PaymentMethod إلى نص عربي
  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.credit:
        return 'آجل';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة شراء' : 'تعديل فاتورة شراء'),
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
                  ValueListenableBuilder<Box<Supplier>>(
                    valueListenable: suppliersBox.listenable(),
                    builder: (context, box, _) {
                      final suppliers = box.values.toList().cast<Supplier>();
                      return DropdownButtonFormField<Supplier>(
                        decoration: InputDecoration(
                          labelText: 'المورد (اختياري)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.business),
                        ),
                        value: _selectedSupplier,
                        items: [
                          const DropdownMenuItem<Supplier>(
                            value: null,
                            child: Text('بدون مورد'),
                          ),
                          ...suppliers.map((supplier) {
                            return DropdownMenuItem(
                              value: supplier,
                              child: Text(supplier.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (supplier) {
                          setState(() {
                            _selectedSupplier = supplier;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // ⭐ حقل جديد لاختيار طريقة الدفع
                  DropdownButtonFormField<PaymentMethod>(
                    decoration: InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.payment),
                    ),
                    value: _selectedPaymentMethod,
                    items: PaymentMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(_getPaymentMethodDisplayName(method)),
                      );
                    }).toList(),
                    onChanged: (method) {
                      if (method != null) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار طريقة الدفع';
                      }
                      return null;
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
                  ValueListenableBuilder<List<InvoiceItem>>(
                    valueListenable: ValueNotifier(_invoiceItems),
                    builder: (context, currentItems, child) {
                      if (currentItems.isEmpty) {
                        return const Text('لا توجد أصناف في الفاتورة حتى الآن.');
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentItems.length,
                        itemBuilder: (context, index) {
                          final item = currentItems[index];
                          final itemTotal = item.quantity * item.purchasePrice; // سعر الشراء
                          final numberFormat = NumberFormat('#,##0.00', 'en_US');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(item.itemName),
                              subtitle: Text(
                                'الكمية: ${item.quantity} ${item.unit} x السعر: ${numberFormat.format(item.purchasePrice)} = الإجمالي: ${numberFormat.format(itemTotal)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeInvoiceItem(index),
                              ),
                            ),
                          );
                        },
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
                  widget.invoice == null ? 'حفظ فاتورة الشراء' : 'تحديث فاتورة الشراء',
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
