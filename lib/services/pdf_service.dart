import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {

  // Logic to generate the PDF based on your "Bhavik Developers" design
  Future<Uint8List> generateReceipt(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final partyName = data['party_name'] ?? 'Client Name';
    final amount = data['amount'] ?? '0';
    final date = data['date']?.substring(0, 10) ?? DateTime.now().toString();
    final description = data['description'] ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER (Company Details) ---
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Bhavik Developers", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Gwalior, MP"),
                        pw.Text("GST No: 23AAAAA0000A1Z5"),
                        pw.Text("Contact: +91 9876543210"),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // --- TITLE ---
              pw.Center(
                child: pw.Text("PAYMENT RECEIPT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              ),
              pw.SizedBox(height: 20),

              // --- BUYER DETAILS BOX ---
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Buyer / Allottee Details", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                    _buildRow("Name:", partyName),
                    _buildRow("Address:", "Gwalior, MP"), // Static for now, can be dynamic
                    _buildRow("Receipt No:", "1001"), // Static for now
                    _buildRow("Date:", date),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // --- PAYMENT INFO ---
              pw.Text("Payment Information", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    _cell("Description", isBold: true),
                    _cell("Amount (INR)", isBold: true),
                  ]),
                  pw.TableRow(children: [
                    _cell(description.isEmpty ? "Booking Amount" : description),
                    _cell("Rs. $amount"),
                  ]),
                ],
              ),

              pw.SizedBox(height: 20),

              // --- TERMS ---
              pw.Text("Terms & Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "This receipt is valid subject to realization of cheque."),
              pw.Bullet(text: "Taxes extra as applicable."),

              pw.Spacer(),

              // --- FOOTER (Signatures) ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Container(height: 1, width: 100, color: PdfColors.black),
                    pw.Text("Customer Signature"),
                  ]),
                  pw.Column(children: [
                    pw.Container(height: 1, width: 100, color: PdfColors.black),
                    pw.Text("Authorized Signatory"),
                    pw.Text("Bhavik Developers", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper for rows inside the box
  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Text(value),
        ],
      ),
    );
  }

  // Helper for table cells
  pw.Widget _cell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}