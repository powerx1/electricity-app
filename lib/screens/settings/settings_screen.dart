import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import '../../services/services.dart';

/// شاشة الإعدادات - Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelSettings),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // إعدادات الشركة
              _buildSectionHeader('معلومات الشركة', Icons.business),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.store,
                  title: 'اسم الشركة',
                  subtitle: provider.companyName,
                  onTap: () => _showEditDialog(
                    title: 'اسم الشركة',
                    currentValue: provider.companyName,
                    onSave: (value) => provider.updateCompanyName(value),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // إعدادات الفوترة
              _buildSectionHeader('إعدادات الفوترة', Icons.receipt),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.attach_money,
                  title: 'سعر الكيلوواط الافتراضي',
                  subtitle: '\$${provider.defaultKwhPrice.toStringAsFixed(4)}',
                  onTap: () => _showEditDialog(
                    title: 'سعر الكيلوواط (USD)',
                    currentValue: provider.defaultKwhPrice.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSave: (value) {
                      final price = double.tryParse(value);
                      if (price != null) {
                        return provider.updateDefaultKwhPrice(price);
                      }
                      return Future.value(false);
                    },
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.verified,
                  title: 'نص الختم',
                  subtitle: provider.stampText,
                  onTap: () => _showEditDialog(
                    title: 'نص الختم / التوقيع',
                    currentValue: provider.stampText,
                    onSave: (value) => provider.updateStampText(value),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.date_range, color: AppTheme.primaryColor),
                  ),
                  title: const Text('إظهار التاريخ الهجري'),
                  subtitle: Text(
                    provider.showHijriDate ? 'مفعّل' : 'معطّل',
                  ),
                  value: provider.showHijriDate,
                  onChanged: (value) => provider.updateShowHijriDate(value),
                ),
              ]),
              const SizedBox(height: 20),

              // إعدادات الطباعة
              _buildSectionHeader('الطباعة', Icons.print),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.bluetooth,
                  title: 'الطابعة الحرارية',
                  subtitle: PrintingService().isConnected
                      ? 'متصل: ${PrintingService().connectedDevice?.name}'
                      : 'غير متصل',
                  trailing: PrintingService().isConnected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _showPrinterSettings(),
                ),
              ]),
              const SizedBox(height: 20),

              // استيراد/تصدير
              _buildSectionHeader('البيانات', Icons.storage),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.upload_file,
                  title: 'استيراد عملاء من Excel',
                  subtitle: 'استيراد قائمة العملاء من ملف Excel',
                  onTap: () => _importCustomers(),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.download,
                  title: 'تحميل قالب Excel',
                  subtitle: 'قالب لاستيراد العملاء',
                  onTap: () => _downloadTemplate(),
                ),
              ]),
              const SizedBox(height: 20),

              // حول التطبيق
              _buildSectionHeader('حول التطبيق', Icons.info),
              _buildSettingsCard([
                _SettingsTile(
                  icon: Icons.electric_bolt,
                  title: AppConstants.appName,
                  subtitle: 'الإصدار 1.0.0',
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.restore,
                  title: 'إعادة الإعدادات الافتراضية',
                  subtitle: 'استعادة جميع الإعدادات للقيم الافتراضية',
                  trailing: const Icon(Icons.warning, color: Colors.orange),
                  onTap: () => _confirmReset(),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Future<void> _showEditDialog({
    required String title,
    required String currentValue,
    required Future<bool> Function(String) onSave,
    TextInputType? keyboardType,
  }) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'أدخل $title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final success = await onSave(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context, success);
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successSettingsUpdated),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showPrinterSettings() async {
    final printingService = PrintingService();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => Padding(
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
                const Text(
                  'إعدادات الطابعة الحرارية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اتصل بطابعة Xprinter الحرارية عبر Bluetooth',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                
                if (printingService.isConnected) ...[
                  Card(
                    color: Colors.green[50],
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                      title: Text(printingService.connectedDevice?.name ?? 'طابعة'),
                      subtitle: const Text('متصل'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await printingService.disconnect();
                          setSheetState(() {});
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('قطع الاتصال'),
                      ),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final printers = await printingService.getAvailablePrinters();
                        if (context.mounted) {
                          final selected = await showDialog<dynamic>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('اختر الطابعة'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: printers.isEmpty
                                    ? const Text('لم يتم العثور على طابعات')
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: printers.length,
                                        itemBuilder: (context, index) {
                                          final printer = printers[index];
                                          return ListTile(
                                            leading: const Icon(Icons.print),
                                            title: Text(printer.name),
                                            subtitle: Text(printer.macAdress),
                                            onTap: () => Navigator.pop(context, printer),
                                          );
                                        },
                                      ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إلغاء'),
                                ),
                              ],
                            ),
                          );

                          if (selected != null) {
                            final connected = await printingService.connectToPrinter(selected);
                            if (connected) {
                              setSheetState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم الاتصال بالطابعة'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('البحث عن طابعات'),
                  ),
                ],
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                const Text(
                  'ملاحظات:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildNote('تأكد من تشغيل الطابعة'),
                _buildNote('تأكد من اقتران الطابعة بجهازك'),
                _buildNote('فعّل Bluetooth وخدمات الموقع'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _importCustomers() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الاستيراد: ${result.errors.first.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.electric_bolt,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'تطبيق متكامل لإدارة فواتير الكهرباء',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'المميزات:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• إدارة العملاء'),
        const Text('• إنشاء الفواتير'),
        const Text('• تصدير PDF'),
        const Text('• الطباعة الحرارية'),
        const Text('• إرسال WhatsApp'),
        const Text('• استيراد من Excel'),
      ],
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('تأكيد'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إعادة جميع الإعدادات للقيم الافتراضية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SettingsProvider>().resetToDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم إعادة الإعدادات' : 'فشل في إعادة الإعدادات',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

/// عنصر الإعدادات
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
