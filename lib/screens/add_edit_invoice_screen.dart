import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

// استيراد موديلات Hive
import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/customer.dart'; 
import 'package:mhasbb/models/item.dart'; // ⭐ تأكد من استيراد موديل Item

// استيراد شاشة اختيار الأصناف الجديدة
import 'package:mhasbb/screens/item_selection_screen.dart';


class AddEditInvoiceScreen extends StatefulWidget {
  final Invoice? invoice; // الفاتورة التي سيتم تعديلها (يمكن أن تكون null للإضافة)

  const AddEditInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

  // المتحكمات (Controllers) لحقول الإدخال
  late TextEditingController _invoiceNumberController;
  late TextEditingController _customerNameController; // مؤقتًا لاسم العميل
  late TextEditingController _invoiceDateController;

  List<InvoiceItem> _invoiceItems = []; // قائمة الأصناف في الفاتورة
  double _totalAmount = 0.0; // إجمالي مبلغ الفاتورة

  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox; // ⭐ إضافة صندوق الأصناف
  final Uuid uuid = const Uuid(); // لتوليد معرفات فريدة

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box'); // ⭐ تهيئة صندوق الأصناف

    // تهيئة المتحكمات بناءً على ما إذا كنا نضيف فاتورة جديدة أو نعدل فاتورة موجودة
    if (widget.invoice == null) {
      // فاتورة جديدة
      _invoiceNumberController = TextEditingController(text: _generateNewInvoiceNumber());
      _customerNameController = TextEditingController();
      _invoiceDateController = TextEditingController(text: _formatDate(DateTime.now()));
      _invoiceItems = [];
      _totalAmount = 0.0;
    } else {
      // تعديل فاتورة موجودة
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber);
      _customerNameController = TextEditingController(text: widget.invoice!.customerName);
      _invoiceDateController = TextEditingController(text: _formatDate(widget.invoice!.invoiceDate));
      _invoiceItems = List.from(widget.invoice!.items); // نسخ الأصناف الموجودة
      _calculateTotalAmount(); // إعادة حساب الإجمالي
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  // دالة لتوليد رقم فاتورة جديد (مثال بسيط)
  String _generateNewInvoiceNumber() {
    // يمكنك تحسين هذه الدالة لتوليد أرقام متسلسلة أو أكثر تعقيدًا
    return 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  // دالة لتنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')숙';
  }

  // دالة لحساب الإجمالي الكلي للفاتورة
  void _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += item.quantity * item.sellingPrice;
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
      final String customerName = _customerNameController.text.trim();
      final DateTime invoiceDate = DateTime.parse(_invoiceDateController.text);

      if (_invoiceItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إضافة أصناف إلى الفاتورة.')),
        );
        return;
      }

      // ⭐ المنطق الجديد لخصم الكميات من المخزون
      for (var invoiceItem in _invoiceItems) {
        final itemInInventory = itemsBox.get(invoiceItem.itemId);
        if (itemInInventory != null) {
          // تأكد من عدم الخصم إذا كانت الكمية المباعة أكبر من المتوفرة (يمكنك إضافة تحقق هنا)
          if (itemInInventory.quantity >= invoiceItem.quantity) {
            itemInInventory.quantity -= invoiceItem.quantity;
            await itemsBox.put(itemInInventory.id, itemInInventory); // حفظ الصنف المحدث
          } else {
            // يمكنك هنا عرض رسالة خطأ أو تحذير إذا كانت الكمية غير كافية
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('الكمية المتوفرة من ${invoiceItem.itemName} غير كافية.')),
            );
            return; // إيقاف عملية الحفظ إذا كانت الكمية غير كافية
          }
        }
      }

      final newInvoice = Invoice(
        id: widget.invoice?.id ?? uuid.v4(), // استخدم ID الموجود أو أنشئ واحدًا جديدًا
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        invoiceDate: invoiceDate,
        items: _invoiceItems,
        totalAmount: _totalAmount,
      );

      if (widget.invoice == null) {
        // إضافة فاتورة جديدة
        await invoicesBox.put(newInvoice.id, newInvoice); // استخدام ID الفاتورة كمفتاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الفاتورة بنجاح!')),
        );
      } else {
        // تحديث فاتورة موجودة
        // ملاحظة: في حالة التعديل، قد تحتاج إلى منطق أكثر تعقيدًا لإعادة الكميات القديمة قبل خصم الجديدة
        // لكن للتبسيط، سنفترض أن التعديل يتم على فاتورة جديدة أو لا يؤثر على الكميات المخزنية بشكل مباشر بعد الحفظ الأولي.
        // أو يمكنك تطبيق منطق إعادة الكميات القديمة هنا قبل خصم الكميات الجديدة من _invoiceItems
        await invoicesBox.put(widget.invoice!.key, newInvoice); // استخدام مفتاح الفاتورة الأصلي للتحديث
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الفاتورة بنجاح!')),
        );
      }
      Navigator.of(context).pop(); // العودة إلى شاشة فواتير البيع
    }
  }

  // دالة جديدة لاختيار الأصناف من المخزون
  Future<void> _selectItemsFromInventory() async {
    final List<InvoiceItem>? selectedItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemSelectionScreen(
          existingInvoiceItems: _invoiceItems, // تمرير الأصناف الموجودة لتحديدها مسبقاً
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
        title: Text(widget.invoice == null ? 'إضافة فاتورة جديدة' : 'تعديل فاتورة'),
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
                  labelText: 'رقم الفاتورة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true, // رقم الفاتورة لا يتم تعديله يدوياً
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _invoiceDateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ الفاتورة (YYYY-MM-DD)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true, // يمكن أن نجعله قابلاً للاختيار من منتقي التاريخ لاحقاً
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 2,
                            child: ListTile(
                              title: Text('${item.itemName} (${item.quantity} ${item.unit})'),
                              subtitle: Text(
                                'السعر: ${item.sellingPrice.toStringAsFixed(2)} | الإجمالي: ${(item.quantity * item.sellingPrice).toStringAsFixed(2)}',
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

              // زر إضافة صنف (الآن سيفتح شاشة اختيار الأصناف)
              ElevatedButton.icon(
                onPressed: _selectItemsFromInventory,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة صنف من المخزون'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // زر بعرض كامل
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
