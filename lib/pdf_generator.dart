import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

class PdfGenerator {
  static Future<void> generate(ReceiptData data) async {
    final pdf = pw.Document();

    // Navy Blue Color for PDF Headings
    final PdfColor navyBlue = PdfColor.fromInt(0xFF001F3F);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER [cite: 1] ---
              pw.Center(child: pw.Text("Bhavik Developers", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: navyBlue))),
              pw.Center(child: pw.Text("PAYMENT RECEIPT - FLAT BOOKING / REAL ESTATE", style: pw.TextStyle(fontSize: 10))),
              pw.Divider(color: navyBlue),

              // --- BUILDER DETAILS [cite: 1] ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("Registered Address: Gwalior, MP", style: pw.TextStyle(fontSize: 9)),
                    pw.Text("GST No: 23AAAAA0000A1Z5", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("RERA Reg No: P-GWL-20-000", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Contact: +91 9876543210", style: pw.TextStyle(fontSize: 9)),
                  ]),
                  // Receipt Details Block [cite: 1]
                  pw.Container(
                    padding: pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: navyBlue)),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text("Receipt No: ${data.receiptNo}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date: ${data.date}"),
                    ]),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text("Project: ${data.projectName}"),
              pw.Text("Project Address: ${data.projectAddress}", style: pw.TextStyle(fontSize: 9)),

              pw.SizedBox(height: 15),

              // --- BUYER DETAILS BOX [cite: 1] ---
              pw.Header(level: 1, text: "Buyer / Allottee Details", textStyle: pw.TextStyle(fontSize: 12, color: PdfColors.white), decoration: pw.BoxDecoration(color: navyBlue)),
              pw.Container(
                padding: pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Column(children: [
                  _buildRow("Buyer Name:", data.buyerName, "PAN No:", data.panNo),
                  _buildRow("Address:", data.address, "Phone:", data.phone),
                  pw.Divider(),
                  _buildRow("Flat/Unit No:", data.flatNo, "Floor:", data.floor),
                  _buildRow("Type:", data.type, "Super Built-up Area:", data.superArea),
                ]),
              ),

              pw.SizedBox(height: 10),

              // --- PAYMENT INFO [cite: 1] ---
              pw.Header(level: 1, text: "Payment Information", textStyle: pw.TextStyle(fontSize: 12, color: PdfColors.white), decoration: pw.BoxDecoration(color: navyBlue)),
              pw.Row(children: [
                pw.Expanded(child: pw.Text("Total Consideration: ${data.totalConsideration}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(child: pw.Text("Amount Received: ${data.amountReceived}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              pw.SizedBox(height: 5),
              pw.Text("Amount in Words: ${data.amountInWords}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 5),
              pw.Text("Payment Towards: ${data.paymentTowards}"),
              pw.Text("Payment Mode: ${data.paymentMode}"),
              pw.SizedBox(height: 5),
              pw.Text("Balance Outstanding: ${data.balanceAmount}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),

              pw.SizedBox(height: 15),

              // --- INSTALLMENT TABLE [cite: 2, 3] ---
              pw.Text("Installment Description Table:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: navyBlue),
                  headers: ['Inst. No', 'Description / Stage', 'Due Date', 'Amount', 'Status'],
                  data: [
                    ['1', 'Booking Amount', data.date, data.amountReceived, 'PAID'], // Current Payment
                    ['2', 'Plinth Level', '-', '-', 'Pending'],
                    ['3', 'Slab Level', '-', '-', 'Pending'],
                  ],
                  columnWidths: {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(4),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(2),
                  }
              ),

              pw.Spacer(),

              // --- TERMS & SIGNATURE [cite: 4, 7] ---
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text("Terms & Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        _buildBullet("This receipt is valid only for mentioned amount."),
                        _buildBullet("Does not constitute transfer of title."),
                        _buildBullet("Cheques subject to realization."), // [cite: 6]
                        _buildBullet("Taxes extra as applicable."),
                      ]),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(children: [
                        pw.Text("Authorized Signatory", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 30),
                        pw.Container(height: 1, width: 100, color: PdfColors.black),
                        pw.Text("Bhavik Developers"),
                      ]),
                    )
                  ]
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Helper for Rows
  static pw.Widget _buildRow(String label1, String val1, String label2, String val2) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Row(children: [pw.Text(label1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)), pw.SizedBox(width: 5), pw.Text(val1, style: pw.TextStyle(fontSize: 9))])),
        pw.Expanded(child: pw.Row(children: [pw.Text(label2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)), pw.SizedBox(width: 5), pw.Text(val2, style: pw.TextStyle(fontSize: 9))])),
      ]),
    );
  }

  // Helper for Bullets
  static pw.Widget _buildBullet(String text) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text("• ", style: pw.TextStyle(fontSize: 8)),
      pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 8))),
    ]);
  }
}