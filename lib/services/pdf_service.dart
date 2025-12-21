import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

class PdfService {

  static const PdfColor black = PdfColor.fromInt(0xff000000);
  static const PdfColor darkHeaderColor = PdfColor.fromInt(0xff404040);
  static const PdfColor sectionHeaderColor = PdfColor.fromInt(0xffA0A0A0);
  static const PdfColor fieldBgColor = PdfColor.fromInt(0xffE3F2FD);



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

    // 1. Auto Amount Words
    double amountVal = double.tryParse(data['total_amount'].toString()) ?? 0;
    String amountInWords = "${convertNumberToWords(amountVal.toInt())} ONLY";
    String totalAmountStr = "Rs. ${amountVal.toStringAsFixed(0)}/-";

    // 2. Advance & Other Fields
    String advanceStr = "Rs. ${data['advance'] ?? '0'}/-";

    // 3. Terms Processing
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
              // --- HEADER (Logo) ---
              _buildCompactHeader(data, logoImage),

              // --- BODY (Exact format from image) ---
              pw.Column(
                children: [
                  pw.SizedBox(height: 15),

                  // Registered Address Section - Exact format
                  pw.Container(
                    width: double.infinity,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'H-1, Near Baba Bakhtawar Chowk,',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'H-block, Aya Nagar, New Delhi - 110047',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '9717729910, 9999917729',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'bhavikdevelopers@gmail.com',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // PROPERTY DETAILS section
                  _buildSectionHeader('PROPERTY DETAILS'),
                  _buildFieldRow('Project Name', data['projectName'] ?? ''),
                  _buildFieldRow('Address', data['address'] ?? ''),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _buildFieldRow('Flat/Property Type', data['propertyType'] ?? '')),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: _buildFieldRow('Floor', data['floor'] ?? '')),
                    ],
                  ),

                  pw.SizedBox(height: 15),

                  // BUYER DETAILS section
                  _buildSectionHeader('BUYER DETAILS'),
                  _buildFieldRow('Name', data['party_name'] ?? ''),
                  _buildFieldRow('Address', data['address'] ?? ''),
                  _buildFieldRow('Mobile Number', data['mobile'] ?? ''),
                  _buildFieldRow('Email', data['email'] ?? ''),

                  pw.SizedBox(height: 15),

                  // PAYMENT DETAILS section
                  _buildSectionHeader('PAYMENT DETAILS'),
                  _buildFieldRow('Total Consideration Amount', totalAmountStr),
                  _buildFieldRow('Amount (In Words)', amountInWords),
                  _buildFieldRow('Advance', advanceStr),
                  pw.Row(
                    children: [
                      pw.Expanded(child: _buildFieldRow('Payment Type', data['payment_type'] ?? '')),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: _buildFieldRow('Payment Date', data['payment_date'] ?? '')),
                    ],
                  ),

                  pw.SizedBox(height: 15),

                  // Further Payment Terms section
                  pw.Text(
                    'Further Payment Terms :',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: double.infinity,
                    color: fieldBgColor,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: termsList.map((term) =>
                          pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Bullet(text: term, style: const pw.TextStyle(fontSize: 9))
                          )
                      ).toList(),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40, width: 80),
                      pw.Text('Stamp and Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                ],
              )
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

    // 1. Auto Amount Words
    double amountVal = double.tryParse(data['total_amount'].toString()) ?? 0;
    String amountInWords = "${convertNumberToWords(amountVal.toInt())} ONLY";
    String totalAmountStr = "Rs. ${amountVal.toStringAsFixed(0)}/-";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- HEADER (Logo) ---
              _buildCompactHeader(data, logoImage),

              // --- BODY ---
              pw.Column(
                children: [
                  // Contract Agreement Strip
                  pw.Container(
                    height: 28,
                    alignment: pw.Alignment.center,
                    color: darkHeaderColor,
                    child: pw.Text(
                      'CONTRACT AGREEMENT',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // Registered Address Section - Same as receipt
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'H-1, Near Baba Bakhtawar Chowk,\nH-block, Aya Nagar, New Delhi - 110047',
                          style:  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '9717729910, 9999917729',
                          style:  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'bhavikdevelopers@gmail.com',
                          style:  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  sectionHeader('CONTRACTOR DETAILS'),
                  rowField('Name', data['contractor_name'] ?? ''),
                  rowField('Domain', data['domain'] ?? ''),
                  rowField('Mobile Number', data['mobile'] ?? ''),
                  plottingBox('Address', data['address'] ?? '', height: 40),

                  sectionHeader('PROPERTY DETAILS'),
                  rowField('Project Name', data['propertyName'] ?? ''),
                  plottingBox('Address', data['address'] ?? '', height: 40),

                  sectionHeader('PAYMENT DETAILS'),
                  rowField('Total Amount', totalAmountStr),
                  plottingBox('Amount (In Words)', amountInWords, height: 35),
                  rowField('Rate', data['rate'] ?? ''),

                  // Terms Section
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Terms & Conditions :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: double.infinity,
                    color: fieldBgColor,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      data['terms'] ?? '',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                      children: [
                        pw.SizedBox(height: 40, width: 80),
                        pw.Text('Stamp and Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ]
                  )
                ],
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ================= UI HELPERS =================

  // Header to match exact image format
  static pw.Widget _buildCompactHeader(Map<String, dynamic> data, pw.MemoryImage logo) {
    return pw.Column(
      children: [
        // Top row with Date, Logo, and S.No
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 30),
                pw.Row(
                  children: [
                    pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(width: 5),
                    pw.Container(
                      width: 80,
                      height: 15,
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: black))),
                      child: pw.Text(data['date'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
            
            // Logo - centered and larger
            pw.Expanded(
              child: pw.Container(
                height: 150,
                alignment: pw.Alignment.center,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
            
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(height: 30),
                pw.Row(
                  children: [
                    pw.Text('Sn. No.:', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(width: 5),
                    pw.Container(
                      width: 60,
                      height: 15,
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: black))),
                      child: pw.Text(data['sNo'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        
        // PAYMENT RECEIPT header bar
        pw.SizedBox(height: 20),
        pw.Container(
          height: 30,
          width: double.infinity,
          color: darkHeaderColor,
          alignment: pw.Alignment.center,
          child: pw.Text(
            'PAYMENT RECEIPT',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      color: PdfColors.grey400,
      child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text('$label :', style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: fieldBgColor,
              child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget sectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      color: PdfColors.grey400,
      child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  // FIXED: Ab ye 'value' show karega blue box ke andar
  static pw.Widget rowField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text('$label :', style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: fieldBgColor,
              // Yahan pehle child missing tha, isliye text nahi dikh raha tha
              child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Ab ye 'value' show karega
  static pw.Widget plottingBox(String label, String value, {double height = 40}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text('$label :', style: pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Container(
              height: height,
              padding: const pw.EdgeInsets.all(4),
              color: fieldBgColor,
              child: pw.Text(value, style: pw.TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _saveAndLaunchFile(Uint8List bytes, String fileName) async {
    try {
      // Use printing package to share/download PDF
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
        subject: 'Receipt PDF',
        body: 'Please find attached receipt PDF',
      );
      
      print("PDF shared/downloaded successfully: $fileName");
    } catch (e) {
      print("Error sharing PDF: $e");
      // Fallback: Try to save to downloads directory
      try {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
          final result = await OpenFilex.open(file.path);
          print("File saved to downloads and opened: ${file.path}");
        }
      } catch (fallbackError) {
        print("Fallback error: $fallbackError");
      }
    }
  }

  static Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, try to get external storage directory
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      } catch (e) {
        print("Error getting external storage: $e");
      }
    } else if (Platform.isIOS) {
      // For iOS, get documents directory
      return await getApplicationDocumentsDirectory();
    }
    
    // Fallback to application documents directory
    return await getApplicationDocumentsDirectory();
  }

  // Helper: Number to Words
  static String convertNumberToWords(int number) {
    if (number == 0) return "Zero";
    final units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    String words = "";
    if ((number / 10000000).floor() > 0) { words += "${convertNumberToWords((number / 10000000).floor())} Crore "; number %= 10000000; }
    if ((number / 100000).floor() > 0) { words += "${convertNumberToWords((number / 100000).floor())} Lakh "; number %= 100000; }
    if ((number / 1000).floor() > 0) { words += "${convertNumberToWords((number / 1000).floor())} Thousand "; number %= 1000; }
    if ((number / 100).floor() > 0) { words += "${convertNumberToWords((number / 100).floor())} Hundred "; number %= 100; }
    if (number > 0) { if (words != "") words += "and "; if (number < 20) { words += units[number]; } else { words += tens[(number / 10).floor()]; if ((number % 10) > 0) { words += " ${units[number % 10]}"; } } }
    return words.toUpperCase();
  }
}