import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../settings/domain/business_settings.dart';
import '../domain/quote_detail.dart';

class QuotePdfService {
  const QuotePdfService();

  Future<Uint8List> build({
    required QuoteDetail quote,
    required BusinessSettings company,
  }) async {
    final document = pw.Document();
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');
    final validity = quote.createdAt.add(const Duration(days: 15));

    final logoData = await rootBundle.load(
      'assets/branding/logo_duo_print_3d.png',
    );
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logo, width: 150),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'ORÇAMENTO',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1260DC'),
                    ),
                  ),
                  pw.Text('Nº ${quote.id.toString().padLeft(5, '0')}'),
                  pw.Text('Emissão: ${date.format(quote.createdAt)}'),
                  pw.Text('Validade: ${date.format(validity)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('DADOS DA DUO PRINT 3D'),
          _info(_pdfSafeText(company.companyName)),
          if (company.document.isNotEmpty)
            _info(_pdfSafeText('Documento: ${company.document}')),
          if (company.address.isNotEmpty) _info(_pdfSafeText(company.address)),
          if (company.city.isNotEmpty) _info(_pdfSafeText(company.city)),
          if (company.whatsapp.isNotEmpty)
            _info(_pdfSafeText('WhatsApp: ${company.whatsapp}')),
          if (company.email.isNotEmpty)
            _info(_pdfSafeText('E-mail: ${company.email}')),
          pw.SizedBox(height: 18),
          _sectionTitle('CLIENTE'),
          _info(_pdfSafeText(quote.customerName)),
          if (quote.customerDocument.isNotEmpty)
            _info(_pdfSafeText('Documento: ${quote.customerDocument}')),
          if (quote.customerPhone.isNotEmpty)
            _info(_pdfSafeText('Telefone: ${quote.customerPhone}')),
          if (quote.customerEmail.isNotEmpty)
            _info(_pdfSafeText('E-mail: ${quote.customerEmail}')),
          pw.SizedBox(height: 18),
          _sectionTitle('PRODUTOS / SERVIÇOS'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Descrição',
              'Material',
              'Qtd.',
              'Valor unit.',
              'Valor total',
            ],
            data: quote.items
                .map(
                  (item) => [
                    _pdfSafeText(
                      item.description.isEmpty
                          ? (item.projectVersion.isEmpty
                                ? item.projectName
                                : '${item.projectName} - ${item.projectVersion}')
                          : item.description,
                    ),
                    _pdfSafeText('${item.materialName} (${item.materialType})'),
                    item.quantity.toString(),
                    money.format(item.unitPrice),
                    money.format(item.totalPrice),
                  ],
                )
                .toList(),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1260DC'),
            ),
            headerStyle: const pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          pw.SizedBox(height: 18),
          if (quote.notes.isNotEmpty) ...[
            _sectionTitle('OBSERVAÇÕES'),
            _info(_pdfSafeText(quote.notes)),
            pw.SizedBox(height: 18),
          ],
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EEF4FF'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _totalRow('Subtotal', money.format(quote.subtotal)),
                if (quote.discountAmount > 0)
                  _totalRow(
                    quote.discountType == 'Valor'
                        ? 'Desconto'
                        : 'Desconto (${quote.discountValue.toStringAsFixed(2)}%)',
                    '- ${money.format(quote.discountAmount)}',
                  ),
                pw.Divider(),
                pw.Row(
                  children: [
                    pw.Text(
                      'TOTAL DO ORÇAMENTO',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      money.format(quote.salePrice),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1260DC'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Prazo e condições podem ser confirmados no momento da aprovação.',
          ),
          pw.Text('Este orçamento é válido até ${date.format(validity)}.'),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Duo Print 3D - Imprimindo ideias. Criando soluções.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> printQuote({
    required QuoteDetail quote,
    required BusinessSettings company,
  }) async {
    final bytes = await build(quote: quote, company: company);
    await Printing.layoutPdf(
      name: 'Orçamento Duo Print ${quote.id}',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> shareQuote({
    required QuoteDetail quote,
    required BusinessSettings company,
  }) async {
    final bytes = await build(quote: quote, company: company);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'orcamento_duo_print_${quote.id}.pdf',
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(children: [pw.Text(label), pw.Spacer(), pw.Text(value)]),
    );
  }

  static String _pdfSafeText(String text) {
    return text
        .replaceAll('×', 'x')
        .replaceAll('✕', 'x')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#111111')),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _info(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Text(text),
    );
  }
}
