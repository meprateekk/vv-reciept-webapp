import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- 1. Import this for validations
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_generator.dart';
import '../utils/formatters.dart';

class ReceiptFormScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const ReceiptFormScreen({
    super.key,
    required this.siteId,
    required this.siteName
  });

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- CONTROLLERS ---
  final sNoController = TextEditingController(text: "001");
  final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  late TextEditingController propNameController;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final mobileController = TextEditingController();
  final propertyController = TextEditingController();
  final floorController = TextEditingController();

  final amountController = TextEditingController();
  final amountWordsController = TextEditingController();
  final advanceController = TextEditingController();
  final advanceWordsController = TextEditingController();
  final refNoController = TextEditingController();
  final furtherPaymentController = TextEditingController();

  String? _selectedPaymentType;
  final List<String> _paymentOptions = ['Cheque', 'Cash', 'UPI', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    propNameController = TextEditingController(text: widget.siteName);
  }

  @override
  void dispose() {
    // Dispose all controllers to free memory
    nameController.dispose(); addressController.dispose(); mobileController.dispose();
    propertyController.dispose(); floorController.dispose(); amountController.dispose();
    amountWordsController.dispose(); advanceController.dispose(); advanceWordsController.dispose();
    refNoController.dispose(); furtherPaymentController.dispose();
    sNoController.dispose(); dateController.dispose(); propNameController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (nameController.text.isEmpty || amountController.text.isEmpty || _selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill Name, Amount and Payment Type")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prepare Data
      final receiptData = {
        'sNo': sNoController.text,
        'date': dateController.text,
        'propertyName': propNameController.text,
        'party_name': nameController.text,
        'buyer_address': addressController.text,
        'buyer_mob': mobileController.text,
        'flat_property': propertyController.text,
        'floor': floorController.text,
        'amount': amountController.text,
        'amount_words': amountWordsController.text,
        'advance': advanceController.text,
        'advance_words': advanceWordsController.text,
        'payment_type': _selectedPaymentType,
        'reference_no': refNoController.text,
        'further_payments': furtherPaymentController.text,
      };

      // 2. Save to Supabase
      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': 'receipt',
        'content': receiptData,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Generate PDF
      await PdfGenerator.generateReceipt(
        sNoController.text,
        dateController.text,
        propNameController.text,
        nameController.text,
        addressController.text,
        mobileController.text,
        propertyController.text,
        floorController.text,
        amountController.text,
        amountWordsController.text,
        advanceController.text,
        advanceWordsController.text,
        _selectedPaymentType!,
        refNoController.text,
        furtherPaymentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved & Generated Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Receipt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Office Use Only"),
            Row(
              children: [
                Expanded(child: TextField(controller: sNoController, decoration: const InputDecoration(labelText: "S.No"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date"))),
              ],
            ),
            TextField(controller: propNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Property Name")),


            const SizedBox(height: 20),
            _buildSectionTitle("Buyer Details"),

            // --- TEACHING MOMENT: Validations Added Here ---
            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Buyer Name"),
            ),

            TextField(
              controller: addressController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Buyer Address"),
            ),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Only Numbers Allowed
                LengthLimitingTextInputFormatter(10),   // Max 10 digits
              ],
              decoration: const InputDecoration(labelText: "Buyer Mobile"),
            ),

            Row(
              children: [
                Expanded(child: TextField(controller: propertyController, decoration: const InputDecoration(labelText: "Flat No"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: floorController, decoration: const InputDecoration(labelText: "Floor"))),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Payment Details"),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Total Amount (Numbers)"),
            ),

            TextField(
              controller: amountWordsController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Total Amount (In Words)"),
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: advanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: "Advance (Numbers)"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: advanceWordsController,
                    inputFormatters: [CapitalizeWordsFormatter()],
                    decoration: const InputDecoration(labelText: "Advance (In Words)"),
                  ),
                ),
              ],
            ),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Payment Type"),
              value: _selectedPaymentType,
              items: _paymentOptions.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedPaymentType = val),
            ),

            TextField(
              controller: refNoController,
              textCapitalization: TextCapitalization.characters, // All Caps for IDs
              decoration: const InputDecoration(labelText: "Cheque / UPI Ref No"),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Terms & Conditions"), // <--- NEW SECTION YOU ASKED FOR

            TextField(
              controller: furtherPaymentController,
              maxLines: 4, // Makes it a bigger box
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(
                labelText: "Further Payment Terms / Notes",
                border: OutlineInputBorder(), // Adds a box border
                hintText: "Enter payment schedule or terms here...",
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _handleGenerate,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Generate PDF", style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper to make titles look consistent
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
        const Divider(thickness: 1.5),
        const SizedBox(height: 10),
      ],
    );
  }
}