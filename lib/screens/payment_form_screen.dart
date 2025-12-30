import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';

class PaymentFormScreen extends StatefulWidget {
  final String siteId, siteName;
  final Map<String, dynamic> initialData; // Passes the first buyer/property doc

  const PaymentFormScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.initialData,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _supabase = Supabase.instance.client;
  final amountController = TextEditingController();
  final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  String? selectedType;
  bool _isLoading = false;

  Future<void> _handleSave() async {
    final buyerContent = widget.initialData['content'];
    double totalLimit = double.tryParse(buyerContent['total_amount']?.toString() ?? '0') ?? 0;
    double currentInput = double.tryParse(amountController.text) ?? 0;

    if (currentInput <= 0) return;

    setState(() => _isLoading = true);

    try {
      // 1. Fetch history to check total paid
      final res = await _supabase
          .from('documents')
          .select('content')
          .eq('site_id', widget.siteId)
          .filter('content->>party_name', 'eq', buyerContent['party_name']);

      double alreadyPaid = 0;
      for (var doc in res) {
        alreadyPaid += double.tryParse(doc['content']['advance']?.toString() ?? '0') ?? 0;
      }

      // 2. Logic: Amount can't be more than total amount
      if ((alreadyPaid + currentInput) > totalLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Total paid exceeds Total Amount!"), backgroundColor: Colors.red),
        );
        return;
      }

      // 3. Prepare Data for new Receipt
      final newData = Map<String, dynamic>.from(buyerContent);
      newData['advance'] = amountController.text;
      newData['payment_date'] = dateController.text;
      newData['payment_type'] = selectedType ?? "Cash";
      newData['sNo'] = (res.length + 1).toString().padLeft(3, '0');

      // 4. Save to Supabase
      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': 'receipt',
        'content': newData,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5. Generate PDF
      await PdfService.downloadAndSaveReceipt(newData);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Installment Amount"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Date", suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => dateController.text = picked.toString().substring(0, 10));
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: "Payment Type"),
              items: ["UPI", "Cash", "Bank Transfer", "Cheque"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedType = v),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Save & Generate PDF"),
              ),
            )
          ],
        ),
      ),
    );
  }
}