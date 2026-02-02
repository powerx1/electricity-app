import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import '../../services/services.dart';

/// شاشة العملاء - Customers Screen
class CustomersScreen extends StatefulWidget {
  final bool openAddDialog;

  const CustomersScreen({super.key, this.openAddDialog = false});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openAddDialog) {
        _showAddEditDialog();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: (value) {
                  context.read<CustomerProvider>().searchCustomers(value);
                },
              )
            : const Text(AppConstants.labelCustomers),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<CustomerProvider>().searchCustomers('');
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'import') {
                await _importFromExcel();
              } else if (value == 'template') {
                await _downloadTemplate();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.green),
                    SizedBox(width: 8),
                    Text('استيراد من Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تحميل قالب Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.customers.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: provider.loadCustomers,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.customers.length,
              itemBuilder: (context, index) {
                final customer = provider.customers[index];
                return _CustomerCard(
                  customer: customer,
                  onEdit: () => _showAddEditDialog(customer: customer),
                  onDelete: () => _showDeleteDialog(customer),
                  onTap: () => _showCustomerDetails(customer),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEditDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة عميل'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد عملاء',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة عميل جديد',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddEditDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة عميل'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _importFromExcel,
            icon: const Icon(Icons.upload_file),
            label: const Text('استيراد من Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog({Customer? customer}) async {
    final isEditing = customer != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: customer?.fullName);
    final phoneController = TextEditingController(text: customer?.phoneNumber);
    final addressController = TextEditingController(text: customer?.address);
    final notesController = TextEditingController(text: customer?.notes);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل العميل' : 'إضافة عميل جديد'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelFullName,
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.errorRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelPhoneNumber,
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+966501234567',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.errorRequired;
                    }
                    if (!Customer.isValidPhoneNumber(value)) {
                      return AppConstants.errorInvalidPhone;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelAddress,
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelNotes,
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppConstants.btnCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = context.read<CustomerProvider>();

                final newCustomer = Customer(
                  id: customer?.id,
                  fullName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                bool success;
                if (isEditing) {
                  success = await provider.updateCustomer(newCustomer);
                } else {
                  success = await provider.addCustomer(newCustomer) != null;
                }

                if (success && context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: Text(isEditing ? AppConstants.btnSave : AppConstants.btnAdd),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? AppConstants.successCustomerUpdated
                : AppConstants.successCustomerAdded,
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(Customer customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل "${customer.fullName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppConstants.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppConstants.btnDelete),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final success = await context.read<CustomerProvider>().deleteCustomer(
        customer.id!,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successCustomerDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      customer.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.phoneNumber,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              if (customer.address != null) ...[
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: customer.address!,
                ),
              ],
              if (customer.notes != null) ...[
                _DetailRow(
                  icon: Icons.note,
                  label: 'ملاحظات',
                  value: customer.notes!,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditDialog(customer: customer);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // الانتقال لإنشاء فاتورة
                        Navigator.pop(context);
                        // يمكن تمرير العميل لشاشة الفاتورة
                      },
                      icon: const Icon(Icons.receipt),
                      label: const Text('فاتورة جديدة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    final result = await context.read<CustomerProvider>().importFromExcel();

    if (mounted) {
      if (result.success && result.data.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم استيراد ${result.successfulRows} عميل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.errors.isNotEmpty) {
        _showImportErrorsDialog(result.errors);
      }
    }
  }

  void _showImportErrorsDialog(List<ImportError> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('أخطاء في الاستيراد'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final error = errors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Text('${error.row}'),
                ),
                title: Text(error.message),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final file = await ExcelService().createCustomerTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ القالب في: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء القالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// بطاقة العميل
class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  customer.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          customer.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف التفاصيل
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
