import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

class PdfService {
  static const PdfColor black = PdfColor.fromInt(0xff000000);
  static const PdfColor darkHeaderColor = PdfColor.fromInt(0xff404040);
  static const PdfColor fieldBgColor = PdfColor.fromInt(0xffE3F2FD);

  // ==========================================
  // 1. PUBLIC METHODS (Used by your Screens)
  // ==========================================

  static Future<void> downloadAndSaveReceipt(Map<String, dynamic> data) async {
    try {
      final pdfBytes = await _generatePaymentReceipt(data);
      await _saveAndLaunchFile(pdfBytes, "Receipt_${data['party_name'] ?? 'Client'}.pdf");
    } catch (e) {
      print("Error in downloadAndSaveReceipt: $e");
    }
  }

  static Future<void> downloadAndSaveAgreement(Map<String, dynamic> data) async {
    try {
      final pdfBytes = await _generateContractAgreement(data);
      await _saveAndLaunchFile(pdfBytes, "Agreement_${data['contractor_name'] ?? 'Contractor'}.pdf");
    } catch (e) {
      print("Error in downloadAndSaveAgreement: $e");
    }
  }

  // ==========================================
  // 2. RECEIPT GENERATOR LOGIC
  // ==========================================
  static Future<Uint8List> _generatePaymentReceipt(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    double amountVal = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0;
    String amountInWords = "${convertNumberToWords(amountVal.toInt())} ONLY";
    String totalAmountStr = "Rs. ${amountVal.toStringAsFixed(0)}/-";
    String advanceStr = "Rs. ${data['advance'] ?? '0'}/-";

    String termsRaw = data['further_payments'] ?? '';
    List<String> termsList = termsRaw.split('\n').where((t) => t.trim().isNotEmpty).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTopBrandingHeader(data, logoImage),
              pw.Container(
                height: 30,
                color: darkHeaderColor,
                alignment: pw.Alignment.center,
                child: pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 15),
              _buildSectionHeader('OFFICE DETAILS'),
              _buildFieldRow('Registered Office', 'H-1, Near Baba Bakhtawar Chowk,'),
              _buildFieldRow('', 'H-block, Aya Nagar, New Delhi - 110047'),
              _buildFieldRow('Contact Numbers', '9717729910, 9999917729'),
              _buildFieldRow('Email Address', 'bhavikdevelopers@gmail.com'),
              pw.SizedBox(height: 15),
              _buildSectionHeader('PROPERTY DETAILS'),
              _buildFieldRow('Project Name', data['projectName'] ?? ''),
              _buildFieldRow('Address', data['address'] ?? ''),
              pw.Row(children: [
                pw.Expanded(child: _buildFieldRow('Property Type', data['propertyType'] ?? '')),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildFieldRow('Floor', data['floor'] ?? '')),
              ]),
              pw.SizedBox(height: 15),
              _buildSectionHeader('BUYER DETAILS'),
              _buildFieldRow('Name', data['party_name'] ?? ''),
              _buildFieldRow('Address', data['address'] ?? ''),
              _buildFieldRow('Mobile Number', data['mobile'] ?? ''),
              _buildFieldRow('Email', data['email'] ?? ''),
              pw.SizedBox(height: 15),
              _buildSectionHeader('PAYMENT DETAILS'),
              _buildFieldRow('Total Consideration', totalAmountStr),
              _buildFieldRow('Amount (In Words)', amountInWords),
              _buildFieldRow('Advance', advanceStr),
              pw.Row(children: [
                pw.Expanded(child: _buildFieldRow('Payment Type', data['payment_type'] ?? '')),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildFieldRow('Payment Date', data['payment_date'] ?? '')),
              ]),
              pw.SizedBox(height: 15),
              pw.Text('Further Payment Terms :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                color: fieldBgColor,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: termsList.map((term) => pw.Bullet(text: term, style: const pw.TextStyle(fontSize: 9))).toList(),
                ),
              ),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // ==========================================
  // 3. AGREEMENT GENERATOR LOGIC
  // ==========================================
  static Future<Uint8List> _generateContractAgreement(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    double amountVal = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0;
    String amountInWords = "${convertNumberToWords(amountVal.toInt())} ONLY";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildTopBrandingHeader(data, logoImage),
              pw.Container(
                height: 30,
                color: darkHeaderColor,
                alignment: pw.Alignment.center,
                child: pw.Text('CONTRACT AGREEMENT', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 15),
              _buildSectionHeader('OFFICE DETAILS'),
              _buildFieldRow('Office Address', 'H-1, Near Baba Bakhtawar Chowk, New Delhi'),
              _buildFieldRow('Contact', '9717729910'),
              pw.SizedBox(height: 15),
              _buildSectionHeader('CONTRACTOR DETAILS'),
              _buildFieldRow('Name', data['contractor_name'] ?? ''),
              _buildFieldRow('Domain', data['domain'] ?? ''),
              _buildFieldRow('Mobile', data['mobile'] ?? ''),
              _buildFieldRow('Address', data['address'] ?? ''),
              pw.SizedBox(height: 15),
              _buildSectionHeader('PAYMENT & TERMS'),
              _buildFieldRow('Total Amount', 'Rs. ${amountVal.toStringAsFixed(0)}/-'),
              _buildFieldRow('Amount (In Words)', amountInWords),
              _buildFieldRow('Rate', data['rate'] ?? ''),
              pw.SizedBox(height: 10),
              pw.Text('Terms & Conditions :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Container(
                width: double.infinity,
                color: fieldBgColor,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(data['terms'] ?? '', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // ==========================================
  // 4. UI HELPERS
  // ==========================================

  static pw.Widget _buildTopBrandingHeader(Map<String, dynamic> data, pw.MemoryImage logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(children: [pw.SizedBox(height: 30), _buildHeaderLine('Date:', data['date'] ?? '')]),
        pw.Container(height: 140, width: 180, alignment: pw.Alignment.center, child: pw.Image(logo, fit: pw.BoxFit.contain)),
        pw.Column(children: [pw.SizedBox(height: 30), _buildHeaderLine('Sn. No.:', data['sNo'] ?? '')]),
      ],
    );
  }

  static pw.Widget _buildHeaderLine(String label, String value) {
    return pw.Row(children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(width: 5),
      pw.Container(width: 70, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: black))), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
    ]);
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      color: PdfColors.grey400,
      child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(width: 130, child: pw.Text(label.isEmpty ? '' : '$label :', style: const pw.TextStyle(fontSize: 10))),
        pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: fieldBgColor, child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
      ]),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
      pw.Column(children: [pw.SizedBox(height: 40), pw.Text('Stamp and Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))]),
    ]);
  }

  static Future<void> _saveAndLaunchFile(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static String convertNumberToWords(int number) {
    if (number == 0) return "ZERO";
    final units = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"];
    final tens = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"];
    String words = "";
    if ((number / 100000).floor() > 0) { words += "${convertNumberToWords((number / 100000).floor())} LAKH "; number %= 100000; }
    if ((number / 1000).floor() > 0) { words += "${convertNumberToWords((number / 1000).floor())} THOUSAND "; number %= 1000; }
    if ((number / 100).floor() > 0) { words += "${convertNumberToWords((number / 100).floor())} HUNDRED "; number %= 100; }
    if (number > 0) { if (words != "") words += "AND "; if (number < 20) words += units[number]; else { words += tens[(number / 10).floor()]; if ((number % 10) > 0) words += " ${units[number % 10]}"; } }
    return words.trim().toUpperCase();
  }
}