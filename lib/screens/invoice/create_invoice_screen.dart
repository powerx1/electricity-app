import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import '../../services/services.dart';

/// شاشة إنشاء فاتورة - Create Invoice Screen
class CreateInvoiceScreen extends StatefulWidget {
  final Customer? preSelectedCustomer;

  const CreateInvoiceScreen({super.key, this.preSelectedCustomer});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  final _oldReadingController = TextEditingController();
  final _newReadingController = TextEditingController();
  final _kwhPriceController = TextEditingController();
  final _notesController = TextEditingController();

  double _consumption = 0;
  double _totalAmount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;

    // تعيين السعر الافتراضي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>().settings;
      _kwhPriceController.text = settings.defaultKwhPrice.toStringAsFixed(4);
    });

    // الاستماع لتغييرات القراءات لحساب الاستهلاك
    _oldReadingController.addListener(_calculateConsumption);
    _newReadingController.addListener(_calculateConsumption);
    _kwhPriceController.addListener(_calculateConsumption);
  }

  @override
  void dispose() {
    _oldReadingController.dispose();
    _newReadingController.dispose();
    _kwhPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateConsumption() {
    final oldReading = double.tryParse(_oldReadingController.text) ?? 0;
    final newReading = double.tryParse(_newReadingController.text) ?? 0;
    final kwhPrice = double.tryParse(_kwhPriceController.text) ?? 0;

    setState(() {
      _consumption = Invoice.calculateConsumption(oldReading, newReading);
      _totalAmount = Invoice.calculateTotal(_consumption, kwhPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelCreateInvoice)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // اختيار العميل
              _buildCustomerSelector(),
              const SizedBox(height: 20),

              // القراءات
              _buildReadingsSection(),
              const SizedBox(height: 20),

              // حساب الاستهلاك
              _buildConsumptionCard(),
              const SizedBox(height: 20),

              // سعر الكيلوواط
              _buildPriceSection(),
              const SizedBox(height: 20),

              // المبلغ الإجمالي
              _buildTotalCard(),
              const SizedBox(height: 20),

              // ملاحظات
              _buildNotesSection(),
              const SizedBox(height: 20),

              // معلومات الفاتورة
              _buildInvoiceInfoCard(settingsProvider),
              const SizedBox(height: 32),

              // زر إنشاء الفاتورة
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'اختيار العميل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                return InkWell(
                  onTap: () => _showCustomerPicker(provider.customers),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedCustomer == null
                            ? Colors.grey.shade300
                            : AppTheme.primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _selectedCustomer != null
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                          child: Icon(
                            _selectedCustomer != null
                                ? Icons.person
                                : Icons.person_add,
                            color: _selectedCustomer != null
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCustomer?.fullName ?? 'اختر عميل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedCustomer != null
                                      ? null
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_selectedCustomer != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedCustomer!.phoneNumber,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker(List<Customer> customers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'اختر العميل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: customers.isEmpty
                  ? const Center(child: Text('لا يوجد عملاء. أضف عميل أولاً.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              customer.fullName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(customer.fullName),
                          subtitle: Text(customer.phoneNumber),
                          trailing: null,
                          onTap: () {
                            setState(() => _selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.electric_meter, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'قراءات العداد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _oldReadingController,
                    decoration: const InputDecoration(
                      labelText: AppConstants.labelOldReading,
                      suffixText: 'kWh',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.errorRequired;
                      }
                      if (double.tryParse(value) == null) {
                        return AppConstants.errorInvalidReading;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _newReadingController,
                    decoration: const InputDecoration(
                      labelText: AppConstants.labelNewReading,
                      suffixText: 'kWh',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.errorRequired;
                      }
                      final newReading = double.tryParse(value);
                      if (newReading == null) {
                        return AppConstants.errorInvalidReading;
                      }
                      final oldReading =
                          double.tryParse(_oldReadingController.text) ?? 0;
                      if (newReading < oldReading) {
                        return AppConstants.errorReadingMismatch;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            children: [
              const Text(
                'الاستهلاك',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${_consumption.toStringAsFixed(0)} kWh',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'سعر الكيلوواط',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kwhPriceController,
              decoration: const InputDecoration(
                labelText: 'السعر (USD)',
                prefixText: '\$ ',
                hintText: '0.10',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.errorRequired;
                }
                if (double.tryParse(value) == null) {
                  return AppConstants.errorInvalidPrice;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade500, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'المبلغ الإجمالي المستحق',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalAmount.toStringAsFixed(2)} USD',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'ملاحظات (اختياري)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'أضف ملاحظات إضافية...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceInfoCard(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'معلومات الفاتورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<String>(
              future: context.read<InvoiceProvider>().getNextInvoiceNumber(),
              builder: (context, snapshot) {
                return _InfoRow(
                  label: 'رقم الفاتورة',
                  value: snapshot.data ?? '---',
                  icon: Icons.tag,
                );
              },
            ),
            _InfoRow(
              label: 'التاريخ',
              value:
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              icon: Icons.calendar_today,
            ),
            if (settingsProvider.showHijriDate)
              _InfoRow(
                label: 'التاريخ الهجري',
                value:
                    context.read<InvoiceProvider>().getHijriDate(
                      DateTime.now(),
                      true,
                    ) ??
                    '',
                icon: Icons.date_range,
              ),
            _InfoRow(
              label: 'الختم',
              value: settingsProvider.stampText,
              icon: Icons.verified,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _createInvoice,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.receipt),
      label: Text(
        _isLoading ? 'جاري الإنشاء...' : AppConstants.btnCreateInvoice,
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _createInvoice() async {
    // التحقق من اختيار عميل
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار عميل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final settings = context.read<SettingsProvider>().settings;
      final invoiceProvider = context.read<InvoiceProvider>();

      final invoice = await invoiceProvider.createInvoice(
        customer: _selectedCustomer!,
        oldReading: double.parse(_oldReadingController.text),
        newReading: double.parse(_newReadingController.text),
        kwhPrice: double.parse(_kwhPriceController.text),
        stampText: settings.stampText,
        showHijriDate: settings.showHijriDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (invoice != null && mounted) {
        // إنشاء PDF
        final pdfFile = await invoiceProvider.generateInvoicePdf(
          invoice,
          settings: settings,
        );

        // عرض حوار الإجراءات
        await _showSuccessDialog(invoice, pdfFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء الفاتورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(Invoice invoice, File? pdfFile) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('تم إنشاء الفاتورة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم الفاتورة: ${invoice.invoiceNumber}'),
            Text('العميل: ${invoice.customerName}'),
            Text('المبلغ: ${invoice.formattedTotal}'),
            const SizedBox(height: 20),
            const Text('ماذا تريد أن تفعل؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
          if (pdfFile != null) ...[
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await PrintingService().printPdf(
                  await pdfFile.readAsBytes(),
                  jobName: 'فاتورة ${invoice.invoiceNumber}',
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await WhatsAppService().sendInvoiceViaWhatsApp(
                  invoice: invoice,
                  pdfFile: pdfFile,
                  context: context,
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// صف معلومات
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
