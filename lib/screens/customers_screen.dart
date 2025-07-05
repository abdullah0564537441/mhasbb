// lib/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // لتوليد معرفات فريدة للعملاء
import 'package:mhasbb/models/customer.dart'; // تأكد من استيراد نموذج العميل الخاص بك

// --- شاشة عرض وإدارة العملاء ---
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Box<Customer> customersBox;

  @override
  void initState() {
    super.initState();
    // تهيئة صندوق Hive للعملاء
    customersBox = Hive.box<Customer>('customers_box');
  }

  // دالة لحذف العميل
  Future<void> _deleteCustomer(Customer customer) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف العميل "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await customer.delete(); // حذف العميل من Hive
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف العميل بنجاح!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Customer>>(
        valueListenable: customersBox.listenable(), // الاستماع للتغييرات في صندوق العملاء
        builder: (context, box, _) {
          final customers = box.values.toList().cast<Customer>(); // جلب جميع العملاء

          if (customers.isEmpty) {
            return const Center(
              child: Text('لا توجد عملاء حتى الآن.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4.0,
                child: ListTile(
                  title: Text(customer.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                        Text('الهاتف: ${customer.phoneNumber}'),
                      if (customer.address != null && customer.address!.isNotEmpty)
                        Text('العنوان: ${customer.address}'),
                      if (customer.email != null && customer.email!.isNotEmpty)
                        Text('البريد الإلكتروني: ${customer.email}'),
                      if (customer.notes != null && customer.notes!.isNotEmpty)
                        Text('ملاحظات: ${customer.notes}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // الانتقال لشاشة التعديل (أو نفس شاشة الإضافة مع تمرير العميل)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditCustomerScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCustomer(customer),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // الانتقال لشاشة إضافة عميل جديد
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditCustomerScreen(), // شاشة فارغة لإضافة عميل جديد
            ),
          );
        },
        label: const Text('إضافة عميل'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- شاشة إضافة وتعديل العملاء ---
class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // يمكن أن يكون null لإضافة عميل جديد، أو يحتوي على عميل للتعديل

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid uuid = const Uuid(); // لتوليد معرف فريد

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  late Box<Customer> customersBox;

  @override
  void initState() {
    super.initState();
    customersBox = Hive.box<Customer>('customers_box');

    // تهيئة Controllers بناءً على إذا كان العميل موجوداً أم لا (للتعديل أو الإضافة)
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _notesController = TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String name = _nameController.text.trim();
      final String? phoneNumber = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final String? address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
      final String? email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      final String? notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      try {
        if (widget.customer == null) {
          // إضافة عميل جديد
          final newCustomer = Customer(
            id: uuid.v4(),
            name: name,
            phoneNumber: phoneNumber,
            address: address,
            email: email,
            notes: notes,
          );
          await customersBox.put(newCustomer.id, newCustomer);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة العميل بنجاح!')),
          );
        } else {
          // تعديل عميل موجود
          final existingCustomer = widget.customer!;
          existingCustomer.name = name;
          existingCustomer.phoneNumber = phoneNumber;
          existingCustomer.address = address;
          existingCustomer.email = email;
          existingCustomer.notes = notes;
          await existingCustomer.save(); // حفظ التغييرات على الكائن الموجود
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث بيانات العميل بنجاح!')),
          );
        }
        Navigator.of(context).pop(); // العودة إلى شاشة العملاء
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ العميل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم العميل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم العميل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
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
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveCustomer,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(widget.customer == null ? Icons.save : Icons.update),
              label: Text(
                widget.customer == null ? 'حفظ العميل' : 'تحديث العميل',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
