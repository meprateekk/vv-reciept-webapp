import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ReceiptFormScreen extends StatefulWidget {
  final String siteId, siteName;
  final Map<String, dynamic>? initialData;
  final bool isEdit, isNewPayment;

  const ReceiptFormScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.initialData,
    this.isEdit = false,
    this.isNewPayment = false
  });

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers
  final sNoController = TextEditingController();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final propertyTypeController = TextEditingController();
  final floorController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill logic if editing or adding payment
    if (widget.initialData != null) {
      final content = widget.initialData!['content'];
      nameController.text = content['party_name'] ?? '';
      mobileController.text = content['mobile'] ?? '';
      emailController.text = content['email'] ?? '';
      addressController.text = content['address'] ?? '';
      propertyTypeController.text = content['propertyType'] ?? '';
      floorController.text = content['floor'] ?? '';
      amountController.text = content['total_amount'] ?? '';

      if (widget.isEdit) {
        sNoController.text = content['sNo'] ?? '';
      } else {
        _fetchNextSNo(nameController.text);
      }
    } else {
      sNoController.text = "001";
    }
  }

  // Auto-increment S.No based on existing receipts for this buyer
  Future<void> _fetchNextSNo(String name) async {
    if (name.trim().isEmpty) return;
    final res = await _supabase
        .from('documents')
        .select('id')
        .eq('site_id', widget.siteId)
        .eq('type', 'receipt')
        .filter('content->>party_name', 'eq', name.trim());
    setState(() => sNoController.text = (res.length + 1).toString().padLeft(3, '0'));
  }

  // --- THE MISSING SAVE LOGIC ---
  Future<void> _handleSave() async {
    if (nameController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Name and Total Amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'sNo': sNoController.text,
        'date': DateTime.now().toString().substring(0, 10),
        'propertyName': widget.siteName,
        'party_name': nameController.text, // Formatter handles capitalization
        'mobile': mobileController.text,
        'email': emailController.text,
        'address': addressController.text,
        'propertyType': propertyTypeController.text.toUpperCase(), // Strict UPPERCASE
        'floor': floorController.text,
        'total_amount': amountController.text,
        'advance': "0", // Initial entry, payments added via "Add Payment"
      };

      if (widget.isEdit) {
        await _supabase
            .from('documents')
            .update({'content': data})
            .eq('id', widget.initialData!['id']);
      } else {
        await _supabase.from('documents').insert({
          'site_id': widget.siteId,
          'type': 'receipt',
          'content': data,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Generate PDF immediately after save
      final pdfData = Map<String, dynamic>.from(data);
      pdfData['party_name'] = "${sNoController.text}_${nameController.text.replaceAll(' ', '').toLowerCase()}";
      await PdfService.downloadAndSaveReceipt(pdfData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Buyer details saved and PDF downloaded!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? "Edit Buyer" : "Add New Buyer")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Buyer Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()], // Strict Capitalization
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (v) => widget.isEdit ? null : _fetchNextSNo(v),
            ),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.number, // Number only
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(
                controller: addressController,
                inputFormatters: [CapitalizeWordsFormatter()], // Strict Capitalization
                decoration: const InputDecoration(labelText: "Address")
            ),

            const SizedBox(height: 30),
            const Text("Property Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            TextField(
              controller: propertyTypeController,
              onChanged: (v) {
                // Force Uppercase in real-time
                propertyTypeController.value = propertyTypeController.value.copyWith(
                  text: v.toUpperCase(),
                  selection: TextSelection.collapsed(offset: v.length),
                );
              },
              decoration: const InputDecoration(labelText: "Type (e.g. 2BHK)"),
            ),
            TextField(controller: floorController, decoration: const InputDecoration(labelText: "Floor")),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Consideration Amount"),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: _handleSave,
                    child: const Text("Save")
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))),
              ],
            )
          ],
        ),
      ),
    );
  }
}