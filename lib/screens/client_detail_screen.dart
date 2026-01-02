import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import '../services/cached_data_service.dart';
import '../widgets/loading_skeletons.dart';
import 'receipt_form_screen.dart';
import 'payment_form_screen.dart';
import 'payment_detail_screen.dart';

// ==========================================
// 1. CLIENT LIST SCREEN (Level 3)
// ==========================================
class ClientListScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final String type;

  const ClientListScreen({super.key, required this.siteId, required this.siteName, required this.type});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await CachedDataService.getDocuments(widget.siteId, widget.type, forceRefresh: true);
      if (mounted) setState(() => _isRefreshing = false);
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'receipt' ? "Sales - ${widget.siteName}" : "Contractors - ${widget.siteName}"),
        backgroundColor: widget.type == 'receipt' ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: CachedDataService.getDocuments(widget.siteId, widget.type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => const ClientSkeleton(),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No clients found."));
                }

                final filteredDocs = snapshot.data!;

                Map<String, List<Map<String, dynamic>>> groupedClients = {};
                for (var doc in filteredDocs) {
                  final content = doc['content'] ?? {};
                  String name = widget.type == 'receipt' ? (content['party_name'] ?? '') : (content['contractor_name'] ?? '');
                  if (name.toLowerCase().contains(_searchQuery)) {
                    groupedClients.putIfAbsent(name, () => []).add(doc);
                  }
                }

                if (groupedClients.isEmpty) return const Center(child: Text("No clients found."));

                return ListView(
                  children: groupedClients.entries.map((entry) {
                    final firstDoc = entry.value.first['content'];
                    double totalConsideration = double.tryParse(firstDoc['total_amount']?.toString() ?? '0') ?? 0;
                    double totalPaid = 0;
                    int actualReceiptCount = 0; // Count only actual payments
                    for (var doc in entry.value) {
                      final advance = double.tryParse(doc['content']['advance']?.toString() ?? '0') ?? 0;
                      totalPaid += advance;
                      if (advance > 0) actualReceiptCount++; // Only count non-zero payments
                    }
                    double pendingAmount = totalConsideration - totalPaid;
                    String propertyType = widget.type == 'receipt' ? (firstDoc['propertyType'] ?? 'N/A') : (firstDoc['domain'] ?? 'N/A');

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: ListTile(
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
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // --- ADDED THIS: Receipt Count Badge ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.type == 'receipt' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$actualReceiptCount Receipts", // Shows only actual payment receipts
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.type == 'receipt' ? Colors.blue : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Type: $propertyType | Paid: ₹$totalPaid | Pending: ₹$pendingAmount"),
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
      // FAB changed to "Add Buyer" logic
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.type == 'receipt' ? Colors.blue : Colors.green,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiptFormScreen(siteId: widget.siteId, siteName: widget.siteName))),
        label: const Text("Add Buyer"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}

// ==========================================
// 2. CLIENT DETAIL SCREEN (Buyer Profile)
// ==========================================
class ClientDetailScreen extends StatefulWidget {
  final String clientName;
  final List<Map<String, dynamic>> documents;
  final String siteName, siteId, type;

  const ClientDetailScreen({super.key, required this.clientName, required this.documents, required this.siteName, required this.siteId, required this.type});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filter out zero-payment cards and adjust numbering
    final paidHistory = widget.documents.where((doc) {
      final advance = double.tryParse(doc['content']['advance']?.toString() ?? '0') ?? 0;
      return advance > 0; // Only include actual payments
    }).toList();
    
    final filteredHistory = paidHistory.where((doc) => (doc['content']['sNo'] ?? '').toString().contains(_searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Buyer Profile")), // AppBar Title changed
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
                  child: ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString().padLeft(3, '0'))),
                    title: Text("Paid: ₹${content['advance']}"),
                    subtitle: Text("Date: ${content['payment_date'] ?? content['date']}"),
                    trailing: (content['advance'] != null && content['advance'] != "0" && double.tryParse(content['advance'].toString()) != 0)
                        ? IconButton(
                            icon: const Icon(Icons.download, color: Colors.blue),
                            onPressed: () => widget.type == 'receipt' ? PdfService.downloadAndSaveReceipt(content) : PdfService.downloadAndSaveAgreement(content),
                          )
                        : const SizedBox.shrink(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentDetailScreen(
                            document: doc,
                            siteId: widget.siteId,
                            siteName: widget.siteName,
                            onDelete: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // FAB changed to "Add Payment"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentFormScreen(
          siteId: widget.siteId, siteName: widget.siteName, initialData: widget.documents.first,
        ))),
        label: const Text("Add Payment"),
        icon: const Icon(Icons.add_card),
      ),
    );
  }
}