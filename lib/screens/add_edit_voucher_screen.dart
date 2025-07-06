// lib/screens/add_edit_voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/models/customer.dart'; // لاستخدام العملاء
import 'package:mhasbb/models/supplier.dart'; // لاستخدام الموردين

class AddEditVoucherScreen extends StatefulWidget {
  final Voucher? voucher; // السند المراد تعديله، null للإضافة

  const AddEditVoucherScreen({super.key, this.voucher});

  @override
  State<AddEditVoucherScreen> createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  late Box<Voucher> vouchersBox;
  late Box<Customer> customersBox;
  late Box<Supplier> suppliersBox;
  final Uuid _uuid = const Uuid();

  late String _id;
  late String _voucherNumber;
  late VoucherType _type;
  late DateTime _date;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _paymentMethodController;
  String? _selectedRelatedPartyId;
  String? _selectedRelatedPartyName;

  @override
  void initState() {
    super.initState();
    vouchersBox = Hive.box<Voucher>('vouchers_box');
    customersBox = Hive.box<Customer>('customers_box');
    suppliersBox = Hive.box<Supplier>('suppliers_box');

    if (widget.voucher == null) {
      // وضع افتراضيات لسند جديد
      _id = _uuid.v4();
      _voucherNumber = _generateNextVoucherNumber(VoucherType.income); // افتراضي قبض
      _type = VoucherType.income;
      _date = DateTime.now();
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _paymentMethodController = TextEditingController(text: 'نقدي'); // افتراضي نقدي
      _selectedRelatedPartyId = null;
      _selectedRelatedPartyName = null;
    } else {
      // تهيئة الواجهة بسند موجود للتعديل
      _id = widget.voucher!.id;
      _voucherNumber = widget.voucher!.voucherNumber;
      _type = widget.voucher!.type;
      _date = widget.voucher!.date;
      _amountController = TextEditingController(text: widget.voucher!.amount.toString());
      _descriptionController = TextEditingController(text: widget.voucher!.description);
      _paymentMethodController = TextEditingController(text: widget.voucher!.paymentMethod);
      _selectedRelatedPartyId = widget.voucher!.relatedPartyId;
      _selectedRelatedPartyName = widget.voucher!.relatedPartyName;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  // توليد رقم السند التالي بناءً على النوع (صرف/قبض)
  String _generateNextVoucherNumber(VoucherType type) {
    final allVouchers = vouchersBox.values.where((v) => v.type == type).toList();
    if (allVouchers.isEmpty) {
      return type == VoucherType.income ? 'QV-0001' : 'DV-0001'; // QV: سند قبض، DV: سند صرف
    }
    allVouchers.sort((a, b) => a.voucherNumber.compareTo(b.voucherNumber));
    final lastNumber = allVouchers.last.voucherNumber;
    final parts = lastNumber.split('-');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      try {
        int num = int.parse(parts[1]);
        return '${parts[0]}-${(num + 1).toString().padLeft(4, '0')}';
      } catch (e) {
        // Fallback if parsing fails
      }
    }
    return type == VoucherType.income ? 'QV-0001' : 'DV-0001';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveVoucher() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newVoucher = Voucher(
        id: _id,
        voucherNumber: _voucherNumber,
        type: _type,
        date: _date,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        relatedPartyId: _selectedRelatedPartyId,
        relatedPartyName: _selectedRelatedPartyName,
        paymentMethod: _paymentMethodController.text,
      );

      try {
        await vouchersBox.put(newVoucher.id, newVoucher);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.voucher == null ? 'تمت إضافة السند بنجاح.' : 'تم تعديل السند بنجاح.'),
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ السند: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // قائمة الأطراف المرتبطة (عملاء وموردين)
    final List<dynamic> allParties = [
      ...customersBox.values.toList().cast<Customer>(),
      ...suppliersBox.values.toList().cast<Supplier>(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'إضافة سند جديد' : 'تعديل سند'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // اختيار نوع السند (صرف/قبض)
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<VoucherType>(
                      title: const Text('سند قبض'),
                      value: VoucherType.income,
                      groupValue: _type,
                      onChanged: (VoucherType? value) {
                        setState(() {
                          _type = value!;
                          if (widget.voucher == null) { // فقط إذا كان سند جديد
                            _voucherNumber = _generateNextVoucherNumber(_type);
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<VoucherType>(
                      title: const Text('سند صرف'),
                      value: VoucherType.expense,
                      groupValue: _type,
                      onChanged: (VoucherType? value) {
                        setState(() {
                          _type = value!;
                          if (widget.voucher == null) { // فقط إذا كان سند جديد
                            _voucherNumber = _generateNextVoucherNumber(_type);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // رقم السند (للقراءة فقط في وضع التعديل)
              TextFormField(
                initialValue: _voucherNumber,
                readOnly: true, // عادة ما يكون رقم السند للقراءة فقط
                decoration: const InputDecoration(
                  labelText: 'رقم السند',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // التاريخ
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  hintText: 'أدخل المبلغ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المبلغ';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // البيان/الوصف
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'البيان / الوصف',
                  hintText: 'وصف السند',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال البيان / الوصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // الطرف المرتبط (عميل أو مورد)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'الطرف المرتبط (اختياري)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedRelatedPartyId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRelatedPartyId = newValue;
                    if (newValue != null) {
                      final selectedParty = allParties.firstWhere((p) => p.id == newValue);
                      _selectedRelatedPartyName = selectedParty.name;
                    } else {
                      _selectedRelatedPartyName = null;
                    }
                  });
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('بدون طرف مرتبط'),
                  ),
                  ...allParties.map((party) {
                    return DropdownMenuItem<String>(
                      value: party.id,
                      child: Text('${party.name} (${party is Customer ? 'عميل' : 'مورد'})'),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 15),

              // طريقة الدفع/القبض
              TextFormField(
                controller: _paymentMethodController,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع/القبض',
                  hintText: 'مثال: نقدي، تحويل بنكي، شيك',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال طريقة الدفع/القبض';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              ElevatedButton.icon(
                onPressed: _saveVoucher,
                icon: const Icon(Icons.save),
                label: Text(widget.voucher == null ? 'حفظ السند' : 'تعديل السند'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
