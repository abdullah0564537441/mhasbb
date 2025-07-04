import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // لتوليد معرفات فريدة

// استيراد موديل الصنف (Item)
import 'package:mhasbb/models/item.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item; // الصنف الذي سيتم تعديله (يمكن أن يكون null للإضافة)

  const AddEditItemScreen({super.key, this.item});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

  // المتحكمات (Controllers) لحقول الإدخال
  late TextEditingController _itemNameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;

  late Box<Item> itemsBox; // صندوق Hive الخاص بالأصناف
  final Uuid uuid = const Uuid(); // لتوليد معرفات فريدة

  @override
  void initState() {
    super.initState();
    itemsBox = Hive.box<Item>('items_box');

    // تهيئة المتحكمات بناءً على ما إذا كنا نضيف صنفًا جديدًا أو نعدل صنفًا موجودًا
    if (widget.item == null) {
      // وضع افتراضيات لصنف جديد
      _itemNameController = TextEditingController();
      _quantityController = TextEditingController(text: '0'); // كمية افتراضية
      _unitController = TextEditingController(text: 'قطعة'); // وحدة افتراضية
      _purchasePriceController = TextEditingController(text: '0.0'); // سعر شراء افتراضي
      _sellingPriceController = TextEditingController(text: '0.0'); // سعر بيع افتراضي
    } else {
      // تحميل بيانات الصنف الموجودة للتعديل
      _itemNameController = TextEditingController(text: widget.item!.name);
      _quantityController = TextEditingController(text: widget.item!.quantity.toString());
      _unitController = TextEditingController(text: widget.item!.unit);
      _purchasePriceController = TextEditingController(text: widget.item!.purchasePrice.toString());
      _sellingPriceController = TextEditingController(text: widget.item!.sellingPrice.toString());
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // دالة لحفظ الصنف
  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String name = _itemNameController.text.trim();
      final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
      final String unit = _unitController.text.trim();
      final double purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
      final double sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اسم الصنف لا يمكن أن يكون فارغًا.')),
        );
        return;
      }

      // إنشاء كائن Item
      final newItem = Item(
        id: widget.item?.id ?? uuid.v4(), // استخدم ID الموجود أو أنشئ واحدًا جديدًا
        name: name,
        quantity: quantity,
        unit: unit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
      );

      if (widget.item == null) {
        // إضافة صنف جديد
        await itemsBox.put(newItem.id, newItem); // استخدام ID الصنف كمفتاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الصنف بنجاح!')),
        );
      } else {
        // تحديث صنف موجود
        await itemsBox.put(widget.item!.key, newItem); // استخدام مفتاح الصنف الأصلي للتحديث
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصنف بنجاح!')),
        );
      }
      Navigator.of(context).pop(); // العودة إلى شاشة المخزون
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'إضافة صنف جديد' : 'تعديل صنف'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // حقل اسم الصنف
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: 'اسم الصنف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل اسم الصنف',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الصنف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل الكمية
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل الكمية',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الكمية';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح للكمية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل الوحدة
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: 'الوحدة (مثال: قطعة، كجم)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل وحدة القياس',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوحدة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل سعر الشراء
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر الشراء',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل سعر الشراء',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال سعر الشراء';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لسعر الشراء';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل سعر البيع
              TextFormField(
                controller: _sellingPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر البيع',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'أدخل سعر البيع',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال سعر البيع';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لسعر البيع';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // زر حفظ الصنف
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  widget.item == null ? 'حفظ الصنف' : 'تحديث الصنف',
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
