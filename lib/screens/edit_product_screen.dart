import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _minStockController;
  late String _selectedCategory;

  final List<String> _categories = [
    'عام',
    'مواد غذائية',
    'مشروبات',
    'ألبان',
    'معلبات',
    'منظفات',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.mainPrice.toString(),
    );
    _minStockController = TextEditingController(
      text: widget.product.minStockLevel.toString(),
    );
    _selectedCategory = _getCategoryName(widget.product.categoryId);
  }

  String _getCategoryName(int? id) {
    switch (id) {
      case 2:
        return 'مواد غذائية';
      case 3:
        return 'مشروبات';
      case 4:
        return 'ألبان';
      case 5:
        return 'معلبات';
      case 6:
        return 'منظفات';
      case 7:
        return 'أخرى';
      default:
        return 'عام';
    }
  }

  int _getCategoryId(String name) {
    switch (name) {
      case 'مواد غذائية':
        return 2;
      case 'مشروبات':
        return 3;
      case 'ألبان':
        return 4;
      case 'معلبات':
        return 5;
      case 'منظفات':
        return 6;
      case 'أخرى':
        return 7;
      default:
        return 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. تحديث بيانات المنتج الأساسية
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        categoryId: _getCategoryId(_selectedCategory),
        barcode:
            _barcodeController.text.isEmpty ? null : _barcodeController.text,
        description: _descriptionController.text,
        minStockLevel: int.tryParse(_minStockController.text) ?? 10,
      );

      await _productService.updateProduct(updatedProduct);

      // 2. تحديث السعر (إذا تغير)
      final newPrice = double.tryParse(_priceController.text);
      if (newPrice != null && newPrice != widget.product.mainPrice) {
        // البحث عن الوحدة الأساسية وتحديث سعرها
        final baseUnit = widget.product.units.firstWhere(
          (u) => u.isBaseUnit,
          orElse: () => widget.product.units.isNotEmpty
              ? widget.product.units.first
              : throw Exception('لا توجد وحدات للمنتج'),
        );

        final updatedUnit = baseUnit.copyWith(salePrice: newPrice);
        await _productService.updateProductUnit(updatedUnit);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث المنتج بنجاح')));
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                inputFormatters: [
                  // يسمح بالحروف والمسافات فقط (بدون أرقام أو رموز)
                  FilteringTextInputFormatter.allow(RegExp(
                      r'[a-zA-Z\s\u0621-\u064A\u0671-\u06D3\u06FB-\u06FE]')),
                  FilteringTextInputFormatter.deny(RegExp(
                      r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المنتج';
                  }
                  if (RegExp(
                          r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')
                      .hasMatch(value)) {
                    return 'يسمح بالحروف فقط (لا يسمح بالأرقام أو الرموز)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'الباركود',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                      RegExp(r'[\u0600-\u06FF]')), // منع العربية تماماً
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                      return 'خطأ: الباركود لا يقبل الحروف العربية';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر البيع',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: 'ر.ي',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'حد الطلب',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                        helperText: 'تنبيه عند انخفاض الكمية',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ التعديلات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
