import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  // --- 1. GENERATE SALES RECEIPT ---
  static Future<void> generateReceipt(
      String sNo,
      String date,
      String propertyNameAndAddress,
      String buyerName,
      String buyerAddress,
      String buyerMob,
      String flatProperty,
      String floor,
      String totalAmount,
      String totalAmountWords,
      String advanceAmount,
      String advanceAmountWords,
      String paymentType,
      String referenceNo,
      String furtherPayments,
      ) async {
    final pdf = pw.Document();
    final logoImage = await imageFromAssetBundle('assets/logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage, sNo, date),
              pw.SizedBox(height: 10),

              _buildSectionTitle("Property Details"),
              _buildRow("Property Name & Add:", propertyNameAndAddress),
              pw.Divider(),

              _buildSectionTitle("Buyer Details"),
              _buildRow("Name:", buyerName),
              _buildRow("Address:", buyerAddress),
              _buildRow("Mobile:", buyerMob),
              _buildRow("Flat / Property:", flatProperty),
              _buildRow("Floor:", floor),
              pw.Divider(),

              _buildSectionTitle("Payment Information"),
              _buildRow("Total Consideration:", "$totalAmount"),
              _buildRow("In Words:", totalAmountWords, isBold: false),
              pw.SizedBox(height: 5),
              _buildRow("Advance Amount:", "$advanceAmount"),
              _buildRow("In Words:", advanceAmountWords, isBold: false),
              pw.SizedBox(height: 5),
              _buildRow("Payment Type:", paymentType),
              _buildRow("Reference/Cheque No:", referenceNo),

              pw.SizedBox(height: 10),
              pw.Text("Further Payment Terms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text(furtherPayments, style: const pw.TextStyle(fontSize: 10)),
              ),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // --- 2. GENERATE CONTRACTOR AGREEMENT ---
  static Future<void> generateAgreement(
      String sNo,
      String date,
      String propertyNameAndAddress,
      String contractorName,
      String sectorDomain,
      String contractorMob,
      String contractorAdd,
      String agreedRate,
      String totalAmount,
      String amountInWords,
      String agreementTerms,
      ) async {
    final pdf = pw.Document();
    final logoImage = await imageFromAssetBundle('assets/logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage, sNo, date, title: "CONTRACTOR AGREEMENT"),
              pw.SizedBox(height: 10),

              _buildSectionTitle("Site / Property Details"),
              _buildRow("Property Name & Add:", propertyNameAndAddress),
              pw.Divider(),

              _buildSectionTitle("Contractor Details"),
              _buildRow("Name:", contractorName),
              _buildRow("Sector / Domain:", sectorDomain),
              _buildRow("Mobile:", contractorMob),
              _buildRow("Address:", contractorAdd),
              pw.Divider(),

              _buildSectionTitle("Payment Info"),
              _buildRow("Agreed Rate:", agreedRate),
              _buildRow("Total Amount:", totalAmount),
              _buildRow("In Words:", amountInWords, isBold: false),
              pw.Divider(),

              pw.Text("Agreement Terms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                height: 200, // Fixed height for terms
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text(agreementTerms, style: const pw.TextStyle(fontSize: 10)),
              ),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }


  static pw.Widget _buildHeader(pw.ImageProvider logo, String sNo, String date, {String title = "PAYMENT RECEIPT"}) {
    return pw.Column(
      children: [
        // STEP 1: The "3-Column Shelf" Row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // [Col 1] LEFT SIDE: S.No and Date
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("S.No: $sNo", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Date: $date", style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            // [Col 2] CENTER: The Logo
            pw.Container(
              height: 70,
              width: 70,
              child: pw.Image(logo),
            ),

            // [Col 3] RIGHT SIDE: Invisible empty box to balance the layout
            pw.Expanded(
              child: pw.Container(),
            ),
          ],
        ),

        pw.SizedBox(height: 5),

        // STEP 2: Company Details (Below the Logo)
        pw.Center(child: pw.Text("BHAVIK DEVELOPERS", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text("Reg. Add: H-1, near baba bakhtawar chowk, H-block,\nAya Nagar, New Delhi - 110047", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
        pw.Center(child: pw.Text("Mob: 9717729910, 9999917729 | Email: bhavikdevelopers@gmail.com", style: const pw.TextStyle(fontSize: 9))),

        pw.Divider(thickness: 2),
        pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5, bottom: 5),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
    );
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = true}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 120, child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5))),
              child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            pw.Container(height: 40, width: 80),
            pw.Text("Stamp & Sign", style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}