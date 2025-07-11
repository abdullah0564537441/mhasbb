// lib/screens/add_edit_return_invoice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/invoice.dart';
import 'package:mhasbb/models/invoice_item.dart';
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/models/invoice_type.dart'; // ⭐⭐ هذا هو الاستيراد الذي كان مفقوداً ⭐⭐
// import 'package:mhasbb/models/return_invoice.dart'; // إذا كنت تستخدم موديل ReturnInvoice منفصل


class AddEditReturnInvoiceScreen extends StatefulWidget {
  // استخدام Invoice لتمثيل المرتجع بناءً على الكود الحالي.
  // إذا كان لديك موديل ReturnInvoice منفصل، قم بتغيير هذا إلى ReturnInvoice?
  final Invoice? returnInvoice;

  const AddEditReturnInvoiceScreen({super.key, this.returnInvoice});

  @override
  State<AddEditReturnInvoiceScreen> createState() => _AddEditReturnInvoiceScreenState();
}

class _AddEditReturnInvoiceScreenState extends State<AddEditReturnInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid uuid = const Uuid();

  late Box<Invoice> invoicesBox;
  late Box<Item> itemsBox;
  late Box<Customer> customersBox;
  late Box<Supplier> suppliersBox;
  // late Box<ReturnInvoice> returnInvoicesBox; // إذا كنت تستخدم صندوق ReturnInvoice منفصل

  InvoiceType? _returnType; // لتحديد ما إذا كان مرتجع بيع أو شراء
  Invoice? _selectedOriginalInvoice; // الفاتورة الأصلية التي يتم عمل المرتجع لها

  Customer? _selectedCustomer; // العميل المرتبط بالمرتجع (لمرتجع المبيعات)
  Supplier? _selectedSupplier; // المورد المرتبط بالمرتجع (لمرتجع المشتريات)

  final List<InvoiceItem> _returnedItems = []; // الأصناف التي سيتم إرجاعها
  late TextEditingController _returnNumberController;
  late TextEditingController _dateController;
  DateTime _selectedDate = DateTime.now();
  late PaymentMethod _paymentMethodForReturn; // طريقة الدفع لرد/تحصيل المبلغ

  @override
  void initState() {
    super.initState();
    invoicesBox = Hive.box<Invoice>('invoices_box');
    itemsBox = Hive.box<Item>('items_box');
    customersBox = Hive.box<Customer>('customers_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box');
    // returnInvoicesBox = Hive.box<ReturnInvoice>('return_invoices_box'); // إذا كنت تستخدم صندوق ReturnInvoice منفصل

    if (widget.returnInvoice == null) {
      // مرتجع جديد
      _returnNumberController = TextEditingController(text: 'الرجاء اختيار نوع المرتجع'); // لا نولد الرقم حتى يتم اختيار النوع
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _paymentMethodForReturn = PaymentMethod.cash; // افتراضي: نقدي
    } else {
      // تعديل مرتجع موجود (بافتراض أنه Invoice)
      _returnNumberController = TextEditingController(text: widget.returnInvoice!.invoiceNumber);
      _selectedDate = widget.returnInvoice!.date;
      _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));
      _returnType = widget.returnInvoice!.type;
      _returnedItems.addAll(List<InvoiceItem>.from(widget.returnInvoice!.items));
      _paymentMethodForReturn = widget.returnInvoice!.paymentMethod;

      if (widget.returnInvoice!.originalInvoiceId != null) {
        _selectedOriginalInvoice = invoicesBox.get(widget.returnInvoice!.originalInvoiceId);
      }
      if (widget.returnInvoice!.customerId != null) {
        _selectedCustomer = customersBox.get(widget.returnInvoice!.customerId);
      }
      if (widget.returnInvoice!.supplierId != null) {
        _selectedSupplier = suppliersBox.get(widget.returnInvoice!.supplierId);
      }
    }
  }

  @override
  void dispose() {
    _returnNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _generateNextReturnNumber(InvoiceType? type) {
    if (type == null) return 'الرجاء اختيار نوع المرتجع'; // لا نولد الرقم حتى يتم اختيار النوع

    String prefix = '';
    if (type == InvoiceType.salesReturn) {
      prefix = 'SR-'; // Sales Return
    } else if (type == InvoiceType.purchaseReturn) {
      prefix = 'PR-'; // Purchase Return
    }

    final allReturns = invoicesBox.values.where((inv) => inv.type == type).toList();
    int maxNumber = 0;
    for (var ret in allReturns) {
      if (ret.invoiceNumber.startsWith(prefix)) {
        try {
          int currentNumber = int.parse(ret.invoiceNumber.substring(prefix.length));
          if (currentNumber > maxNumber) {
            maxNumber = currentNumber;
          }
        } catch (e) {
          // Ignore errors for non-numeric parts after prefix
          debugPrint('Error parsing return number: ${ret.invoiceNumber} - $e');
        }
      }
    }
    return '$prefix${(maxNumber + 1).toString().padLeft(4, '0')}';
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

  // دالة لاختيار الفاتورة الأصلية (مبيعات للمرتجع، مشتريات للمرتجع)
  void _selectOriginalInvoice() {
    final bool isSalesReturn = (_returnType == InvoiceType.salesReturn);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSalesReturn ? 'اختر فاتورة المبيعات الأصلية' : 'اختر فاتورة المشتريات الأصلية'),
          content: SizedBox(
            width: double.maxFinite,
            child: ValueListenableBuilder<Box<Invoice>>(
              valueListenable: invoicesBox.listenable(),
              builder: (context, box, _) {
                final List<Invoice> invoices = box.values
                    .where((inv) => isSalesReturn ? inv.type == InvoiceType.sale : inv.type == InvoiceType.purchase)
                    .toList()
                    ..sort((a, b) => b.date.compareTo(a.date)); // الأحدث أولاً

                if (invoices.isEmpty) {
                  return Center(child: Text(isSalesReturn ? 'لا توجد فواتير مبيعات.' : 'لا توجد فواتير مشتريات.'));
                }

                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    // تأكد أن customerId/supplierId ليس null قبل محاولة الوصول إليه
                    final String partyName = isSalesReturn
                        ? (customersBox.get(invoice.customerId ?? '')?.name ?? 'عميل غير معروف')
                        : (suppliersBox.get(invoice.supplierId ?? '')?.name ?? 'مورد غير معروف');

                    return ListTile(
                      title: Text('رقم الفاتورة: ${invoice.invoiceNumber}'),
                      subtitle: Text(
                          'التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)} | ${isSalesReturn ? 'العميل' : 'المورد'}: $partyName'),
                      onTap: () {
                        setState(() {
                          _selectedOriginalInvoice = invoice;
                          // تعيين العميل/المورد بناءً على الفاتورة الأصلية
                          if (isSalesReturn) {
                            _selectedCustomer = customersBox.get(invoice.customerId);
                            _selectedSupplier = null;
                          } else {
                            _selectedSupplier = suppliersBox.get(invoice.supplierId);
                            _selectedCustomer = null;
                          }
                          // نسخ الأصناف من الفاتورة الأصلية كقائمة قابلة للتعديل
                          _returnedItems.clear();
                          _returnedItems.addAll(invoice.items.map((item) => InvoiceItem(
                            itemId: item.itemId,
                            itemName: item.itemName,
                            quantity: 0.0, // الكمية المرتجعة تبدأ من الصفر
                            sellingPrice: item.sellingPrice,
                            purchasePrice: item.purchasePrice,
                            unit: item.unit,
                          )));
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  // دالة لحساب الإجمالي للمرتجع (يتم استخدام سعر الشراء للمشتريات وسعر البيع للمبيعات)
  double _calculateTotalReturnAmount() {
    double total = 0.0;
    for (var item in _returnedItems) {
      if (_returnType == InvoiceType.salesReturn) {
        total += item.quantity * item.sellingPrice;
      } else if (_returnType == InvoiceType.purchaseReturn) {
        total += item.quantity * item.purchasePrice;
      }
    }
    return total;
  }

  Future<void> _saveReturnInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (_returnType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد نوع المرتجع (مبيعات أو مشتريات).')),
        );
        return;
      }
      if (_selectedOriginalInvoice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الفاتورة الأصلية للمرتجع.')),
        );
        return;
      }
      if (_returnedItems.every((item) => item.quantity == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد كمية واحدة على الأقل للمرتجع.')),
        );
        return;
      }

      _formKey.currentState!.save();

      final String returnNumber = _returnNumberController.text.trim();
      final String? partyId = _isSalesReturn() ? _selectedCustomer?.id : _selectedSupplier?.id;
      final String? partyName = _isSalesReturn() ? _selectedCustomer?.name : _selectedSupplier?.name;

      try {
        if (widget.returnInvoice == null) {
          // مرتجع جديد: تعديل المخزون
          for (var returnedItem in _returnedItems) {
            if (returnedItem.quantity > 0) {
              final itemInStock = itemsBox.get(returnedItem.itemId);
              if (itemInStock != null) {
                if (_returnType == InvoiceType.salesReturn) {
                  itemInStock.quantity += returnedItem.quantity; // مرتجع مبيعات: زيادة المخزون
                } else if (_returnType == InvoiceType.purchaseReturn) {
                  itemInStock.quantity -= returnedItem.quantity; // مرتجع مشتريات: نقص المخزون
                  if (itemInStock.quantity < 0) {
                     // يمكنك إضافة تحذير أو منع إذا كانت الكمية المرتجعة أكبر من الموجودة
                     debugPrint('Warning: Purchase return quantity exceeds stock for ${itemInStock.name}');
                  }
                }
                await itemInStock.save();
              }
            }
          }

          final newReturn = Invoice(
            id: uuid.v4(),
            invoiceNumber: returnNumber,
            type: _returnType!,
            date: _selectedDate,
            items: _returnedItems.where((item) => item.quantity > 0).toList(), // حفظ الأصناف ذات الكمية > 0
            customerId: _isSalesReturn() ? partyId : null,
            customerName: _isSalesReturn() ? partyName : null,
            supplierId: _isSalesReturn() ? null : partyId,
            supplierName: _isSalesReturn() ? null : partyName,
            paymentMethod: _paymentMethodForReturn, // طريقة الدفع لرد المبلغ/خصمه
            originalInvoiceId: _selectedOriginalInvoice!.id,
          );
          await invoicesBox.put(newReturn.id, newReturn);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إضافة ${_getReturnTypeName(_returnType!)} بنجاح!')),
          );
        } else {
          // تعديل مرتجع موجود:
          // هذه عملية أكثر تعقيداً تتطلب استعادة الكميات الأصلية للمرتجع أولاً،
          // ثم تطبيق الكميات الجديدة. للحفاظ على التركيز، لن نطبقها هنا،
          // ولكن الفكرة هي عكس تأثير المرتجع القديم ثم تطبيق الجديد.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعديل المرتجعات غير مدعوم حالياً بهذه البساطة.')),
          );
          return;
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ المرتجع: $e')),
        );
        debugPrint('Hive Save Error: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إكمال جميع الحقول المطلوبة بشكل صحيح.')),
      );
    }
  }

  bool _isSalesReturn() => _returnType == InvoiceType.salesReturn;

  String _getReturnTypeName(InvoiceType type) {
    if (type == InvoiceType.salesReturn) {
      return 'مرتجع مبيعات';
    } else if (type == InvoiceType.purchaseReturn) {
      return 'مرتجع مشتريات';
    }
    return 'مرتجع';
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.credit:
        return 'خصم من حساب'; // يمكن تغييرها إلى 'خصم من حساب' أو 'زيادة في الحساب' حسب السياق
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
        title: Text(widget.returnInvoice == null ? 'إضافة مرتجع' : 'تعديل مرتجع'),
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
                  DropdownButtonFormField<InvoiceType>(
                    decoration: InputDecoration(
                      labelText: 'نوع المرتجع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.swap_horiz),
                    ),
                    value: _returnType,
                    onChanged: (type) {
                      setState(() {
                        _returnType = type;
                        _returnNumberController.text = _generateNextReturnNumber(type);
                        _selectedOriginalInvoice = null; // إعادة تعيين الفاتورة الأصلية عند تغيير النوع
                        _returnedItems.clear(); // مسح الأصناف المرتجعة
                        _selectedCustomer = null;
                        _selectedSupplier = null;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: InvoiceType.salesReturn,
                        child: Text('مرتجع مبيعات'),
                      ),
                      DropdownMenuItem(
                        value: InvoiceType.purchaseReturn,
                        child: Text('مرتجع مشتريات'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار نوع المرتجع';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _returnNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم المرتجع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال رقم المرتجع';
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
                  // زر لاختيار الفاتورة الأصلية
                  ElevatedButton.icon(
                    onPressed: _returnType != null ? _selectOriginalInvoice : null,
                    icon: const Icon(Icons.receipt),
                    label: Text(_selectedOriginalInvoice == null
                        ? 'اختر الفاتورة الأصلية'
                        : 'الفاتورة الأصلية: ${_selectedOriginalInvoice!.invoiceNumber}'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  if (_selectedOriginalInvoice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'الطرف: ${_isSalesReturn() ? (_selectedCustomer?.name ?? 'غير معروف') : (_selectedSupplier?.name ?? 'غير معروف')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // ⭐ حقل طريقة الدفع للمرتجع
                    DropdownButtonFormField<PaymentMethod>(
                      decoration: InputDecoration(
                        labelText: 'طريقة رد/خصم المبلغ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.payment),
                      ),
                      value: _paymentMethodForReturn,
                      items: PaymentMethod.values.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(_getPaymentMethodDisplayName(method)),
                        );
                      }).toList(),
                      onChanged: (method) {
                        if (method != null) {
                          setState(() {
                            _paymentMethodForReturn = method;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار طريقة رد/خصم المبلغ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الأصناف المرتجعة:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _returnedItems.isEmpty
                        ? const Text('الرجاء اختيار فاتورة لتحديد الأصناف المرتجعة.')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _returnedItems.length,
                            itemBuilder: (context, index) {
                              final item = _returnedItems[index];
                              final originalInvoiceItem = _selectedOriginalInvoice!.items
                                  .firstWhere((element) => element.itemId == item.itemId);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          'الكمية الأصلية: ${originalInvoiceItem.quantity} ${item.unit}'),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.quantity.toString(),
                                              decoration: InputDecoration(
                                                labelText: 'كمية المرتجع (${item.unit})',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                isDense: true,
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) {
                                                setState(() {
                                                  final double newQuantity = double.tryParse(value) ?? 0.0;
                                                  // لا يمكن إرجاع كمية أكبر من الكمية الأصلية
                                                  if (newQuantity <= originalInvoiceItem.quantity) {
                                                    item.quantity = newQuantity;
                                                  } else {
                                                    item.quantity = originalInvoiceItem.quantity;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('لا يمكن إرجاع كمية أكبر من الكمية الأصلية (${originalInvoiceItem.quantity}).')),
                                                    );
                                                  }
                                                });
                                              },
                                              validator: (value) {
                                                final double? qty = double.tryParse(value ?? '');
                                                if (qty == null || qty < 0) {
                                                  return 'كمية غير صحيحة';
                                                }
                                                if (qty > originalInvoiceItem.quantity) {
                                                  return 'يجب ألا تزيد عن الكمية الأصلية';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // يمكنك إضافة زر لإزالة الصنف إذا لم يكن هناك مرتجع منه
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _returnedItems.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                    Text(
                      'الإجمالي الكلي للمرتجع: ${NumberFormat('#,##0.00', 'en_US').format(_calculateTotalReturnAmount())}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveReturnInvoice,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  widget.returnInvoice == null ? 'حفظ المرتجع' : 'تحديث المرتجع',
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
