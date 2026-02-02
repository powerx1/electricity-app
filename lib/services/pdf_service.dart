import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// خدمة إنشاء PDF - PDF Generation Service
class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  pw.Font? _arabicFont;
  pw.Font? _arabicFontBold;

  /// تحميل الخطوط العربية
  Future<void> _loadFonts() async {
    if (_arabicFont != null) return;

    try {
      // استخدام خط عربي من الأصول
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

      _arabicFont = pw.Font.ttf(fontData);
      _arabicFontBold = pw.Font.ttf(fontBoldData);
    } catch (e) {
      // استخدام الخط الافتراضي إذا فشل تحميل الخط العربي
      _arabicFont = pw.Font.helvetica();
      _arabicFontBold = pw.Font.helveticaBold();
    }
  }

  /// إنشاء فاتورة PDF
  Future<Uint8List> generateInvoicePdf(
    Invoice invoice, {
    AppSettings? settings,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    // إنشاء الأنماط
    final titleStyle = pw.TextStyle(
      font: _arabicFontBold,
      fontSize: 24,
      color: PdfColors.blue900,
    );

    final headerStyle = pw.TextStyle(
      font: _arabicFontBold,
      fontSize: 14,
      color: PdfColors.grey800,
    );

    final normalStyle = pw.TextStyle(font: _arabicFont, fontSize: 12);

    final boldStyle = pw.TextStyle(font: _arabicFontBold, fontSize: 12);

    final largeStyle = pw.TextStyle(
      font: _arabicFontBold,
      fontSize: 18,
      color: PdfColors.green800,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // رأس الفاتورة
                _buildHeader(invoice, titleStyle, normalStyle, settings),
                pw.SizedBox(height: 20),

                // معلومات العميل
                _buildCustomerInfo(invoice, headerStyle, normalStyle),
                pw.SizedBox(height: 20),

                // تفاصيل الفاتورة
                _buildInvoiceDetails(
                  invoice,
                  headerStyle,
                  normalStyle,
                  boldStyle,
                ),
                pw.SizedBox(height: 20),

                // حساب الاستهلاك
                _buildConsumptionTable(
                  invoice,
                  headerStyle,
                  normalStyle,
                  boldStyle,
                ),
                pw.SizedBox(height: 20),

                // المبلغ الإجمالي
                _buildTotalSection(invoice, largeStyle, normalStyle),
                pw.SizedBox(height: 30),

                // الملاحظات
                if (invoice.notes != null && invoice.notes!.isNotEmpty)
                  _buildNotesSection(invoice, headerStyle, normalStyle),

                pw.Spacer(),

                // قسم التوقيع والختم
                _buildStampSection(invoice, headerStyle, normalStyle),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// بناء رأس الفاتورة
  pw.Widget _buildHeader(
    Invoice invoice,
    pw.TextStyle titleStyle,
    pw.TextStyle normalStyle,
    AppSettings? settings,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('فاتورة كهرباء', style: titleStyle),
              pw.SizedBox(height: 5),
              pw.Text(
                settings?.companyName ?? 'خدمات فوترة الكهرباء',
                style: normalStyle,
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  'رقم الفاتورة: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                    font: _arabicFontBold,
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'التاريخ: ${_formatDate(invoice.invoiceDate)}',
                style: normalStyle,
              ),
              if (invoice.hijriDate != null)
                pw.Text(
                  'التاريخ الهجري: ${invoice.hijriDate}',
                  style: normalStyle,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء قسم معلومات العميل
  pw.Widget _buildCustomerInfo(
    Invoice invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle normalStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('معلومات العميل', style: headerStyle),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          _buildInfoRow('الاسم:', invoice.customerName, normalStyle),
          _buildInfoRow('رقم الهاتف:', invoice.customerPhone, normalStyle),
          if (invoice.customerAddress != null)
            _buildInfoRow('العنوان:', invoice.customerAddress!, normalStyle),
        ],
      ),
    );
  }

  /// بناء صف معلومات
  pw.Widget _buildInfoRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: style.copyWith(font: _arabicFontBold)),
          ),
          pw.Expanded(child: pw.Text(value, style: style)),
        ],
      ),
    );
  }

  /// بناء تفاصيل الفاتورة
  pw.Widget _buildInvoiceDetails(
    Invoice invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle normalStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('تفاصيل القراءات', style: headerStyle),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildReadingBox(
                'القراءة السابقة',
                invoice.oldReading.toStringAsFixed(0),
                PdfColors.orange,
              ),
              pw.Icon(pw.IconData(0x2192), size: 30, color: PdfColors.grey600),
              _buildReadingBox(
                'القراءة الحالية',
                invoice.newReading.toStringAsFixed(0),
                PdfColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء صندوق القراءة
  pw.Widget _buildReadingBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: _arabicFont,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: _arabicFontBold,
              fontSize: 20,
              color: color,
            ),
          ),
          pw.Text(
            'كيلوواط/ساعة',
            style: pw.TextStyle(
              font: _arabicFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء جدول الاستهلاك
  pw.Widget _buildConsumptionTable(
    Invoice invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle normalStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // رأس الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('البيان', headerStyle, isHeader: true),
            _buildTableCell('الكمية', headerStyle, isHeader: true),
            _buildTableCell('السعر', headerStyle, isHeader: true),
            _buildTableCell('الإجمالي', headerStyle, isHeader: true),
          ],
        ),
        // صف الاستهلاك
        pw.TableRow(
          children: [
            _buildTableCell('استهلاك الكهرباء', normalStyle),
            _buildTableCell(
              '${invoice.consumption.toStringAsFixed(0)} kWh',
              normalStyle,
            ),
            _buildTableCell(
              '\$${invoice.kwhPrice.toStringAsFixed(4)}',
              normalStyle,
            ),
            _buildTableCell(
              '\$${invoice.totalAmount.toStringAsFixed(2)}',
              boldStyle,
            ),
          ],
        ),
      ],
    );
  }

  /// بناء خلية الجدول
  pw.Widget _buildTableCell(
    String text,
    pw.TextStyle style, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  /// بناء قسم المجموع
  pw.Widget _buildTotalSection(
    Invoice invoice,
    pw.TextStyle largeStyle,
    pw.TextStyle normalStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.green400, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('المبلغ الإجمالي المستحق: ', style: normalStyle),
          pw.SizedBox(width: 10),
          pw.Text(
            '\$${invoice.totalAmount.toStringAsFixed(2)} USD',
            style: largeStyle,
          ),
        ],
      ),
    );
  }

  /// بناء قسم الملاحظات
  pw.Widget _buildNotesSection(
    Invoice invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle normalStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.yellow700),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ملاحظات:', style: headerStyle),
          pw.SizedBox(height: 5),
          pw.Text(invoice.notes!, style: normalStyle),
        ],
      ),
    );
  }

  /// بناء قسم الختم والتوقيع
  pw.Widget _buildStampSection(
    Invoice invoice,
    pw.TextStyle headerStyle,
    pw.TextStyle normalStyle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('التوقيع:', style: headerStyle),
              pw.SizedBox(height: 30),
              pw.Container(
                width: 150,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide()),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  invoice.stampText,
                  style: pw.TextStyle(
                    font: _arabicFontBold,
                    fontSize: 12,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ختم رسمي',
                  style: pw.TextStyle(
                    font: _arabicFont,
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// حفظ PDF في ملف
  Future<File> savePdfToFile(Uint8List pdfBytes, String invoiceNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/invoice_$invoiceNumber.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// الحصول على مسار ملف PDF
  Future<String> getPdfPath(String invoiceNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/invoice_$invoiceNumber.pdf';
  }
}
