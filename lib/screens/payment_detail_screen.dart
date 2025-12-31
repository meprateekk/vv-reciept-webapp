import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import 'receipt_form_screen.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> document;
  final String siteId, siteName;
  final Function? onDelete;

  const PaymentDetailScreen({
    super.key,
    required this.document,
    required this.siteId,
    required this.siteName,
    this.onDelete,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _deletePayment() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _supabase.from('documents').delete().eq('id', widget.document['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment deleted successfully'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                  widget.onDelete?.call();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editPayment() {
    final content = widget.document['content'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptFormScreen(
          siteId: widget.siteId,
          siteName: widget.siteName,
          initialData: widget.document,
          isEdit: true,
        ),
      ),
    );
  }

  void _downloadPdf() {
    final content = widget.document['content'];
    PdfService.downloadAndSaveReceipt(content);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.document['content'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Details"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Payment Summary",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Serial No.", content['sNo'] ?? ''),
                    _buildDetailRow("Payment Amount", "₹${content['advance'] ?? '0'}"),
                    _buildDetailRow("Payment Date", content['payment_date'] ?? content['date'] ?? ''),
                    _buildDetailRow("Payment Type", content['payment_type'] ?? 'Cash'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow("Total Consideration", "₹${content['total_amount'] ?? '0'}"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Buyer Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Buyer Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Name", content['party_name'] ?? ''),
                    _buildDetailRow("Mobile", content['mobile'] ?? ''),
                    _buildDetailRow("Email", content['email'] ?? ''),
                    _buildDetailRow("Address", content['address'] ?? ''),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Property Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Property Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Project Name", content['propertyName'] ?? ''),
                    _buildDetailRow("Property Type", content['propertyType'] ?? ''),
                    _buildDetailRow("Floor", content['floor'] ?? ''),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download),
                    label: const Text("Download PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _editPayment,
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deletePayment,
                icon: const Icon(Icons.delete),
                label: const Text("Delete Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
