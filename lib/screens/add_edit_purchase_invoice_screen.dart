// lib/screens/add_edit_purchase_invoice_screen.dart
// تأكد أن جميع الـ imports في بداية الملف موجودة بشكل صحيح

// ... (الكود العلوي لم يتغير، بما في ذلك _addInvoiceItem و _removeInvoiceItem و _calculateTotal)

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
                          final itemTotal = item.quantity * item.purchasePrice;
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
            // هذا هو الجزء الذي يسبب المشكلة إذا كان خارج دالة build
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
} // تأكد أن هذا القوس يغلق كلاس _AddEditPurchaseInvoiceScreenState
