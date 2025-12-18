import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart'; // CHANGED: New Service Import
import '../utils/formatters.dart';

class ContractFormScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const ContractFormScreen({super.key, required this.siteId, required this.siteName});

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  final sNoController = TextEditingController(text: "001");
  final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  late TextEditingController propNameController;

  final nameController = TextEditingController();
  final domainController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final rateController = TextEditingController();
  final totalAmountController = TextEditingController();
  final amountWordsController = TextEditingController();
  final termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    propNameController = TextEditingController(text: widget.siteName);
  }

  @override
  void dispose() {
    sNoController.dispose();
    dateController.dispose();
    propNameController.dispose();
    nameController.dispose();
    domainController.dispose();
    mobileController.dispose();
    addressController.dispose();
    rateController.dispose();
    totalAmountController.dispose();
    amountWordsController.dispose();
    termsController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (nameController.text.isEmpty || totalAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill Name and Amount")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Data map create kiya
      final contractData = {
        'sNo': sNoController.text,
        'date': dateController.text,
        'propertyName': propNameController.text,
        'contractor_name': nameController.text,
        'domain': domainController.text,
        'mobile': mobileController.text,
        'address': addressController.text,
        'rate': rateController.text,
        'total_amount': totalAmountController.text,
        'amount_words': amountWordsController.text,
        'terms': termsController.text,
      };

      // 1. Supabase me save kiya
      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': 'agreement',
        'content': contractData,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. CHANGED: PDF Download Logic using PdfService
      await PdfService.downloadAndSaveAgreement(contractData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agreement Saved & Downloading...")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Tera UI code same rahega, usme koi change nahi) ...
    // Bas _handleGenerate update ho gaya hai upar wala.
    return Scaffold(
      appBar: AppBar(title: const Text("Contractor Agreement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: sNoController, decoration: const InputDecoration(labelText: "S.No")),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date")),
            TextField(controller: propNameController, decoration: const InputDecoration(labelText: "Property Name")),

            const SizedBox(height: 20),
            const Text("Contractor Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Contractor Name"),
            ),
            TextField(
              controller: domainController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Sector / Domain (e.g. Electrician)"),
            ),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: "Mobile No"),
            ),
            TextField(
              controller: addressController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Address"),
            ),

            const SizedBox(height: 20),
            const Text("Payment & Terms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Agreed Rate")),
            TextField(controller: totalAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Amount")),

            TextField(
                controller: amountWordsController,
                inputFormatters: [CapitalizeWordsFormatter()],
                decoration: const InputDecoration(labelText: "Amount In Words")
            ),

            const SizedBox(height: 10),
            TextField(
              controller: termsController,
              maxLines: 5,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(
                labelText: "Agreement Terms",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _handleGenerate,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Generate Agreement", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}