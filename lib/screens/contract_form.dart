import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
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

  // Controllers
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

  // --- 1. AUTO SERIAL NUMBER LOGIC ---
  // Contractor ke naam ke basis pe agla number fetch karega
  Future<void> _fetchNextSerialNumber(String contractorName) async {
    if (contractorName.trim().isEmpty) return;

    try {
      final response = await _supabase
          .from('documents')
          .select('content')
          .eq('site_id', widget.siteId)
          .eq('type', 'agreement')
          .filter('content->>contractor_name', 'eq', contractorName.trim());

      int nextNumber = (response as List).length + 1;
      setState(() {
        sNoController.text = nextNumber.toString().padLeft(3, '0');
      });
    } catch (e) {
      debugPrint("Error fetching serial number: $e");
    }
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

  // --- 2. GENERATE & SAVE LOGIC ---
  Future<void> _handleGenerate() async {
    if (nameController.text.isEmpty || totalAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Contractor Name and Amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Naming Convention: 001_name_domain (e.g. 001_rohitkumar_electrician)
      String cleanName = nameController.text.replaceAll(' ', '').toLowerCase();
      String cleanDomain = domainController.text.replaceAll(' ', '').toLowerCase();
      if (cleanDomain.isEmpty) cleanDomain = "contractor";

      String formattedFileName = "${sNoController.text}_${cleanName}_$cleanDomain";

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
        'amount_words': amountWordsController.text.toUpperCase(),
        'terms': termsController.text,
        'fileName': formattedFileName,
      };

      // 1. Supabase mein save karein
      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': 'agreement',
        'content': contractData,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Agreement PDF...")));
      }

      // 2. PDF Download (File naming format ke saath)
      final pdfData = Map<String, dynamic>.from(contractData);
      pdfData['contractor_name'] = formattedFileName;

      await PdfService.downloadAndSaveAgreement(pdfData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Agreement saved and PDF downloaded successfully!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contractor Agreement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row for S.No and Date
            Row(
              children: [
                Expanded(child: TextField(controller: sNoController, decoration: const InputDecoration(labelText: "S.No (Auto)"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date"))),
              ],
            ),
            TextField(controller: propNameController, decoration: const InputDecoration(labelText: "Property Name")),

            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Contractor Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Divider(),

            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Contractor Name", hintText: "Enter name to update Serial No."),
              onChanged: (value) => _fetchNextSerialNumber(value),
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
            TextField(controller: addressController, inputFormatters: [CapitalizeWordsFormatter()], decoration: const InputDecoration(labelText: "Address")),

            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Payment & Terms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Divider(),

            TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Agreed Rate")),
            TextField(controller: totalAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Amount")),
            TextField(controller: amountWordsController, inputFormatters: [CapitalizeWordsFormatter()], decoration: const InputDecoration(labelText: "Amount In Words")),

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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Generate & Save Agreement", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}