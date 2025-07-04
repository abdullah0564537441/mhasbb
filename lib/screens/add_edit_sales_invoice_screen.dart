import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // لتوليد معرفات فريدة للفواتير والأصناف

// استيراد الموديلات التي سنستخدمها
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/item.dart'; // لافتراض وجود منتجات يمكن اختيارها

class AddEditInvoiceScreen extends StatefulWidget {
  final Invoice? invoice; // الفاتورة التي سيتم تعديلها (يمكن أن تكون null للإضافة)

  const AddEditInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

  // المتحكمات (Controllers) لحقول الإدخال
  late TextEditingController _invoiceIdController;
  late TextEditingController _customerNameController;
  late TextEditingController _invoiceDateController; // لتخزين التاريخ كنص
  DateTime? _selectedDate; // لتخزين التاريخ كـ DateTime

  // قائمة الأصناف في الفاتورة الحالية
  List<InvoiceItem> _currentInvoiceItems = [];

  // صناديق Hive التي سنتعامل معها
  late Box<Invoice> invoicesBox;
  late Box<Customer> customersBox;
  late Box<Item> itemsBox; // صندوق الأصناف (المنتجات) المتاحة

  // لتوليد معرفات فريدة
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    customersBox = Hive.box<Customer>('customers_box');
    itemsBox = Hive.box<Item>('items_box'); // الحصول على صندوق الأصناف

