// lib/screens/add_edit_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/invoice_type.dart';

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

  // لوضع التعديل: تخزين الكميات الأصلية لاستعادتها
  final Map<String, double> _originalItemQuantities = {};

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    customersBox = Hive.box<Customer>('customers_box');

    if (widget.invoice == null) {
      _invoiceNumberController = TextEditingController(text: _generateNextInvoiceNumber());
      _selectedDate = DateTime.now();
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
    } else {
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _selectedDate = widget.invoice!.date;
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _invoiceItems.addAll(List<InvoiceItem>.from(widget.invoice!.items));
      if (widget.invoice!.customerId != null) {
        _selectedCustomer = customersBox.get(widget.invoice!.customerId);
      }
      // ملء الكميات الأصلية لوضع التعديل
      for (var item in widget.invoice!.items) {
        _originalItemQuantities[item.itemId] = item.quantity;
      }
    }
  }

  String _generateNextInvoiceNumber() {
    final allInvoices = invoicesBox.values.toList();
    final salesInvoices = allInvoices.where((inv) => inv.type == InvoiceType.sale).toList();
    if (salesInvoices.isEmpty) {
      return 'SO-0001';
    }
    int maxNumber = 0;
    for (var invoice in salesInvoices) {
      if (invoice.invoiceNumber.startsWith('SO-')) {
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
    return 'SO-${(maxNumber + 1).toString().padLeft(4, '0')}';
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
    final TextEditingController _sellingPriceController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController(text: '1.0'); // إضافة متحكم للكمية

    final _itemFormKey = GlobalKey<FormState>();
    final TextEditingController _itemSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة صنف للفاتورة'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInDialog) { // استخدام setStateInDialog
              if (selectedItemObject != null && _sellingPriceController.text.isEmpty) {
                _sellingPriceController.text = selectedItemObject!.sellingPrice.toStringAsFixed(2);
              }

              return Form(
                key: _itemFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.AxisSize.min,
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
                          setStateInDialog(() { // استخدام setStateInDialog
                            selectedItemObject = selection;
                            _itemSearchController.text = selection.name;
                            _sellingPriceController.text = selection.sellingPrice.toStringAsFixed(2);
                            tempQuantity = 1.0; // إعادة تعيين الكمية عند اختيار صنف جديد
                            _quantityController.text = '1.0'; // تحديث قيمة المتحكم
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
                                        subtitle: Text('سعر البيع: ${option.sellingPrice.toStringAsFixed(2)}'),
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
                        controller: _quantityController, // استخدام المتحكم هنا
                        decoration: InputDecoration(
                          labelText: 'الكمية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        // initialValue: tempQuantity.toString(), // لا نحتاج initialValue مع controller
                        onChanged: (value) {
                          tempQuantity = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                            return 'الرجاء إدخال كمية صحيحة أكبر من 0';
                          }
                          // ⭐ التحقق من توفر الكمية في المخزون
                          if (selectedItemObject != null) {
                            final currentItemInStock = itemsBox.get(selectedItemObject!.id);
                            if (currentItemInStock != null) {
                              // حساب الكمية الحالية للصنف نفسه في الفاتورة (لتجنب التعديل الذاتي الخاطئ في وضع التعديل)
                              final currentQuantityInInvoiceForThisItem = _invoiceItems
                                  .where((element) => element.itemId == selectedItemObject!.id)
                                  .fold(0.0, (previousValue, element) => previousValue + element.quantity);

                              // في وضع التعديل، يجب أن نعيد الكمية الأصلية لهذا الصنف إلى المخزون مؤقتًا للتحقق
                              double effectiveStock = currentItemInStock.quantity;
                              if (widget.invoice != null && _originalItemQuantities.containsKey(selectedItemObject!.id)) {
                                effectiveStock += _originalItemQuantities[selectedItemObject!.id]!;
                              }

                              // الكمية المطلوبة الإجمالية (الكمية الجديدة + أي كمية موجودة لنفس الصنف في الفاتورة قبل التعديل)
                              // إذا كان الصنف يُضاف لأول مرة في الحوار، فالكمية المطلوبة هي tempQuantity
                              // إذا كان الصنف موجودًا بالفعل في قائمة الفاتورة، يجب أن نأخذ في الاعتبار الكمية الموجودة بالفعل
                              double totalRequestedQuantity = tempQuantity; // هذا يمثل الإضافة الجديدة فقط

                              // للتحقق من الكمية الإجمالية بعد الإضافة
                              // سنفترض أننا نجمع الكميات إذا كان الصنف موجودًا بالفعل في القائمة المؤقتة _invoiceItems
                              // ولكن التحقق يجب أن يكون مقابل المخزون الفعلي بعد حساب التعديلات.
                              // الحل الأبسط: تحقق من أن الكمية المطلوبة (tempQuantity) لا تتجاوز المخزون المتاح حاليًا
                              // بعد حساب الكميات المسترجعة من الفاتورة الأصلية.
                              if (effectiveStock < totalRequestedQuantity) {
                                return 'الكمية المطلوبة ($totalRequestedQuantity) أكبر من المتوفر ($effectiveStock)';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sellingPriceController,
                        decoration: InputDecoration(
                          labelText: 'سعر البيع',
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
                _sellingPriceController.dispose();
                _quantityController.dispose(); // التخلص من المتحكم
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_itemFormKey.currentState!.validate()) {
                  // هنا لا نحتاج save() لأننا نستخدم controllers مباشرة
                  // _itemFormKey.currentState!.save();

                  if (selectedItemObject != null) {
                    final existingItemIndex = _invoiceItems.indexWhere((item) => item.itemId == selectedItemObject!.id);

                    if (existingItemIndex != -1) {
                      // إذا كان الصنف موجودًا بالفعل في الفاتورة، قم بتحديث كميته وسعره
                      setState(() { // يجب أن يكون هذا setState الخاص بـ _AddEditInvoiceScreenState
                        _invoiceItems[existingItemIndex] = InvoiceItem(
                          itemId: selectedItemObject!.id,
                          itemName: selectedItemObject!.name,
                          quantity: _invoiceItems[existingItemIndex].quantity + tempQuantity, // أضف إلى الكمية الموجودة
                          sellingPrice: double.tryParse(_sellingPriceController.text) ?? selectedItemObject!.sellingPrice,
                          purchasePrice: selectedItemObject!.purchasePrice,
                          unit: selectedItemObject!.unit,
                        );
                      });
                    } else {
                      // إضافة صنف جديد إلى الفاتورة
                      final newItem = InvoiceItem(
                        itemId: selectedItemObject!.id,
                        itemName: selectedItemObject!.name,
                        quantity: tempQuantity,
                        sellingPrice: double.tryParse(_sellingPriceController.text) ?? selectedItemObject!.sellingPrice,
                        purchasePrice: selectedItemObject!.purchasePrice,
                        unit: selectedItemObject!.unit,
                      );
                      setState(() { // يجب أن يكون هذا setState الخاص بـ _AddEditInvoiceScreenState
                        _invoiceItems.add(newItem);
                      });
                    }
                    Navigator.of(context).pop();
                    _sellingPriceController.dispose();
                    _quantityController.dispose(); // التخلص من المتحكم
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
      total += item.quantity * item.sellingPrice;
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
      final String? customerId = _selectedCustomer?.id;
      final String? customerName = _selectedCustomer?.name;

      try {
        if (widget.invoice == null) {
          // فاتورة بيع جديدة: إنقاص المخزون
          for (var invoiceItem in _invoiceItems) {
            final itemInStock = itemsBox.get(invoiceItem.itemId);
            if (itemInStock != null) {
              if (itemInStock.quantity >= invoiceItem.quantity) {
                itemInStock.quantity -= invoiceItem.quantity;
                await itemInStock.save();
              } else {
                // هذا السيناريو يجب أن يتم التعامل معه بواسطة validator في _addInvoiceItem
                // ولكن كطبقة حماية إضافية
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('كمية الصنف ${invoiceItem.itemName} غير كافية في المخزون!')),
                );
                return; // إيقاف عملية الحفظ
              }
            }
          }

          final newInvoice = Invoice(
            id: uuid.v4(),
            invoiceNumber: invoiceNumber,
            type: InvoiceType.sale,
            date: _selectedDate,
            items: _invoiceItems.toList(),
            customerId: customerId,
            customerName: customerName,
            supplierId: null,
            supplierName: null,
          );
          await invoicesBox.put(newInvoice.id, newInvoice);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة فاتورة البيع بنجاح!')),
          );
        } else {
          // فاتورة بيع موجودة: استعادة الكميات القديمة ثم تطبيق الجديدة
          // 1. أولاً: زيادة الكميات الأصلية في المخزون
          for (var entry in _originalItemQuantities.entries) {
            final itemId = entry.key;
            final originalQty = entry.value;
            final itemInStock = itemsBox.get(itemId);
            if (itemInStock != null) {
              itemInStock.quantity += originalQty; // زيادة المخزون
              await itemInStock.save();
            }
          }

          // 2. ثانياً: نقص الكميات الجديدة من المخزون (بعد التحقق من توفرها)
          for (var invoiceItem in _invoiceItems) {
            final itemInStock = itemsBox.get(invoiceItem.itemId);
            if (itemInStock != null) {
              if (itemInStock.quantity >= invoiceItem.quantity) {
                itemInStock.quantity -= invoiceItem.quantity; // نقص من المخزون
                await itemInStock.save();
              } else {
                // هذا السيناريو يجب أن يتم التعامل معه بواسطة validator في _addInvoiceItem
                // ولكن كطبقة حماية إضافية
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('كمية الصنف ${invoiceItem.itemName} غير كافية في المخزون بعد التعديل!')),
                );
                return; // إيقاف عملية الحفظ
              }
            }
          }

          final existingInvoice = widget.invoice!;
          existingInvoice.invoiceNumber = invoiceNumber;
          existingInvoice.date = _selectedDate;
          existingInvoice.items = _invoiceItems.toList();
          existingInvoice.customerId = customerId;
          existingInvoice.customerName = customerName;

          await existingInvoice.save();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث فاتورة البيع بنجاح!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة بيع' : 'تعديل فاتورة بيع'),
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
                  widget.invoice == null ? 'حفظ فاتورة البيع' : 'تحديث فاتورة البيع',
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
