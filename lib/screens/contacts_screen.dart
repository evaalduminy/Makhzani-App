import 'package:flutter/material.dart';
import 'package:makhzani_app/models/contact_model.dart';
import 'package:makhzani_app/services/database_helper.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Contact> _suppliers = [];
  List<Contact> _customers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper();
      final suppliers = await db.getContacts(type: ContactType.supplier);
      final customers = await db.getContacts(type: ContactType.customer);

      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('جهات الاتصال'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'الكل'),
            Tab(icon: Icon(Icons.local_shipping), text: 'الموردين'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'العملاء'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContactsList([..._suppliers, ..._customers]),
                _buildContactsList(_suppliers),
                _buildContactsList(_customers),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'جهة اتصال جديدة',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContactsList(List<Contact> contacts) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد جهات اتصال',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactCard(contact);
        },
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    final isSupplier = contact.type == ContactType.supplier;
    final typeColor = isSupplier ? Colors.blue : Colors.green;
    final typeIcon = isSupplier ? Icons.local_shipping : Icons.shopping_cart;
    final typeLabel = isSupplier ? 'مورد' : 'عميل';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.1),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phone != null && contact.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(contact.phone!),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${contact.balance.toStringAsFixed(2)} ر.ي',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: contact.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const Text(
              'الرصيد',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showEditContactDialog(contact),
        onLongPress: () => _confirmDelete(contact),
      ),
    );
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => _ContactFormDialog(
        onSaved: () => _loadContacts(),
      ),
    );
  }

  void _showEditContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => _ContactFormDialog(
        contact: contact,
        onSaved: () => _loadContacts(),
      ),
    );
  }

  void _confirmDelete(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جهة الاتصال'),
        content: Text('هل أنت متأكد من حذف "${contact.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper().deleteContact(contact.id!);
              _loadContacts();
              if (mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف ${contact.name}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// Dialog لإضافة/تعديل جهة اتصال
class _ContactFormDialog extends StatefulWidget {
  final Contact? contact;
  final VoidCallback onSaved;

  const _ContactFormDialog({this.contact, required this.onSaved});

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _balanceController = TextEditingController();
  ContactType _selectedType = ContactType.supplier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone ?? '';
      _balanceController.text = widget.contact!.balance.toString();
      _selectedType = widget.contact!.type;
    } else {
      _balanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;

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
                Text(
                  isEdit ? 'تعديل جهة الاتصال' : 'جهة اتصال جديدة',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // الاسم
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // الهاتف
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // النوع
                const Text('النوع',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<ContactType>(
                        title: const Text('مورد'),
                        value: ContactType.supplier,
                        groupValue: _selectedType,
                        activeColor: Colors.blue,
                        onChanged: (value) =>
                            setState(() => _selectedType = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<ContactType>(
                        title: const Text('عميل'),
                        value: ContactType.customer,
                        groupValue: _selectedType,
                        activeColor: Colors.green,
                        onChanged: (value) =>
                            setState(() => _selectedType = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // الرصيد الافتتاحي
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'الرصيد الافتتاحي',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'مطلوب';
                    if (double.tryParse(value) == null) return 'رقم غير صحيح';
                    return null;
                  },
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
                      onPressed: _isLoading ? null : _saveContact,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'تحديث' : 'حفظ'),
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

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final contact = Contact(
        id: widget.contact?.id,
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        type: _selectedType,
        balance: double.parse(_balanceController.text),
      );

      if (widget.contact == null) {
        await db.insertContact(contact);
      } else {
        await db.updateContact(contact);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.contact == null
                  ? 'تم إضافة جهة الاتصال بنجاح'
                  : 'تم تحديث جهة الاتصال بنجاح',
            ),
            backgroundColor: Colors.purple.withValues(alpha: 0.1),
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
