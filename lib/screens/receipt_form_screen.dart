import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ReceiptFormScreen extends StatefulWidget {
  final String siteId, siteName;
  final Map<String, dynamic>? initialData;
  final bool isEdit, isNewPayment;

  const ReceiptFormScreen({super.key, required this.siteId, required this.siteName, this.initialData, this.isEdit = false, this.isNewPayment = false});

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  final sNoController = TextEditingController();
  final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final propNameController = TextEditingController();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final projectNameController = TextEditingController();
  final addressController = TextEditingController();
  final propertyTypeController = TextEditingController();
  final floorController = TextEditingController();
  final amountController = TextEditingController();
  final amountWordsController = TextEditingController();
  final advanceController = TextEditingController();
  final paymentDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final furtherPaymentDetailsController = TextEditingController();
  String? selectedPaymentType;

  @override
  void initState() {
    super.initState();
    propNameController.text = widget.siteName;

    if (widget.initialData != null) {
      final content = widget.initialData!['content'];
      nameController.text = content['party_name'] ?? '';
      mobileController.text = content['mobile'] ?? '';
      emailController.text = content['email'] ?? '';
      projectNameController.text = content['projectName'] ?? '';
      addressController.text = content['address'] ?? '';
      propertyTypeController.text = content['propertyType'] ?? '';
      floorController.text = content['floor'] ?? '';
      amountController.text = content['total_amount'] ?? '';
      amountWordsController.text = content['amount_words'] ?? '';
      furtherPaymentDetailsController.text = content['further_payments'] ?? '';
      selectedPaymentType = content['payment_type'];

      if (widget.isEdit) {
        sNoController.text = content['sNo'] ?? '';
        advanceController.text = content['advance'] ?? '';
        dateController.text = content['date'] ?? '';
        paymentDateController.text = content['payment_date'] ?? '';
      } else if (widget.isNewPayment) {
        _fetchNextSerialNumber(nameController.text);
      }
    } else {
      sNoController.text = "001";
    }
  }

  Future<void> _fetchNextSerialNumber(String clientName) async {
    if (clientName.trim().isEmpty) return;
    final response = await _supabase.from('documents').select('id').eq('site_id', widget.siteId).eq('type', 'receipt').filter('content->>party_name', 'eq', clientName.trim());
    setState(() => sNoController.text = (response.length + 1).toString().padLeft(3, '0'));
  }

  Future<void> _handleGenerate() async {
    double total = double.tryParse(amountController.text) ?? 0;
    double current = double.tryParse(advanceController.text) ?? 0;

    if (current > total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Advance exceeds Total Amount!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final history = await _supabase.from('documents').select('id, content').eq('site_id', widget.siteId).filter('content->>party_name', 'eq', nameController.text.trim());
      double alreadyPaid = 0;
      for (var doc in history) {
        if (widget.isEdit && doc['id'] == widget.initialData!['id']) continue;
        alreadyPaid += double.tryParse(doc['content']['advance']?.toString() ?? '0') ?? 0;
      }

      if ((alreadyPaid + current) > total) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Total Paid (₹${alreadyPaid + current}) exceeds limit (₹$total)!"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
        return;
      }

      final data = {
        'sNo': sNoController.text,
        'date': dateController.text,
        'propertyName': propNameController.text,
        'party_name': nameController.text,
        'mobile': mobileController.text,
        'email': emailController.text,
        'projectName': projectNameController.text,
        'address': addressController.text,
        'propertyType': propertyTypeController.text,
        'floor': floorController.text,
        'total_amount': amountController.text,
        'amount_words': amountWordsController.text.toUpperCase(),
        'advance': advanceController.text,
        'payment_type': selectedPaymentType ?? 'Cash',
        'payment_date': paymentDateController.text,
        'further_payments': furtherPaymentDetailsController.text,
      };

      if (widget.isEdit) {
        await _supabase.from('documents').update({'content': data}).eq('id', widget.initialData!['id']);
      } else {
        await _supabase.from('documents').insert({'site_id': widget.siteId, 'type': 'receipt', 'content': data, 'created_at': DateTime.now().toIso8601String()});
      }

      String cleanName = nameController.text.replaceAll(' ', '').toLowerCase();
      String formattedFileName = "${sNoController.text}_${cleanName}_${propertyTypeController.text.toLowerCase()}";
      final pdfData = Map<String, dynamic>.from(data);
      pdfData['party_name'] = formattedFileName;
      await PdfService.downloadAndSaveReceipt(pdfData);

      if (mounted) Navigator.pop(context);
    } catch (e) { print(e); } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? "Edit Sales Receipt" : "Sales Receipt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: sNoController, decoration: const InputDecoration(labelText: "S.No"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date"))),
            ]),
            TextField(controller: propNameController, decoration: const InputDecoration(labelText: "Property Name")),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Buyer Details", style: TextStyle(fontWeight: FontWeight.bold))),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Buyer Name"), inputFormatters: [CapitalizeWordsFormatter()], onChanged: (v) => widget.isEdit ? null : _fetchNextSerialNumber(v)),
            TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile No")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Property Details", style: TextStyle(fontWeight: FontWeight.bold))),
            TextField(controller: projectNameController, decoration: const InputDecoration(labelText: "Project Name"), inputFormatters: [CapitalizeWordsFormatter()]),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address"), inputFormatters: [CapitalizeWordsFormatter()]),
            Row(children: [
              Expanded(child: TextField(controller: propertyTypeController, decoration: const InputDecoration(labelText: "Property Type"))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: floorController, decoration: const InputDecoration(labelText: "Floor"))),
            ]),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Payment Details", style: TextStyle(fontWeight: FontWeight.bold))),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Consideration Amount")),
            TextField(controller: amountWordsController, decoration: const InputDecoration(labelText: "Amount In Words"), inputFormatters: [CapitalizeWordsFormatter()]),
            TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Advance (Current Payment)")),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Payment Type"),
              value: selectedPaymentType,
              items: ["Cash", "UPI", "Cheque", "Bank Transfer"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => selectedPaymentType = v),
            ),
            TextField(controller: paymentDateController, decoration: const InputDecoration(labelText: "Payment Date")),
            const SizedBox(height: 20),
            TextField(controller: furtherPaymentDetailsController, maxLines: 3, decoration: const InputDecoration(labelText: "Further Payment Terms", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _handleGenerate,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.isEdit ? "Update & Download" : "Generate & Save"),
            )),
          ],
        ),
      ),
    );
  }
}