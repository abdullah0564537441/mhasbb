// lib/screens/add_edit_voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:mhasbb/models/voucher.dart';
import 'package:mhasbb/models/voucher_type.dart';
import 'package:mhasbb/models/payment_method.dart';
import 'package:mhasbb/models/customer.dart';
import 'package:mhasbb/models/supplier.dart';

class AddEditVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const AddEditVoucherScreen({super.key, this.voucher});

  @override
  State<AddEditVoucherScreen> createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _voucherNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController(); // لإضافة وصف/بيان

  DateTime _selectedDate = DateTime.now();
  VoucherType? _selectedVoucherType;
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.cash;

  String? _selectedPartyType; // 'Customer', 'Supplier', 'Other'
  String? _selectedPartyId;
  String? _selectedPartyName;

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadParties();
    if (widget.voucher != null) {
      _voucherNumberController.text = widget.voucher!.voucherNumber;
      _amountController.text = widget.voucher!.amount.toString();
      _selectedDate = widget.voucher!.date;
      _selectedVoucherType = widget.voucher!.type;
      _selectedPaymentMethod = widget.voucher!.paymentMethod;
      _descriptionController.text = widget.voucher!.description ?? ''; // ⭐⭐ تم التصحيح هنا ⭐⭐
      _selectedPartyId = widget.voucher!.partyId; // ⭐⭐ تم التصحيح هنا ⭐⭐
      _selectedPartyName = widget.voucher!.partyName; // ⭐⭐ تم التصحيح هنا ⭐⭐
      _selectedPartyType = widget.voucher!.partyType; // ⭐⭐ تم التصحيح هنا ⭐⭐
    } else {
      _voucherNumberController.text = 'VOU-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}'; // رقم تلقائي
    }
  }

  Future<void> _loadParties() async {
    final customerBox = Hive.box<Customer>('customers_box');
    final supplierBox = Hive.box<Supplier>('suppliers_box');
    setState(() {
      _customers = customerBox.values.toList();
      _suppliers = supplierBox.values.toList();
    });
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
      });
    }
  }

  Future<void> _saveVoucher() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final voucherBox = Hive.box<Voucher>('vouchers_box');

      if (widget.voucher == null) {
        final newVoucher = Voucher(
          id: const Uuid().v4(),
          voucherNumber: _voucherNumberController.text,
          type: _selectedVoucherType!,
          date: _selectedDate,
          amount: double.parse(_amountController.text),
          paymentMethod: _selectedPaymentMethod!,
          partyId: _selectedPartyId,
          partyName: _selectedPartyName,
          partyType: _selectedPartyType,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null, // ⭐⭐ تم إضافة الحقل هنا ⭐⭐
        );
        await voucherBox.put(newVoucher.id, newVoucher);
      } else {
        widget.voucher!.voucherNumber = _voucherNumberController.text;
        widget.voucher!.amount = double.parse(_amountController.text);
        widget.voucher!.date = _selectedDate;
        widget.voucher!.type = _selectedVoucherType!;
        widget.voucher!.paymentMethod = _selectedPaymentMethod!;
        widget.voucher!.partyId = _selectedPartyId;
        widget.voucher!.partyName = _selectedPartyName;
        widget.voucher!.partyType = _selectedPartyType;
        widget.voucher!.description = _descriptionController.text.isNotEmpty ? _descriptionController.text : null; // ⭐⭐ تم تحديث الحقل هنا ⭐⭐
        await widget.voucher!.save();
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السند بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'إضافة سند' : 'تعديل سند'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _voucherNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم السند',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم السند';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ السند',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'الرجاء إدخال مبلغ صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<VoucherType>(
              value: _selectedVoucherType,
              decoration: const InputDecoration(
                labelText: 'نوع السند',
                border: OutlineInputBorder(),
              ),
              hint: const Text('اختر نوع السند'),
              onChanged: (newValue) {
                setState(() {
                  _selectedVoucherType = newValue;
                });
              },
              items: VoucherType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == VoucherType.receipt ? 'سند قبض' : 'سند صرف'),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'الرجاء اختيار نوع السند';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع/القبض',
                border: OutlineInputBorder(),
              ),
              onChanged: (newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue;
                });
              },
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method == PaymentMethod.cash ? 'نقدي' : 'شيك/تحويل'),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'الرجاء اختيار طريقة الدفع/القبض';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedPartyType,
              decoration: const InputDecoration(
                labelText: 'نوع الطرف (عميل/مورد/آخر)',
                border: OutlineInputBorder(),
              ),
              hint: const Text('اختر نوع الطرف'),
              onChanged: (newValue) {
                setState(() {
                  _selectedPartyType = newValue;
                  _selectedPartyId = null; // إعادة تعيين الطرف المحدد عند تغيير النوع
                  _selectedPartyName = null;
                });
              },
              items: const [
                DropdownMenuItem(value: 'Customer', child: Text('عميل')),
                DropdownMenuItem(value: 'Supplier', child: Text('مورد')),
                DropdownMenuItem(value: 'Other', child: Text('طرف آخر')),
              ],
            ),
            const SizedBox(height: 15),
            if (_selectedPartyType == 'Customer')
              DropdownButtonFormField<String>(
                value: _selectedPartyId,
                decoration: const InputDecoration(
                  labelText: 'العميل',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('اختر العميل'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPartyId = newValue;
                    _selectedPartyName = _customers.firstWhere((c) => c.id == newValue).name;
                  });
                },
                items: _customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer.id,
                    child: Text(customer.name),
                  );
                }).toList(),
              ),
            if (_selectedPartyType == 'Supplier')
              DropdownButtonFormField<String>(
                value: _selectedPartyId,
                decoration: const InputDecoration(
                  labelText: 'المورد',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('اختر المورد'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPartyId = newValue;
                    _selectedPartyName = _suppliers.firstWhere((s) => s.id == newValue).name;
                  });
                },
                items: _suppliers.map((supplier) {
                  return DropdownMenuItem(
                    value: supplier.id,
                    child: Text(supplier.name),
                  );
                }).toList(),
              ),
            if (_selectedPartyType == 'Other')
              TextFormField(
                initialValue: _selectedPartyName, // استخدم هذا لعرض الاسم إذا كان "آخر"
                decoration: const InputDecoration(
                  labelText: 'اسم الطرف الآخر',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedPartyName = value;
                    _selectedPartyId = null; // لا يوجد ID لـ "آخر"
                  });
                },
                validator: (value) {
                  if (_selectedPartyType == 'Other' && (value == null || value.isEmpty)) {
                    return 'الرجاء إدخال اسم الطرف الآخر';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'البيان/الوصف (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveVoucher,
              icon: const Icon(Icons.save),
              label: const Text('حفظ السند'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voucherNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
