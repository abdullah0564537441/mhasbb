// lib/screens/add_edit_item_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:mhasbb/models/item.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item;

  const AddEditItemScreen({super.key, this.item});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _currentStockController; // ⭐⭐ تم تغيير الاسم هنا ⭐⭐

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
    _purchasePriceController = TextEditingController(text: widget.item?.purchasePrice.toString() ?? '0.0');
    _salePriceController = TextEditingController(text: widget.item?.salePrice.toString() ?? '0.0');
    _currentStockController = TextEditingController(text: widget.item?.currentStock.toString() ?? '0.0'); // ⭐⭐ تم التصحيح هنا ⭐⭐
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final name = _nameController.text;
      final unit = _unitController.text;
      final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
      final salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
      final currentStock = double.tryParse(_currentStockController.text) ?? 0.0; // ⭐⭐ تم التصحيح هنا ⭐⭐

      final itemBox = Hive.box<Item>('items_box');

      if (widget.item == null) {
        // إضافة صنف جديد
        final newItem = Item(
          id: const Uuid().v4(),
          name: name,
          unit: unit,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          currentStock: currentStock, // ⭐⭐ تم التصحيح هنا ⭐⭐
        );
        await itemBox.put(newItem.id, newItem);
      } else {
        // تعديل صنف موجود
        widget.item!.name = name;
        widget.item!.unit = unit;
        widget.item!.purchasePrice = purchasePrice;
        widget.item!.salePrice = salePrice;
        widget.item!.currentStock = currentStock; // ⭐⭐ تم التصحيح هنا ⭐⭐
        await widget.item!.save();
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الصنف "${_nameController.text}" بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'إضافة صنف جديد' : 'تعديل صنف'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الصنف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'وحدة القياس (مثال: كرتون, حبة, متر)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وحدة القياس';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'سعر الشراء',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'الرجاء إدخال سعر شراء صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _salePriceController,
                decoration: const InputDecoration(
                  labelText: 'سعر البيع',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'الرجاء إدخال سعر بيع صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _currentStockController,
                decoration: const InputDecoration(
                  labelText: 'الكمية الحالية في المخزون',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'الرجاء إدخال كمية صحيحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save),
                label: const Text('حفظ الصنف'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _currentStockController.dispose();
    super.dispose();
  }
}
