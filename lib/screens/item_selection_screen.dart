import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// استيراد موديلات Hive
import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/models/invoice_item.dart';

class ItemSelectionScreen extends StatefulWidget {
  final List<InvoiceItem> existingInvoiceItems; // الأصناف الموجودة بالفعل في الفاتورة الحالية

  const ItemSelectionScreen({super.key, required this.existingInvoiceItems});

  @override
  State<ItemSelectionScreen> createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  late Box<Item> itemsBox;
  Map<String, double> _selectedQuantities = {}; // {item.id: quantity} لتتبع الكميات المختارة
  Map<String, Item> _allItemsMap = {}; // {item.id: Item} لسهولة الوصول للصنف

  @override
  void initState() {
    super.initState();
    itemsBox = Hive.box<Item>('items_box');

    // بناء خريطة بجميع الأصناف لتسهيل البحث
    for (var item in itemsBox.values) {
      _allItemsMap[item.id] = item;
    }

    // تهيئة الكميات المختارة بناءً على الأصناف الموجودة في الفاتورة
    for (var invoiceItem in widget.existingInvoiceItems) {
      // ⭐ التعديل هنا: التأكد من أن الكمية هي double
      _selectedQuantities[invoiceItem.itemId] = invoiceItem.quantity.toDouble(); 
    }
  }

  // دالة لزيادة الكمية
  void _incrementQuantity(String itemId) {
    setState(() {
      _selectedQuantities.update(
        itemId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    });
  }

  // دالة لإنقاص الكمية
  void _decrementQuantity(String itemId) {
    setState(() {
      _selectedQuantities.update(
        itemId,
        (value) {
          if (value > 0) {
            return value - 1;
          }
          return 0;
        },
        ifAbsent: () => 0,
      );
    });
  }

  // دالة لإرسال الأصناف المختارة مرة أخرى إلى شاشة الفاتورة
  void _returnSelectedItems() {
    List<InvoiceItem> resultItems = [];
    _selectedQuantities.forEach((itemId, quantity) {
      if (quantity > 0) {
        final item = _allItemsMap[itemId]; // الحصول على الصنف من الخريطة
        if (item != null) {
          resultItems.add(
            InvoiceItem(
              itemId: item.id,
              itemName: item.name,
              quantity: quantity,
              unit: item.unit,
              sellingPrice: item.sellingPrice,
            ),
          );
        }
      }
    });
    Navigator.pop(context, resultItems); // العودة مع قائمة الأصناف المختارة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الأصناف'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _returnSelectedItems, // زر لتأكيد الاختيار
            tooltip: 'تأكيد الأصناف المختارة',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Item>>(
        valueListenable: itemsBox.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أصناف في المخزون.\nالرجاء إضافة أصناف أولاً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final List<Item> availableItems = box.values.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: availableItems.length,
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    final currentQuantity = _selectedQuantities[item.id] ?? 0.0; // الكمية المختارة حاليا

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('سعر البيع: ${item.sellingPrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700])),
                                  Text('المتوفر: ${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                            ),
                            // عناصر التحكم بالكمية
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _decrementQuantity(item.id),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    currentQuantity.toStringAsFixed(0), // عرض الكمية بدون كسور
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _incrementQuantity(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _returnSelectedItems,
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد واضافة الأصناف للفاتورة'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
