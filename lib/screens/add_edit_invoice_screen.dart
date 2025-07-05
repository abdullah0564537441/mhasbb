// lib/screens/add_edit_invoice_screen.dart

// ... (الكود العلوي لم يتغير)

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  // ... (المتغيرات و initState لم تتغير)

  void _addInvoiceItem() {
    Item? selectedItemObject;
    double tempQuantity = 1.0;
    final TextEditingController _sellingPriceController = TextEditingController();

    final _itemFormKey = GlobalKey<FormState>();
    final TextEditingController _itemSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة صنف للفاتورة'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              if (selectedItemObject != null && _sellingPriceController.text.isEmpty) {
                _sellingPriceController.text = selectedItemObject!.sellingPrice.toStringAsFixed(2);
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
                            _sellingPriceController.text = selection.sellingPrice.toStringAsFixed(2);
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
                        controller: _sellingPriceController,
                        decoration: InputDecoration(
                          labelText: 'سعر البيع',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // ⭐ تم إزالة السطر التالي الذي كان يسبب خطأ copyWith
                          // selectedItemObject = selectedItemObject?.copyWith(
                          //   sellingPrice: double.tryParse(value) ?? 0.0,
                          // );
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
                      quantity: tempQuantity,
                      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
                      // ⭐ جديد: يجب أن نمرر purchasePrice هنا
                      purchasePrice: selectedItemObject!.purchasePrice, // جلب سعر الشراء من الصنف الأصلي
                      unit: selectedItemObject!.unit,
                    );
                    setState(() {
                      _invoiceItems.add(newItem);
                    });
                    Navigator.of(context).pop();
                    _sellingPriceController.dispose();
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

  // ... (باقي الكود لم يتغير)
}
