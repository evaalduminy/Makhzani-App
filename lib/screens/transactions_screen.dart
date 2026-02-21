import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makhzani_app/services/transaction_service.dart';
import 'package:makhzani_app/services/product_service.dart';
import 'package:makhzani_app/models/stock_transaction_model.dart';
import 'package:makhzani_app/models/product.dart';
import 'package:makhzani_app/models/product_detail_model.dart';
import 'package:makhzani_app/models/product_unit_model.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  String _filterType = 'الكل';
  final List<String> _filterOptions = ['الكل', 'بيع', 'شراء', 'تعديل', 'إرجاع'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactionService = TransactionService();
      final result = await transactionService.getAllTransactionsWithDetails();

      if (mounted) {
        setState(() {
          _transactions = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filterType == 'الكل') return _transactions;

    String typeFilter = '';
    switch (_filterType) {
      case 'بيع':
        typeFilter = 'SALE';
        break;
      case 'شراء':
        typeFilter = 'PURCHASE';
        break;
      case 'تعديل':
        typeFilter = 'ADJUSTMENT';
        break;
      case 'إرجاع':
        typeFilter = 'RETURN';
        break;
    }

    return _transactions.where((t) => t['type'] == typeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // شريط الفلترة
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فلترة حسب النوع',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((option) {
                      final isSelected = _filterType == option;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _filterType = option);
                          },
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // قائمة المعاملات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد معاملات',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'معاملة جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final quantity = transaction['quantity'] as int;
    final productName = transaction['product_name'] as String? ?? 'غير معروف';
    final barcode = transaction['barcode'] as String? ?? '';
    final categoryName =
        transaction['category_name'] as String? ?? 'بدون تصنيف';
    final dateStr = transaction['transaction_date'] as String;
    final notes = transaction['notes'] as String?;

    // تحويل التاريخ
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      date = DateTime.now();
    }
    final formattedDate = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);

    // تحديد اللون والأيقونة حسب النوع
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (type) {
      case 'SALE':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'بيع';
        break;
      case 'PURCHASE':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = 'شراء';
        break;
      case 'ADJUSTMENT':
        typeColor = Colors.orange;
        typeIcon = Icons.edit;
        typeLabel = 'تعديل';
        break;
      case 'RETURN':
        typeColor = Colors.blue;
        typeIcon = Icons.keyboard_return;
        typeLabel = 'إرجاع';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help_outline;
        typeLabel = type;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // أيقونة النوع
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                // معلومات المعاملة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (barcode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                barcode,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.blueGrey[700]),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // الكمية
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quantity.abs()} قطعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: quantity < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTransactionDialog(
        onTransactionAdded: () {
          _loadTransactions();
        },
      ),
    );
  }
}

// Dialog لإضافة معاملة جديدة
class _AddTransactionDialog extends StatefulWidget {
  final VoidCallback onTransactionAdded;

  const _AddTransactionDialog({required this.onTransactionAdded});

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitController = TextEditingController(); // متحكم اسم الوحدة يدوياً

