import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import 'receipt_form_screen.dart';
import 'contract_form.dart';

// ==========================================
// 1. CLIENT LIST SCREEN (Level 3)
// ==========================================
class ClientListScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final String type; // 'receipt' or 'agreement'

  const ClientListScreen({super.key, required this.siteId, required this.siteName, required this.type});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'receipt' ? "Sales - ${widget.siteName}" : "Contractors - ${widget.siteName}"),
        backgroundColor: widget.type == 'receipt' ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // 1. REFRESH BUTTON
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by client name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // FIX: Removed .eq() from stream call
              stream: _supabase.from('documents').stream(primaryKey: ['id']).eq('site_id', widget.siteId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Manual filter for document type
                final filteredDocs = snapshot.data!.where((doc) => doc['type'] == widget.type).toList();

                // Grouping Logic
                Map<String, List<Map<String, dynamic>>> groupedClients = {};
                for (var doc in filteredDocs) {
                  final content = doc['content'] ?? {};
                  String name = widget.type == 'receipt'
                      ? (content['party_name'] ?? '')
                      : (content['contractor_name'] ?? '');

                  if (name.toLowerCase().contains(_searchQuery)) {
                    groupedClients.putIfAbsent(name, () => []).add(doc);
                  }
                }

                if (groupedClients.isEmpty) return const Center(child: Text("No clients found."));

                return ListView(
                  children: groupedClients.entries.map((entry) {
                    final firstDoc = entry.value.first['content'];

                    // SUMMARY CALCULATIONS
                    double totalConsideration = double.tryParse(firstDoc['total_amount']?.toString() ?? '0') ?? 0;
                    double totalPaid = 0;
                    for (var doc in entry.value) {
                      totalPaid += double.tryParse(doc['content']['advance']?.toString() ?? '0') ?? 0;
                    }
                    double pendingAmount = totalConsideration - totalPaid;
                    String propertyType = widget.type == 'receipt'
                        ? (firstDoc['propertyType'] ?? 'N/A')
                        : (firstDoc['domain'] ?? 'N/A');

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailScreen(
                              clientName: entry.key,
                              documents: entry.value,
                              siteName: widget.siteName,
                              siteId: widget.siteId,
                              type: widget.type,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStat("Type", propertyType),
                                  _buildStat("Receipts", entry.value.length.toString()),
                                  _buildStat("Paid", "₹${totalPaid.toStringAsFixed(0)}"),
                                  _buildStat("Pending", "₹${pendingAmount.toStringAsFixed(0)}",
                                      color: pendingAmount > 0 ? Colors.red : Colors.green),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.type == 'receipt' ? Colors.blue : Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.type == 'receipt'
                  ? ReceiptFormScreen(siteId: widget.siteId, siteName: widget.siteName)
                  : ContractFormScreen(siteId: widget.siteId, siteName: widget.siteName),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }
}

// ==========================================
// 2. CLIENT DETAIL SCREEN (Level 4)
// ==========================================
class ClientDetailScreen extends StatefulWidget {
  final String clientName;
  final List<Map<String, dynamic>> documents;
  final String siteName, siteId, type;

  const ClientDetailScreen({
    super.key, required this.clientName, required this.documents,
    required this.siteName, required this.siteId, required this.type
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _deleteDoc(String id) async {
    await _supabase.from('documents').delete().eq('id', id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = widget.documents.where((doc) =>
        (doc['content']['sNo'] ?? '').toString().contains(_searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => Navigator.pop(context))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: 'Search Serial No...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final doc = filteredHistory[index];
                final content = doc['content'];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(child: Text(content['sNo'] ?? "0")),
                        title: Text("Paid: ₹${content['advance']}"),
                        subtitle: Text("Date: ${content['payment_date'] ?? content['date']}"),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 3. EDIT BUTTON: Prefills data
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                            label: const Text("Edit", style: TextStyle(color: Colors.orange)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiptFormScreen(
                              siteId: widget.siteId, siteName: widget.siteName, initialData: doc, isEdit: true,
                            ))),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text("Delete", style: TextStyle(color: Colors.red)),
                            onPressed: () => _deleteDoc(doc['id']),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 18, color: Colors.blue),
                            label: const Text("PDF", style: TextStyle(color: Colors.blue)),
                            onPressed: () => widget.type == 'receipt'
                                ? PdfService.downloadAndSaveReceipt(content)
                                : PdfService.downloadAndSaveAgreement(content),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiptFormScreen(
          siteId: widget.siteId, siteName: widget.siteName, initialData: widget.documents.first, isNewPayment: true,
        ))),
        child: const Icon(Icons.add_card),
      ),
    );
  }
}