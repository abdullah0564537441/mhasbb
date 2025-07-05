import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mhasbb/models/supplier.dart'; // استيراد موديل المورد
import 'package:mhasbb/screens/add_edit_supplier_screen.dart'; // استيراد شاشة إضافة/تعديل المورد

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late Box<Supplier> suppliersBox; // صندوق Hive للموردين

  @override
  void initState() {
    super.initState();
    // فتح صندوق الموردين عند تهيئة الشاشة
    suppliersBox = Hive.box<Supplier>('suppliers_box');
  }

  // دالة لتأكيد وحذف المورد
  void _confirmAndDeleteSupplier(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف المورد "${supplier.name}"؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await supplier.delete(); // حذف المورد من Hive
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المورد بنجاح!')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردون'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Supplier>>(
        valueListenable: suppliersBox.listenable(),
        builder: (context, box, _) {
          final suppliers = box.values.toList().cast<Supplier>(); // جلب جميع الموردين

          if (suppliers.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد موردون حتى الآن.\nاضغط على "+" لإضافة مورد جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const Icon(Icons.person, size: 40, color: Colors.purple),
                  title: Text(
                    supplier.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supplier.phoneNumber != null && supplier.phoneNumber!.isNotEmpty)
                        Text('الهاتف: ${supplier.phoneNumber}'),
                      if (supplier.address != null && supplier.address!.isNotEmpty)
                        Text('العنوان: ${supplier.address}'),
                      if (supplier.email != null && supplier.email!.isNotEmpty)
                        Text('البريد الإلكتروني: ${supplier.email}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // التنقل لشاشة التعديل مع تمرير المورد الحالي
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditSupplierScreen(supplier: supplier),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmAndDeleteSupplier(context, supplier),
                      ),
                    ],
                  ),
                  onTap: () {
                    // يمكنك إضافة شاشة لعرض تفاصيل المورد هنا
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // التنقل لإضافة مورد جديد
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditSupplierScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
