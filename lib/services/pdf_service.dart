import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'download_helper.dart'; // Tera banaya hua helper

class PdfService {

  // ==========================================
  // 1. EXISTING RECEIPT LOGIC (Isse chedne ki jarurat nahi)
  // ==========================================
  Future<Uint8List> generateReceipt(Map<String, dynamic> data) async {
    // ... (Tera purana receipt code yaha rehne de) ...
    // Agar pura file replace kar raha hai to bata, main wo code bhi de dunga
    // Filhal main maan raha hu Receipt wala code already hai.
    return Uint8List(0); // Placeholder taaki error na aaye
  }

  Future<void> downloadAndSavePdf(Map<String, dynamic> data) async {
    final pdfBytes = await generateReceipt(data);
    await DownloadHelper.saveAndLaunchFile(pdfBytes, "receipt_${DateTime.now().millisecondsSinceEpoch}.pdf");
  }

  // ==========================================
  // 2. NEW: AGREEMENT / CONTRACT LOGIC
  // ==========================================
  Future<Uint8List> generateAgreement(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Header(
                level: 0,
                child: pw.Center(child: pw.Text("CONTRACTOR AGREEMENT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              ),
              pw.SizedBox(height: 20),

              // DETAILS
              pw.Text("This agreement is made on ${data['date']} between:", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),

              pw.Text("BHAVIK DEVELOPERS (The Owner)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("AND"),
              pw.Text("${data['contractor_name']} (The Contractor)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Domain: ${data['domain']}"),
              pw.Text("Address: ${data['address']}"),
              pw.Text("Mobile: ${data['mobile']}"),

              pw.Divider(),
              pw.SizedBox(height: 10),

              // PAYMENT TERMS
              pw.Text("Payment Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 5),
              pw.Bullet(text: "Rate Agreed: Rs. ${data['rate']}"),
              pw.Bullet(text: "Total Amount: Rs. ${data['total_amount']}"),
              pw.Bullet(text: "Amount in Words: ${data['amount_words']}"),

              pw.SizedBox(height: 20),

              // TERMS AND CONDITIONS
              pw.Text("Terms & Conditions:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 5),
              pw.Paragraph(text: data['terms'] ?? "As per company standard policy."),

              pw.Spacer(),

              // SIGNATURES
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Container(height: 1, width: 100, color: PdfColors.black),
                    pw.Text("Contractor Signature"),
                  ]),
                  pw.Column(children: [
                    pw.Container(height: 1, width: 100, color: PdfColors.black),
                    pw.Text("Bhavik Developers"),
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

  // AGREEMENT DOWNLOAD FUNCTION
  Future<void> downloadAndSaveAgreement(Map<String, dynamic> data) async {
    // 1. Generate bytes
    final pdfBytes = await generateAgreement(data);

    // 2. Download/Save using Helper
    final fileName = "agreement_${data['contractor_name']}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    await DownloadHelper.saveAndLaunchFile(pdfBytes, fileName);
  }
}