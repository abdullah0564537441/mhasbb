import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

// استيراد موديلات Hive
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/supplier.dart'; // ⭐ استيراد موديل المورد

// استيراد شاشة اختيار الأصناف الجديدة (نفسها المستخدمة للبيع)
import 'package:mhasbb/screens/item_selection_screen.dart';


class AddEditPurchaseInvoiceScreen extends StatefulWidget {
  final Invoice? invoice; // فاتورة الشراء التي سيتم تعديلها (يمكن أن تكون null للإضافة)

  const AddEditPurchaseInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditPurchaseInvoiceScreen> createState() => _AddEditPurchaseInvoiceScreenState();
}

class _AddEditPurchaseInvoiceScreenState extends State<AddEditPurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

  // المتحكمات (Controllers) لحقول الإدخال
  late TextEditingController _invoiceNumberController;
  late TextEditingController _invoiceDateController;

  Supplier? _selectedSupplier; // ⭐ لتخزين المورد المختار
  late Box<Supplier> suppliersBox; // ⭐ صندوق الموردين
  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox;
  final Uuid uuid = const Uuid(); // لتوليد معرفات فريدة

  List<InvoiceItem> _invoiceItems = []; // قائمة الأصناف في الفاتورة
  double _totalAmount = 0.0; // إجمالي مبلغ الفاتورة

  @override
  void initState() {
    super.initState();
    suppliersBox = Hive.box<Supplier>('suppliers_box'); // تهيئة صندوق الموردين
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');

    // تهيئة المتحكمات بناءً على ما إذا كنا نضيف فاتورة جديدة أو نعدل فاتورة موجودة
    if (widget.invoice == null) {
      // فاتورة شراء جديدة
      _invoiceNumberController = TextEditingController(text: _generateNewInvoiceNumber());
      _invoiceDateController = TextEditingController(text: _formatDate(DateTime.now()));
      _invoiceItems = [];
      _totalAmount = 0.0;
    } else {
      // تعديل فاتورة شراء موجودة
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _invoiceDateController = TextEditingController(text: _formatDate(widget.invoice!.invoiceDate));
      // استعادة المورد المختار من الفاتورة الموجودة
      _selectedSupplier = suppliersBox.values.firstWhereOrNull(
        (s) => s.name == widget.invoice!.supplierName, // البحث باسم المورد
      );
      _invoiceItems = List.from(widget.invoice!.items); // نسخ الأصناف الموجودة
      _calculateTotalAmount(); // إعادة حساب الإجمالي
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  // دالة لتوليد رقم فاتورة جديد (مثال بسيط)
  String _generateNewInvoiceNumber() {
    return 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  // دالة لتنسيق التاريخ (تم إصلاحها للتأكد)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // دالة لحساب الإجمالي الكلي للفاتورة
  void _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      // ⭐ هنا نستخدم سعر الشراء (buyingPrice) من الصنف الأصلي في المخزون،
      // وليس sellingPrice الخاص بالـ InvoiceItem، لأنه فاتورة شراء.
      final originalItem = itemsBox.get(item.itemId);
      if (originalItem != null) {
        total += item.quantity * originalItem.buyingPrice;
      } else {
        // في حالة لم يتم العثور على الصنف في المخزون (مثلاً تم حذفه)، نستخدم sellingPrice الموجود
        // (يمكنك تعديل هذا المنطق حسب الحاجة)
        total += item.quantity * item.sellingPrice;
      }
    }
    setState(() {
      _totalAmount = total;
    });
  }

  // دالة لحفظ الفاتورة
  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String invoiceNumber = _invoiceNumberController.text.trim();
      final DateTime invoiceDate = DateTime.parse(_invoiceDateController.text);

      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار مورد.')),
        );
        return;
      }

      if (_invoiceItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إضافة أصناف إلى الفاتورة.')),
        );
        return;
      }

      // ⭐ المنطق لزيادة الكميات في المخزون (لفاتورة الشراء)
      for (var invoiceItem in _invoiceItems) {
        final itemInInventory = itemsBox.get(invoiceItem.itemId);
        if (itemInInventory != null) {
          itemInInventory.quantity += invoiceItem.quantity; // ⭐ زيادة الكمية
          await itemsBox.put(itemInInventory.id, itemInInventory); // حفظ الصنف المحدث
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('الصنف "${invoiceItem.itemName}" غير موجود في المخزون ولا يمكن تحديثه.')),
          );
          // يمكنك اختيار إيقاف الحفظ أو السماح به مع تحذير
          return;
        }
      }

      final newInvoice = Invoice(
        id: widget.invoice?.id ?? uuid.v4(),
        invoiceNumber: invoiceNumber,
        supplierName: _selectedSupplier!.name, // ⭐ حفظ اسم المورد
        invoiceDate: invoiceDate,
        items: _invoiceItems,
        totalAmount: _totalAmount,
        type: InvoiceType.purchase, // ⭐ تحديد نوع الفاتورة كـ شراء
      );

      if (widget.invoice == null) {
        // إضافة فاتورة شراء جديدة
        await invoicesBox.put(newInvoice.id, newInvoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة فاتورة الشراء بنجاح!')),
        );
      } else {
        // تحديث فاتورة شراء موجودة
        // ملاحظة: في حالة التعديل على فاتورة شراء موجودة، يجب أن تكون حذرًا بشأن
        // منطق المخزون. إذا تم تغيير الكميات، قد تحتاج إلى:
        // 1. إعادة الكميات القديمة للمخزون
        // 2. خصم/زيادة الكميات الجديدة
        // للتبسيط، نحن نفترض أن الكميات التي تم إدخالها هي الإجمالي الذي سيضاف/يُخصم.
        // يمكننا إضافة منطق "العودة بالكميات" لاحقاً إذا لزم الأمر.
        await invoicesBox.put(widget.invoice!.key, newInvoice);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث فاتورة الشراء بنجاح!')),
        );
      }
      Navigator.of(context).pop(); // العودة إلى شاشة فواتير الشراء
    }
  }

  // دالة جديدة لاختيار الأصناف من المخزون
  Future<void> _selectItemsFromInventory() async {
    final List<InvoiceItem>? selectedItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemSelectionScreen(
          existingInvoiceItems: _invoiceItems, // تمرير الأصناف الموجودة لتحديدها مسبقاً
          // ⭐ يمكن إضافة معلمة لنوع الفاتورة هنا لتغيير السعر المعروض في ItemSelectionScreen
          // حاليا، ItemSelectionScreen يعرض سعر البيع، قد تحتاج لتعديله ليعرض سعر الشراء
          // أو السماح بتعديل السعر يدوياً في هذه الشاشة.
        ),
      ),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        _invoiceItems = selectedItems;
        _calculateTotalAmount();
      });
    }
  }

  // دالة لحذف صنف من قائمة أصناف الفاتورة
  void _deleteInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
      _calculateTotalAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'إضافة فاتورة شراء جديدة' : 'تعديل فاتورة شراء'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // حقول تفاصيل الفاتورة
              TextFormField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم فاتورة الشراء',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true, // رقم الفاتورة لا يتم تعديله يدوياً
              ),
              const SizedBox(height: 16),

              // ⭐ حقل اختيار المورد
              DropdownButtonFormField<Supplier>(
                value: _selectedSupplier,
                decoration: InputDecoration(
                  labelText: 'اختر المورد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('الرجاء اختيار مورد'),
                onChanged: (Supplier? newValue) {
                  setState(() {
                    _selectedSupplier = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'الرجاء اختيار مورد';
                  }
                  return null;
                },
                items: suppliersBox.values.map<DropdownMenuItem<Supplier>>((Supplier supplier) {
                  return DropdownMenuItem<Supplier>(
                    value: supplier,
                    child: Text(supplier.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _invoiceDateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ الفاتورة (YYYY-MM-DD)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _invoiceDateController.text = _formatDate(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // قسم أصناف الفاتورة
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'أصناف الفاتورة:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _invoiceItems.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد أصناف في الفاتورة.\nاضغط "إضافة صنف" لإضافة أصناف.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _invoiceItems.length,
                        itemBuilder: (context, index) {
                          final item = _invoiceItems[index];
                          // ⭐ نحتاج لإظهار سعر الشراء هنا.
                          // بما أن InvoiceItem لا يحتوي على buyingPrice،
                          // سنقوم بجلب الصنف الأصلي من المخزون لعرض سعر الشراء.
                          final originalItem = itemsBox.get(item.itemId);
                          final itemPrice = originalItem?.buyingPrice ?? item.sellingPrice; // استخدم سعر الشراء إذا وجد، وإلا سعر البيع المحفوظ
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 2,
                            child: ListTile(
                              title: Text('${item.itemName} (${item.quantity} ${item.unit})'),
                              subtitle: Text(
                                'السعر: ${itemPrice.toStringAsFixed(2)} | الإجمالي: ${(item.quantity * itemPrice).toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteInvoiceItem(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),

              // زر إضافة صنف (سيفتح شاشة اختيار الأصناف)
              ElevatedButton.icon(
                onPressed: _selectItemsFromInventory,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة صنف من المخزون'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // إجمالي الفاتورة
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'الإجمالي الكلي: ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
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
                  widget.invoice == null ? 'حفظ فاتورة الشراء' : 'تحديث فاتورة الشراء',
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

// ⭐ لتسهيل البحث عن المورد في initState
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
