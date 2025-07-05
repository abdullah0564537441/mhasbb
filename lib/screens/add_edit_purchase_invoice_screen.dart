import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ والأرقام

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/supplier.dart'; // استيراد موديل المورد

class AddEditPurchaseInvoiceScreen extends StatefulWidget {
  final Invoice? invoice; // فاتورة الشراء التي سيتم تعديلها (يمكن أن تكون null للإضافة)

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
  late Box<Supplier> suppliersBox; // صندوق الموردين

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box'); // تهيئة صندوق الموردين

    if (widget.invoice == null) {
      // فاتورة جديدة
      _invoiceNumberController = TextEditingController(text: _generateNextInvoiceNumber());
      _selectedDate = DateTime.now();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    } else {
      // تعديل فاتورة موجودة
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _selectedDate = widget.invoice!.date;
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _invoiceItems.addAll(widget.invoice!.items);

      // تحميل المورد المحدد إذا كان موجودًا في الفاتورة
      if (widget.invoice!.supplierId != null) {
        _selectedSupplier = suppliersBox.get(widget.invoice!.supplierId);
      }
    }
  }

  String _generateNextInvoiceNumber() {
    final allInvoices = invoicesBox.values.toList();
    final purchaseInvoices = allInvoices.where((inv) => inv.type == InvoiceType.purchase).toList();
    if (purchaseInvoices.isEmpty) {
      return 'PO-0001';
    }
    // البحث عن أعلى رقم فاتورة شراء حالي
    int maxNumber = 0;
    for (var invoice in purchaseInvoices) {
      if (invoice.invoiceNumber.startsWith('PO-')) {
        try {
          int currentNumber = int.parse(invoice.invoiceNumber.substring(3));
          if (currentNumber > maxNumber) {
            maxNumber = currentNumber;
          }
        } catch (e) {
          // تجاهل الأخطاء إذا كان التنسيق غير صحيح
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

  // دالة لاختيار التاريخ
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

  // دالة لإضافة صنف جديد للفاتورة
  void _addInvoiceItem() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedItemName;
        double quantity = 1.0;
        double price = 0.0;

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
                          price = selectedItem.salePrice; // افتراض سعر البيع هو السعر الافتراضي
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
                        labelText: 'السعر',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: price.toStringAsFixed(2),
                      onChanged: (value) {
                        price = double.tryParse(value) ?? 0.0;
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
              child: const Text('إضافة'),
              onPressed: () {
                if (selectedItemName != null && quantity > 0 && price >= 0) {
                  final newItem = InvoiceItem(
                    itemName: selectedItemName!,
                    quantity: quantity,
                    price: price,
                  );
                  setState(() {
                    _invoiceItems.add(newItem);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // دالة لحذف صنف من الفاتورة
  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  // دالة لحساب إجمالي بنود الفاتورة
  double _calculateTotal() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += item.quantity * item.price;
    }
    return total;
  }

  // دالة لحفظ الفاتورة
  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String invoiceNumber = _invoiceNumberController.text.trim();
      final String? supplierId = _selectedSupplier?.id;
      final String? supplierName = _selectedSupplier?.name;

      if (widget.invoice == null) {
        // إضافة فاتورة جديدة
        final newInvoice = Invoice(
          id: uuid.v4(),
          invoiceNumber: invoiceNumber,
          type: InvoiceType.purchase,
          date: _selectedDate,
          items: _invoiceItems,
          customerId: null, // فاتورة شراء لا تحتاج customerId
          customerName: null, // فاتورة شراء لا تحتاج customerName
          supplierId: supplierId,
          supplierName: supplierName,
        );
        await invoicesBox.put(newInvoice.id, newInvoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة فاتورة الشراء بنجاح!')),
        );
      } else {
        // تحديث فاتورة موجودة
        final existingInvoice = widget.invoice!;
        existingInvoice.invoiceNumber = invoiceNumber;
        existingInvoice.date = _selectedDate;
        existingInvoice.items = _invoiceItems;
        existingInvoice.supplierId = supplierId;
        existingInvoice.supplierName = supplierName;

        await existingInvoice.save();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث فاتورة الشراء بنجاح!')),
        );
      }
      Navigator.of(context).pop();
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
                          prefixIcon: const Icon(Icons.person_pin),
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
                          shrinkWrap: true, // مهم داخل Column أو Expanded
                          physics: const NeverScrollableScrollPhysics(), // لمنع التمرير الداخلي
                          itemCount: _invoiceItems.length,
                          itemBuilder: (context, index) {
                            final item = _invoiceItems[index];
                            final itemTotal = item.quantity * item.price;
                            final numberFormat = NumberFormat('#,##0.00', 'en_US');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: Text(item.itemName),
                                subtitle: Text(
                                  'الكمية: ${item.quantity} x السعر: ${numberFormat.format(item.price)} = الإجمالي: ${numberFormat.format(itemTotal)}',
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
                  minimumSize: const Size(double.infinity, 50), // زر بعرض كامل
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
