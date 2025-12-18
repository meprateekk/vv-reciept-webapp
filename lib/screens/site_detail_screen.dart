import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
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

  Future<void> _deleteDocument(String docId) async {
    try {
      await _supabase.from('documents').delete().eq('id', docId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document deleted")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => DocumentSelectionDialog(siteId: widget.siteId, siteName: widget.siteName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.siteName),
        actions: [
          // --- REFRESH BUTTON ADDED HERE ---
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Documents',
            onPressed: () {
              // Simply calling setState triggers the StreamBuilder to reconnect/refresh
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // This query fetches documents specifically for THIS siteId
        stream: _supabase.from('documents').stream(primaryKey: ['id']).eq('site_id', widget.siteId).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!;
          if (docs.isEmpty) return const Center(child: Text("No documents found. Click + to add."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final content = doc['content'] ?? {};
              final type = doc['type'];

              String title = type == 'receipt' ? "Sales Receipt" : "Contract Agreement";
              IconData icon = type == 'receipt' ? Icons.receipt_long : Icons.handshake;
              String subTitle = type == 'receipt'
                  ? "${content['party_name'] ?? ''} - ₹${content['total_amount'] ?? ''}"
                  : "${content['contractor_name'] ?? ''} - ${content['domain'] ?? ''}";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(children: [
                        Icon(icon, color: Colors.blue),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(content['date']?.substring(0, 10) ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ]),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: Text(subTitle, style: const TextStyle(fontSize: 14))),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // --- PDF DOWNLOAD BUTTON ---
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("PDF"),
                            onPressed: () async {
                              final contentData = doc['content'];
                              try {
                                // Show loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Downloading PDF..."))
                                );
                                
                                if (doc['type'] == 'receipt') {
                                  await PdfService.downloadAndSaveReceipt(contentData);
                                } else {
                                  await PdfService.downloadAndSaveAgreement(contentData);
                                }
                                
                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("PDF downloaded successfully!"),
                                      backgroundColor: Colors.green,
                                    )
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error downloading PDF: $e"),
                                      backgroundColor: Colors.red,
                                    )
                                  );
                                }
                              }
                            },
                          ),
                          // --- DELETE BUTTON ---
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
      floatingActionButton: FloatingActionButton(onPressed: _showFormatDialog, child: const Icon(Icons.add)),
    );
  }
}