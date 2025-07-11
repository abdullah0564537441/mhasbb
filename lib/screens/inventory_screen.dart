// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:mhasbb/models/item.dart';
import 'package:mhasbb/screens/add_edit_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث باسم الصنف أو الوحدة',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                fillColor: Colors.white24,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Item>('items_box').listenable(),
        builder: (context, Box<Item> box, _) {
          final allItems = box.values.toList();

          final filteredItems = allItems.where((item) {
            final nameLower = item.name.toLowerCase();
            final unitLower = item.unit.toLowerCase();
            return nameLower.contains(_searchQuery) || unitLower.contains(_searchQuery);
          }).toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'لا توجد أصناف مسجلة حتى الآن.'
                    : 'لا توجد أصناف مطابقة لبحثك.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          filteredItems.sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditItemScreen(
                          item: item,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDeleteItem(context, item);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('الوحدة: ${item.unit}', style: TextStyle(color: Colors.grey[700])),
                        Text('الكمية الحالية: ${NumberFormat.decimalPattern().format(item.currentStock)} ${item.unit}', // ⭐⭐ تم التصحيح هنا ⭐⭐
                            style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 5),
                        Text('سعر الشراء: ${item.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15)),
                        Text('سعر البيع: ${item.salePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), // ⭐⭐ تم التصحيح هنا ⭐⭐
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل أنت متأكد أنك تريد حذف الصنف "${item.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await item.delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الصنف بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
