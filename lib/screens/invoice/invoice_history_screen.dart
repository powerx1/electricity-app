import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import '../../services/services.dart';

/// شاشة سجل الفواتير - Invoice History Screen
class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  DateTime? _startDate;
  DateTime? _endDate;

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
                  hintText: 'بحث برقم الفاتورة أو اسم العميل...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: (value) {
                  context.read<InvoiceProvider>().searchInvoices(value);
                },
              )
            : const Text(AppConstants.labelInvoiceHistory),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<InvoiceProvider>().clearFilter();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التصفية
          if (_startDate != null || _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'التصفية: ${_formatDateRange()}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      context.read<InvoiceProvider>().clearFilter();
                    },
                    child: const Text('مسح'),
                  ),
                ],
              ),
            ),

          // قائمة الفواتير
          Expanded(
            child: Consumer<InvoiceProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.invoices.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: provider.loadInvoices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = provider.invoices[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () => _showInvoiceDetails(invoice),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ فاتورة جديدة من الشاشة الرئيسية',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    final formatter = DateFormat('dd/MM/yyyy');
    if (_startDate != null && _endDate != null) {
      return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
    } else if (_startDate != null) {
      return 'من ${formatter.format(_startDate!)}';
    } else if (_endDate != null) {
      return 'حتى ${formatter.format(_endDate!)}';
    }
    return '';
  }

  Future<void> _showFilterDialog() async {
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تصفية الفواتير'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('من تاريخ'),
                subtitle: Text(
                  tempStart != null
                      ? DateFormat('dd/MM/yyyy').format(tempStart!)
                      : 'اختر تاريخ',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempStart ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => tempStart = date);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('إلى تاريخ'),
                subtitle: Text(
                  tempEnd != null
                      ? DateFormat('dd/MM/yyyy').format(tempEnd!)
                      : 'اختر تاريخ',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempEnd ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => tempEnd = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempStart = null;
                  tempEnd = null;
                });
              },
              child: const Text('مسح'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _startDate = tempStart;
                  _endDate = tempEnd;
                });
                if (tempStart != null && tempEnd != null) {
                  context.read<InvoiceProvider>().filterByDateRange(
                    tempStart!,
                    tempEnd!.add(const Duration(days: 1)),
                  );
                }
              },
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _InvoiceDetailsSheet(
          invoice: invoice,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// بطاقة الفاتورة
class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${invoice.invoiceNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        invoice.formattedTotal,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: invoice.isPaid
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          invoice.isPaid ? 'مدفوعة' : 'غير مدفوعة',
                          style: TextStyle(
                            color: invoice.isPaid
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.electric_meter,
                    label: 'القراءة السابقة',
                    value: invoice.oldReading.toStringAsFixed(0),
                  ),
                  _StatItem(
                    icon: Icons.bolt,
                    label: 'الاستهلاك',
                    value: '${invoice.consumption.toStringAsFixed(0)} kWh',
                    color: Colors.orange,
                  ),
                  _StatItem(
                    icon: Icons.electric_meter,
                    label: 'القراءة الحالية',
                    value: invoice.newReading.toStringAsFixed(0),
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

/// عنصر إحصائية
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// ورقة تفاصيل الفاتورة
class _InvoiceDetailsSheet extends StatelessWidget {
  final Invoice invoice;
  final ScrollController scrollController;

  const _InvoiceDetailsSheet({
    required this.invoice,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المقبض
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

          // رأس الفاتورة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'فاتورة #${invoice.invoiceNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: invoice.isPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: invoice.isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  invoice.isPaid ? 'مدفوعة' : 'غير مدفوعة',
                  style: TextStyle(
                    color: invoice.isPaid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // معلومات العميل
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات العميل',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _DetailRow(label: 'الاسم', value: invoice.customerName),
                  _DetailRow(label: 'الهاتف', value: invoice.customerPhone),
                  if (invoice.customerAddress != null)
                    _DetailRow(
                      label: 'العنوان',
                      value: invoice.customerAddress!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // تفاصيل الفاتورة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل الفاتورة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _DetailRow(
                    label: 'التاريخ',
                    value: DateFormat('dd/MM/yyyy').format(invoice.invoiceDate),
                  ),
                  if (invoice.hijriDate != null)
                    _DetailRow(
                      label: 'التاريخ الهجري',
                      value: invoice.hijriDate!,
                    ),
                  _DetailRow(
                    label: 'القراءة السابقة',
                    value: '${invoice.oldReading.toStringAsFixed(0)} kWh',
                  ),
                  _DetailRow(
                    label: 'القراءة الحالية',
                    value: '${invoice.newReading.toStringAsFixed(0)} kWh',
                  ),
                  _DetailRow(
                    label: 'الاستهلاك',
                    value: '${invoice.consumption.toStringAsFixed(0)} kWh',
                    valueStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  _DetailRow(
                    label: 'سعر الكيلوواط',
                    value: invoice.formattedKwhPrice,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // المبلغ الإجمالي
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade500, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'المبلغ الإجمالي: ',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  invoice.formattedTotal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (invoice.notes != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.yellow[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(invoice.notes!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // أزرار الإجراءات
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printInvoice(context),
                  icon: const Icon(Icons.print),
                  label: const Text('طباعة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendWhatsApp(context),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _togglePaymentStatus(context),
                  icon: Icon(
                    invoice.isPaid ? Icons.cancel : Icons.check_circle,
                  ),
                  label: Text(invoice.isPaid ? 'إلغاء الدفع' : 'تحديد كمدفوعة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteInvoice(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      final settings = context.read<SettingsProvider>().settings;
      final pdfBytes = await PdfService().generateInvoicePdf(
        invoice,
        settings: settings,
      );
      await PrintingService().printPdf(
        pdfBytes,
        jobName: 'فاتورة ${invoice.invoiceNumber}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(BuildContext context) async {
    try {
      final settings = context.read<SettingsProvider>().settings;
      final pdfBytes = await PdfService().generateInvoicePdf(
        invoice,
        settings: settings,
      );
      final file = await PdfService().savePdfToFile(
        pdfBytes,
        invoice.invoiceNumber,
      );

      if (context.mounted) {
        await WhatsAppService().sendInvoiceViaWhatsApp(
          invoice: invoice,
          pdfFile: file,
          context: context,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePaymentStatus(BuildContext context) async {
    final success = await context.read<InvoiceProvider>().updatePaymentStatus(
      invoice.id!,
      !invoice.isPaid,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم تحديث حالة الدفع' : 'فشل في تحديث حالة الدفع',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الفاتورة رقم ${invoice.invoiceNumber}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<InvoiceProvider>().deleteInvoice(
        invoice.id!,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف الفاتورة' : 'فشل في حذف الفاتورة'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// صف التفاصيل
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
