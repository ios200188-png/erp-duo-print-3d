import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../settings/domain/business_settings.dart';
import '../domain/invoice.dart';

class InvoicePdfService {
  const InvoicePdfService();

  Future<void> share({
    required Invoice invoice,
    required BusinessSettings company,
  }) async {
    final bytes = await build(invoice: invoice, company: company);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'fatura_duo_print_${invoice.id}.pdf',
    );
  }

  Future<Uint8List> build({
    required Invoice invoice,
    required BusinessSettings company,
  }) async {
    final document = pw.Document();
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');
    final logoData =
        await rootBundle.load('assets/branding/logo_duo_print_3d.png');
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
                    'FATURA COMERCIAL',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1260DC'),
                    ),
                  ),
                  pw.Text('Nº ${invoice.id.toString().padLeft(5, '0')}'),
                  pw.Text('Emissão: ${date.format(invoice.issuedAt)}'),
                  pw.Text('Vencimento: ${date.format(invoice.dueDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('DADOS DA DUO PRINT 3D'),
          _info(company.companyName),
          if (company.document.isNotEmpty)
            _info('Documento: ${company.document}'),
          if (company.address.isNotEmpty) _info(company.address),
          if (company.city.isNotEmpty) _info(company.city),
          if (company.whatsapp.isNotEmpty)
            _info('WhatsApp: ${company.whatsapp}'),
          if (company.email.isNotEmpty) _info('E-mail: ${company.email}'),
          pw.SizedBox(height: 18),
          _sectionTitle('CLIENTE'),
          _info(invoice.customerName),
          if (invoice.customerDocument.isNotEmpty)
            _info('Documento: ${invoice.customerDocument}'),
          if (invoice.customerPhone.isNotEmpty)
            _info('Telefone: ${invoice.customerPhone}'),
          if (invoice.customerEmail.isNotEmpty)
            _info('E-mail: ${invoice.customerEmail}'),
          pw.SizedBox(height: 18),
          _sectionTitle('PRODUTO / SERVIÇO'),
          pw.TableHelper.fromTextArray(
            headers: const ['Descrição', 'Qtd.', 'Valor total'],
            data: [
              [
                invoice.projectName,
                invoice.quantity.toString(),
                money.format(invoice.salePrice),
              ],
            ],
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
          _sectionTitle('PAGAMENTO'),
          _info('Forma de pagamento: ${invoice.paymentMethod}'),
          _info('Status: ${invoice.status}'),
          if (invoice.notes.isNotEmpty) _info('Observações: ${invoice.notes}'),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EEF4FF'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'TOTAL',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Spacer(),
                pw.Text(
                  money.format(invoice.salePrice),
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1260DC'),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Divider(),
          pw.Text(
            'Documento comercial de cobrança. Não substitui nota fiscal.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Duo Print 3D — Imprimindo ideias. Criando soluções.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#111111'),
      ),
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
