import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // لاستخدام ValueListenableBuilder ومراقبة الصندوق

// استيراد موديل الصنف (Item)
import 'package:mhasbb/models/item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Box<Item> itemsBox; // صندوق Hive الخاص بالأصناف

  @override
  void initState() {
    super.initState();
    // فتح صندوق الأصناف عند تهيئة الشاشة
    itemsBox = Hive.box<Item>('items_box');
  }

  // دالة لعرض نافذة التأكيد وحذف الصنف
  void _confirmAndDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف الصنف "${item.name}"؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('لا', style: TextStyle(color: Colors.indigo)),
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق نافذة التأكيد
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // لون أحمر لزر الحذف
                foregroundColor: Colors.white,
              ),
              child: const Text('نعم، احذف', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // حذف الصنف من Hive باستخدام مفتاحه (key)
                if (item.key != null) {
                  itemsBox.delete(item.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الصنف بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('خطأ: لا يمكن العثور على مفتاح الصنف للحذف.')),
                  );
                }
                Navigator.of(context).pop(); // إغلاق نافذة التأكيد
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
        title: const Text('المخزون'),
        centerTitle: true,
      ),
      // استخدام ValueListenableBuilder لمراقبة التغييرات في صندوق Hive
      // هذا سيضمن تحديث الواجهة تلقائيًا عند إضافة/حذف/تعديل الأصناف
      body: ValueListenableBuilder<Box<Item>>(
        valueListenable: itemsBox.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أصناف في المخزون حتى الآن.\nاضغط على "+" لإضافة صنف جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // عرض قائمة الأصناف الموجودة
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final item = box.getAt(index); // الحصول على الصنف من الصندوق

              // تأكد أن الصنف ليس null قبل محاولة عرضه
              if (item == null) {
                return const SizedBox.shrink(); // لا تعرض شيئًا إذا كان الصنف null
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const Icon(Icons.inventory_2, size: 40, color: Colors.teal),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('الكمية: ${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey[700])),
                      Text('سعر الشراء: ${item.purchasePrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700])),
                      Text('سعر البيع: ${item.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () {
                          // ⭐ هنا سننتقل إلى شاشة تفاصيل/تعديل الصنف (سننشئها لاحقاً)
                          print('View/Edit item: ${item.name}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('سيتم فتح شاشة تعديل الصنف هنا')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmAndDeleteItem(context, item); // استدعاء دالة التأكيد والحذف
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    print('Tapped on item: ${item.name}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النقر على الصنف (يمكنك تعديل هذا السلوك)')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ⭐ هنا سننتقل إلى شاشة إضافة صنف جديد (سننشئها لاحقاً)
          print('Add New Item button pressed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سيتم فتح شاشة إضافة صنف جديد هنا')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
