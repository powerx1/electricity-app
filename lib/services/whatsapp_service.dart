import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

/// خدمة WhatsApp - WhatsApp Service
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// إرسال رسالة WhatsApp مع الفاتورة
  Future<void> sendInvoiceViaWhatsApp({
    required Invoice invoice,
    required File pdfFile,
    required BuildContext context,
  }) async {
    // إنشاء نص الرسالة
    final message = _buildInvoiceMessage(invoice);

    // عرض حوار التأكيد
    final confirmed = await _showConfirmationDialog(context, invoice, message);

    if (!confirmed) return;

    try {
      // مشاركة الملف مع الرسالة
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: message,
        subject: 'فاتورة كهرباء رقم ${invoice.invoiceNumber}',
      );
    } catch (e) {
      // في حالة فشل المشاركة، حاول فتح WhatsApp مباشرة
      await _openWhatsAppDirectly(invoice.customerPhone, message);
    }
  }

  /// إرسال رسالة نصية فقط عبر WhatsApp
  Future<void> sendMessageViaWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    final encodedMessage = Uri.encodeComponent(message);

    // رابط WhatsApp
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('لا يمكن فتح WhatsApp');
    }
  }

  /// بناء رسالة الفاتورة
  String _buildInvoiceMessage(Invoice invoice) {
    final buffer = StringBuffer();

    buffer.writeln('🔌 *فاتورة كهرباء*');
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('📋 *رقم الفاتورة:* ${invoice.invoiceNumber}');
    buffer.writeln('📅 *التاريخ:* ${_formatDate(invoice.invoiceDate)}');
    if (invoice.hijriDate != null) {
      buffer.writeln('🗓️ *التاريخ الهجري:* ${invoice.hijriDate}');
    }
    buffer.writeln();
    buffer.writeln('👤 *العميل:* ${invoice.customerName}');

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('📊 *تفاصيل الاستهلاك:*');
    buffer.writeln();
    buffer.writeln(
      '⏪ القراءة السابقة: ${invoice.oldReading.toStringAsFixed(0)} kWh',
    );
    buffer.writeln(
      '⏩ القراءة الحالية: ${invoice.newReading.toStringAsFixed(0)} kWh',
    );
    buffer.writeln(
      '⚡ الاستهلاك: ${invoice.consumption.toStringAsFixed(0)} kWh',
    );
    buffer.writeln();
    buffer.writeln(
      '💰 سعر الكيلوواط: \$${invoice.kwhPrice.toStringAsFixed(4)}',
    );
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln(
      '💵 *المبلغ الإجمالي:* \$${invoice.totalAmount.toStringAsFixed(2)} USD',
    );
    buffer.writeln('━━━━━━━━━━━━━━━');

    if (invoice.notes != null && invoice.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 *ملاحظات:* ${invoice.notes}');
    }

    buffer.writeln();
    buffer.writeln('✅ ${invoice.stampText}');

    return buffer.toString();
  }

  /// عرض حوار التأكيد
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    Invoice invoice,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat, color: Colors.green),
            SizedBox(width: 8),
            Text('إرسال عبر WhatsApp'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          invoice.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16),
                        const SizedBox(width: 4),
                        Text(invoice.customerPhone),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'معاينة الرسالة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(message, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'سيتم إرفاق ملف PDF مع الرسالة',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send),
            label: const Text('إرسال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// فتح WhatsApp مباشرة
  Future<void> _openWhatsAppDirectly(String phoneNumber, String message) async {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// تنظيف رقم الهاتف
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
