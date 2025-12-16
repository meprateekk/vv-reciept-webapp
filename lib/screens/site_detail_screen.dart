import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_generator.dart'; // <--- Import the Generator
import 'document_selection_dialog.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const SiteDetailScreen({super.key, required this.siteId, required this.siteName});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final _supabase = Supabase.instance.client;

  // --- DELETE FUNCTION ---
  Future<void> _deleteDocument(String docId) async {
    try {
      await _supabase.from('documents').delete().eq('id', docId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- DOWNLOAD PDF FUNCTION (FIXED) ---
  Future<void> _downloadPdf(Map<String, dynamic> doc) async {
    final type = doc['type'];
    final content = doc['content'];

    if (content == null) return;

    try {
      if (type == 'receipt') {
        // Generate Sales Receipt
        await PdfGenerator.generateReceipt(
          content['sNo']?.toString() ?? '',
          content['date']?.toString() ?? '',
          content['propertyName']?.toString() ?? '',
          content['party_name']?.toString() ?? '',
          content['buyer_address']?.toString() ?? '',
          content['buyer_mob']?.toString() ?? '',
          content['flat_property']?.toString() ?? '',
          content['floor']?.toString() ?? '',
          content['amount']?.toString() ?? '',
          content['amount_words']?.toString() ?? '',
          content['advance']?.toString() ?? '',
          content['advance_words']?.toString() ?? '',
          content['payment_type']?.toString() ?? '',
          content['reference_no']?.toString() ?? '',
          content['further_payments']?.toString() ?? '',
        );
      } else if (type == 'agreement') {
        // Generate Contractor Agreement
        await PdfGenerator.generateAgreement(
          content['sNo']?.toString() ?? '',
          content['date']?.toString() ?? '',
          content['propertyName']?.toString() ?? '',
          content['contractor_name']?.toString() ?? '',
          content['domain']?.toString() ?? '',
          content['mobile']?.toString() ?? '',
          content['address']?.toString() ?? '',
          content['rate']?.toString() ?? '',
          content['total_amount']?.toString() ?? '',
          content['amount_words']?.toString() ?? '',
          content['terms']?.toString() ?? '',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
    }
  }

  // --- SHOW POPUP ---
  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => DocumentSelectionDialog(
        siteId: widget.siteId,
        siteName: widget.siteName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.siteName)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('documents').stream(primaryKey: ['id']).eq('site_id', widget.siteId).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!;

          if (docs.isEmpty) {
            return const Center(child: Text("No documents found. Click + to add."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final content = doc['content'] ?? {};
              final type = doc['type'];

              // Decide Title and Icon based on type
              String title = "Document";
              IconData icon = Icons.insert_drive_file;
              String subTitle = "";

              if (type == 'receipt') {
                title = "Sales Receipt";
                icon = Icons.receipt_long;
                subTitle = "${content['party_name']} - ₹${content['amount']}";
              } else if (type == 'agreement') {
                title = "Contract Agreement";
                icon = Icons.handshake;
                subTitle = "${content['contractor_name']} - ${content['domain']}";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Icon, Title, Date
                      Row(
                        children: [
                          Icon(icon, color: Colors.blue),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(content['date']?.substring(0, 10) ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(subTitle, style: const TextStyle(fontSize: 14)),
                      const Divider(),

                      // Row 2: Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // DOWNLOAD BUTTON
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("PDF"),
                            onPressed: () => _downloadPdf(doc), // <--- Pass the whole 'doc'
                          ),

                          // DELETE BUTTON
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text("Delete", style: TextStyle(color: Colors.red)),
                            onPressed: () => _deleteDocument(doc['id']),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormatDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}