  List<Product> _products = [];
  Product? _selectedProduct;
  ProductUnit? _selectedUnit; // الوحدة المختارة (للمساعدة في معامل التحويل)
  String _transactionType = 'PURCHASE';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ProductService().getAllProducts();
    setState(() => _products = products);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معاملة جديدة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // نوع المعاملة
                const Text('نوع المعاملة',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTypeOption('شراء', 'PURCHASE', Colors.green),
                    _buildTypeOption('بيع', 'SALE', Colors.red),
                    _buildTypeOption('تعديل', 'ADJUSTMENT', Colors.orange),
                    _buildTypeOption('إرجاع', 'RETURN', Colors.blue),
                  ],
                ),
                const SizedBox(height: 24),

                // اختيار المنتج
                DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'المنتج',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: _products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = value;
                      if (value != null && value.units.isNotEmpty) {
                        _selectedUnit = value.units.firstWhere(
                          (u) => u.isBaseUnit,
                          orElse: () => value.units.first,
                        );
                        _unitController.text = _selectedUnit!.unitName;
                      } else {
                        _selectedUnit = null;
                        _unitController.text = 'قطعة';
                      }
                    });
                  },
                  validator: (value) => value == null ? 'اختر منتج' : null,
                ),
                const SizedBox(height: 16),

                // إدخال نوع الوحدة يدوياً أو اختيارها
                if (_selectedProduct != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'نوع الوحدة (كرتون، حبة..)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_important_outline),
                          ),
                          // منع الأرقام والرموز في نوع الوحدة
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(
                                r'[a-zA-Z\s\u0621-\u064A\u0671-\u06D3\u06FB-\u06FE]')),
                            FilteringTextInputFormatter.deny(RegExp(
                                r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'مطلوب';
                            if (RegExp(
                                    r'[0-9\u0660-\u0669\u06F0-\u06F9!@#\$%^&*(),.?":{}|<>]')
                                .hasMatch(value)) {
                              return 'يسمح بالحروف فقط';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_selectedProduct!.units.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.list, color: Colors.blue),
                          onPressed: () {
                            _showUnitPicker();
                          },
                          tooltip: 'اختيار من الوحدات المسجلة',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // الكمية
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'الكمية (${_unitController.text})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'مطلوب';
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'كمية غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // السعر (للشراء فقط)
                if (_transactionType == 'PURCHASE') ...[
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'سعر الشراء لـ ${_unitController.text}',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'ر.ي',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'مطلوب';
                      if (double.tryParse(value) == null) return 'سعر غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ملاحظات
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // أزرار
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, String value, Color color) {
    final isSelected = _transactionType == value;
    return InkWell(
      onTap: () => setState(() => _transactionType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر وحدة من المسجلة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._selectedProduct!.units.map((unit) {
                return ListTile(
                  title: Text(unit.unitName),
                  subtitle: Text('معامل التحويل: ${unit.conversionFactor}'),
                  onTap: () {
                    setState(() {
                      _selectedUnit = unit;
                      _unitController.text = unit.unitName;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) return;

    setState(() => _isLoading = true);

    try {
      final inputQuantity = int.parse(_quantityController.text);
      final factor = _selectedUnit?.conversionFactor ?? 1;
      final totalQuantity = inputQuantity * factor;
      final unitName = _unitController.text;

      final transactionService = TransactionService();
      final notes = _notesController.text.isEmpty
          ? 'معاملة بـ $unitName'
          : '${_notesController.text} (وحدة: $unitName)';

      if (_transactionType == 'PURCHASE') {
        final inputPrice = double.parse(_priceController.text);
        final pricePerPiece = inputPrice / factor;

        final detail = ProductDetail(
          productId: _selectedProduct!.id!,
          quantity: totalQuantity,
          purchasePrice: pricePerPiece,
          expiryDate: null,
        );

        await transactionService.recordPurchase(detail);
      } else if (_transactionType == 'ADJUSTMENT' ||
          _transactionType == 'RETURN') {
        final transaction = StockTransaction(
          productId: _selectedProduct!.id!,
          type: _transactionType == 'RETURN'
              ? StockTransactionType.adjustment
              : StockTransactionType.adjustment,
          quantity: totalQuantity,
          transactionDate: DateTime.now(),
          notes: _transactionType == 'RETURN' ? 'إرجاع: $notes' : notes,
        );
        await transactionService.recordAdjustment(transaction);
      } else if (_transactionType == 'SALE') {
        final transaction = StockTransaction(
          productId: _selectedProduct!.id!,
          type: StockTransactionType.sale,
          quantity: -totalQuantity,
          transactionDate: DateTime.now(),
          notes: notes,
        );
        await transactionService.recordAdjustment(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onTransactionAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المعاملة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
