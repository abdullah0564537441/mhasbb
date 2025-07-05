// lib/screens/add_edit_purchase_invoice_screen.dart

// ... (استيرادات وبداية الكلاس) ...

class _AddEditPurchaseInvoiceScreenState extends State<AddEditPurchaseInvoiceScreen> {
  // ... (المتحكمات والمتغيرات الأخرى) ...

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box');

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
      _invoiceItems.addAll(widget.invoice!.items); // تم إزالة final من 'items' في Invoice
      if (widget.invoice!.supplierId != null) {
        _selectedSupplier = suppliersBox.get(widget.invoice!.supplierId);
      }
    }
  }

  // ... (بقية دوال الكلاس مثل _generateNextInvoiceNumber و _selectDate) ...

  // دالة لإضافة صنف جديد للفاتورة
  void _addInvoiceItem() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedItemName;
        double quantity = 1.0;
        double price = 0.0; // هذا يمثل سعر الشراء الذي سيتم إدخاله أو افتراضه

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
                          // ⭐ تعديل هنا: استخدم اسم الحقل الصحيح لسعر الشراء في موديل Item
                          // افترض أن حقل سعر الشراء في Item هو 'purchasePrice' أو 'price'
                          // إذا كان اسمه 'purchasePrice':
                          // price = selectedItem.purchasePrice;
                          // إذا كان اسمه 'price' (كما هو شائع لسعر الشراء الافتراضي):
                          price = selectedItem.price; // هذا هو الافتراض الشائع لسعر الشراء في موديل Item
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
                        labelText: 'السعر (سعر الشراء)',
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
                    itemId: itemsBox.values.firstWhere((item) => item.name == selectedItemName!).id, // تأكد من الحصول على ID
                    itemName: selectedItemName!,
                    quantity: quantity,
                    sellingPrice: price, // ⭐ تم التعديل هنا: يجب استخدام sellingPrice
                    unit: 'قطعة', // ⭐ تحتاج إلى إضافة حقل اختيار الوحدة أو افتراضها
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

  // ... (بقية الدوال مثل _removeInvoiceItem و _calculateTotal و _saveInvoice) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (AppBar وبداية Form) ...
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ... (حقول رقم الفاتورة والتاريخ والمورد) ...
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
                            // ⭐ تم التعديل هنا: استخدم item.sellingPrice
                            final itemTotal = item.quantity * item.sellingPrice;
                            final numberFormat = NumberFormat('#,##0.00', 'en_US');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: Text(item.itemName),
                                subtitle: Text(
                                  // ⭐ تم التعديل هنا: استخدم item.sellingPrice
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
                  // ... (إجمالي الفاتورة وزر الحفظ) ...
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