    // تهيئة المتحكمات بناءً على ما إذا كنا نضيف فاتورة جديدة أو نعدل فاتورة موجودة
    if (widget.invoice == null) {
      // وضع افتراضيات لفاتورة جديدة
      _invoiceIdController = TextEditingController(text: uuid.v4().substring(0, 8).toUpperCase()); // معرف فريد قصير
      _customerNameController = TextEditingController();
      _selectedDate = DateTime.now(); // التاريخ الافتراضي هو اليوم
      _invoiceDateController = TextEditingController(text: _selectedDate!.toLocal().toString().split(' ')[0]); // تنسيق التاريخ للعرض
    } else {
      // تحميل بيانات الفاتورة الموجودة للتعديل
      _invoiceIdController = TextEditingController(text: widget.invoice!.id);
      _customerNameController = TextEditingController(text: widget.invoice!.customer.name);
      _selectedDate = widget.invoice!.invoiceDate;
      _invoiceDateController = TextEditingController(text: _selectedDate!.toLocal().toString().split(' ')[0]);
      _currentInvoiceItems = List.from(widget.invoice!.items); // نسخ قائمة الأصناف
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _customerNameController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  // دالة لاختيار التاريخ من منتقي التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _invoiceDateController.text = _selectedDate!.toLocal().toString().split(' ')[0];
      });
    }
  }

  // دالة لحساب الإجمالي الكلي للفاتورة
  double _calculateTotalAmount() {
    return _currentInvoiceItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // دالة لإضافة صنف جديد إلى قائمة الفاتورة
  void _addInvoiceItem() async {
    // ⭐ هنا سنفتح شاشة جديدة لاختيار الصنف من المخزون أو إدخاله يدوياً
    // لتبسيط الأمر الآن، سنضيف صنفًا تجريبيًا مؤقتًا
    // لاحقًا: سنقوم بتوجيه المستخدم لشاشة اختيار المنتج أو إدخال تفاصيله
    final newItem = InvoiceItem(
      itemId: uuid.v4(), // معرف فريد للصنف في الفاتورة
      itemName: 'منتج تجريبي ${(_currentInvoiceItems.length + 1)}',
      sellingPrice: 100.0,
      quantity: 1,
    );
    setState(() {
      _currentInvoiceItems.add(newItem);
    });
    // يمكنك هنا توجيه المستخدم لشاشة اختيار الأصناف أو مربّع حوار (Dialog)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة صنف تجريبي للفاتورة.')),
    );
  }

  // دالة لحفظ الفاتورة
  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // التحقق من وجود عميل، إذا لم يكن موجوداً، يمكن إضافته
      Customer? customer = customersBox.values.firstWhereOrNull(
        (c) => c.name.toLowerCase() == _customerNameController.text.toLowerCase(),
      );
      if (customer == null) {
        // إذا كان العميل غير موجود، قم بإنشاء عميل جديد
        customer = Customer(
          id: uuid.v4(),
          name: _customerNameController.text,
          phone: '', // يمكن إضافة حقول الهاتف والعنوان لاحقاً
          address: '',
        );
        await customersBox.put(customer.id, customer); // حفظ العميل الجديد
      }

      final newInvoice = Invoice(
        id: _invoiceIdController.text,
        invoiceDate: _selectedDate ?? DateTime.now(),
        customer: customer,
        items: _currentInvoiceItems,
      );

      if (widget.invoice == null) {
        // إضافة فاتورة جديدة
        await invoicesBox.put(newInvoice.id, newInvoice); // استخدام ID الفاتورة كمفتاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الفاتورة بنجاح!')),
        );
      } else {
        // تحديث فاتورة موجودة
        await invoicesBox.put(widget.invoice!.key, newInvoice); // استخدام مفتاح الفاتورة الأصلي للتحديث
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الفاتورة بنجاح!')),
        );
      }
      Navigator.of(context).pop(); // العودة إلى شاشة فواتير البيع
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة جديدة' : 'تعديل فاتورة'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // حقل رقم الفاتورة (للقراءة فقط)
              TextFormField(
                controller: _invoiceIdController,
                readOnly: true, // لا يمكن تعديل رقم الفاتورة
                decoration: InputDecoration(
                  labelText: 'رقم الفاتورة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),

              // حقل اسم العميل
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'اسم العميل',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل اسم العميل',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم العميل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل تاريخ الفاتورة
              TextFormField(
                controller: _invoiceDateController,
                readOnly: true, // لمنع الإدخال اليدوي
                onTap: () => _selectDate(context), // لفتح منتقي التاريخ عند النقر
                decoration: InputDecoration(
                  labelText: 'تاريخ الفاتورة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 20),

              // قسم الأصناف في الفاتورة
              Text(
                'الأصناف في الفاتورة:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),

              // عرض قائمة الأصناف المضافة
              _currentInvoiceItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'لم تتم إضافة أي أصناف للفاتورة بعد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true, // لجعل ListView يأخذ المساحة التي يحتاجها فقط
                      physics: const NeverScrollableScrollPhysics(), // لمنع التمرير المزدوج
                      itemCount: _currentInvoiceItems.length,
                      itemBuilder: (context, index) {
                        final item = _currentInvoiceItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          child: ListTile(
                            title: Text(item.itemName),
                            subtitle: Text('الكمية: ${item.quantity} | السعر: ${item.sellingPrice.toStringAsFixed(2)} | الإجمالي: ${item.total.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _currentInvoiceItems.removeAt(index); // حذف الصنف
                                });
                              },
                            ),
                            onTap: () {
                              // يمكن إضافة منطق لتعديل الصنف هنا
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('سيتم تفعيل تعديل الصنف لاحقاً')),
                              );
                            },
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 10),
              // زر إضافة صنف جديد
              ElevatedButton.icon(
                onPressed: _addInvoiceItem,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة صنف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // الإجمالي الكلي للفاتورة
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الإجمالي الكلي: ${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
                ),
              ),
              const SizedBox(height: 30),

              // زر حفظ الفاتورة
              ElevatedButton(
                onPressed: _saveInvoice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  widget.invoice == null ? 'حفظ الفاتورة' : 'تحديث الفاتورة',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// امتداد لمساعدة Hive (إذا لم يكن لديك بالفعل)
// هذا يسمح لنا باستخدام firstWhereOrNull() بشكل مباشر على الـ Iterable
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

