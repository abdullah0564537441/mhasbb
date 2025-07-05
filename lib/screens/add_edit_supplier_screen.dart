import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // لتوليد معرفات فريدة

import 'package:mhasbb/models/supplier.dart'; // استيراد موديل المورد

class AddEditSupplierScreen extends StatefulWidget {
  final Supplier? supplier; // المورد الذي سيتم تعديله (يمكن أن يكون null للإضافة)

  const AddEditSupplierScreen({super.key, this.supplier});

  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

  // المتحكمات (Controllers) لحقول الإدخال
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  late Box<Supplier> suppliersBox; // صندوق Hive للموردين
  final Uuid uuid = const Uuid(); // لتوليد معرفات فريدة

  @override
  void initState() {
    super.initState();
    suppliersBox = Hive.box<Supplier>('suppliers_box'); // تهيئة صندوق الموردين

    // تهيئة المتحكمات بناءً على ما إذا كنا نضيف موردًا جديدًا أو نعدل موردًا موجودًا
    if (widget.supplier == null) {
      // مورد جديد
      _nameController = TextEditingController();
      _phoneNumberController = TextEditingController();
      _addressController = TextEditingController();
      _emailController = TextEditingController();
      _notesController = TextEditingController();
    } else {
      // تعديل مورد موجود
      _nameController = TextEditingController(text: widget.supplier!.name);
      _phoneNumberController = TextEditingController(text: widget.supplier!.phoneNumber);
      _addressController = TextEditingController(text: widget.supplier!.address);
      _emailController = TextEditingController(text: widget.supplier!.email);
      _notesController = TextEditingController(text: widget.supplier!.notes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // دالة لحفظ المورد
  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String name = _nameController.text.trim();
      final String? phoneNumber = _phoneNumberController.text.trim().isNotEmpty ? _phoneNumberController.text.trim() : null;
      final String? address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null;
      final String? email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null;
      final String? notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

      if (widget.supplier == null) {
        // إضافة مورد جديد
        final newSupplier = Supplier(
          id: uuid.v4(), // توليد معرف فريد جديد
          name: name,
          phoneNumber: phoneNumber,
          address: address,
          email: email,
          notes: notes,
        );
        await suppliersBox.put(newSupplier.id, newSupplier); // حفظ المورد في Hive باستخدام الـ ID كـ key
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المورد بنجاح!')),
        );
      } else {
        // تحديث مورد موجود
        final existingSupplier = widget.supplier!;
        existingSupplier.name = name;
        existingSupplier.phoneNumber = phoneNumber;
        existingSupplier.address = address;
        existingSupplier.email = email;
        existingSupplier.notes = notes;

        await existingSupplier.save(); // حفظ التغييرات على المورد الموجود
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المورد بنجاح!')),
        );
      }
      Navigator.of(context).pop(); // العودة إلى شاشة الموردين
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'إضافة مورد جديد' : 'تعديل مورد'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView( // استخدام ListView للسماح بالتمرير إذا كانت الحقول كثيرة
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المورد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال اسم المورد';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2, // للسماح بإدخال عنوان أطول
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3, // للسماح بإدخال ملاحظات أطول
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveSupplier,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  widget.supplier == null ? 'حفظ المورد' : 'تحديث المورد',
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
