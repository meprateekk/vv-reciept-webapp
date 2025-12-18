import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ReceiptFormScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const ReceiptFormScreen({super.key, required this.siteId, required this.siteName});

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  final sNoController = TextEditingController(text: "001");
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
  final paymentTypeController = TextEditingController();
  final paymentDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  String? selectedPaymentType;
  final furtherPaymentDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    propNameController.text = widget.siteName;
  }

  @override
  void dispose() {
    sNoController.dispose();
    dateController.dispose();
    propNameController.dispose();
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    projectNameController.dispose();
    addressController.dispose();
    propertyTypeController.dispose();
    floorController.dispose();
    amountController.dispose();
    amountWordsController.dispose();
    advanceController.dispose();
    paymentTypeController.dispose();
    paymentDateController.dispose();
    furtherPaymentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (nameController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill Name and Amount")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final receiptData = {
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
        'amount_words': amountWordsController.text,
        'advance': advanceController.text,
        'payment_type': selectedPaymentType ?? '',
        'payment_date': paymentDateController.text,
        'further_payments': furtherPaymentDetailsController.text,
      };

      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': 'receipt',
        'content': receiptData,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating PDF...")));
      }

      await PdfService.downloadAndSaveReceipt(receiptData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Receipt saved and PDF downloaded successfully!"),
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
      appBar: AppBar(title: const Text("Sales Receipt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: sNoController, decoration: const InputDecoration(labelText: "S.No")),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date")),
            TextField(controller: propNameController, decoration: const InputDecoration(labelText: "Property Name")),

            const SizedBox(height: 20),
            const Text("Buyer Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Buyer Name"),
            ),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: "Mobile No"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),
            const Text("Property Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            TextField(
              controller: projectNameController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Project Name"),
            ),
            TextField(
              controller: addressController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: propertyTypeController,
              decoration: const InputDecoration(labelText: "Flat/Property Type"),
            ),
            TextField(
              controller: floorController,
              decoration: const InputDecoration(labelText: "Floor"),
            ),

            const SizedBox(height: 20),
            const Text("Payment Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Amount")),
            TextField(
              controller: amountWordsController,
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(labelText: "Amount In Words")
            ),
            TextField(controller: advanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Advance")),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Payment Type"),
              initialValue: selectedPaymentType,
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                DropdownMenuItem(value: "UPI", child: Text("UPI")),
                DropdownMenuItem(value: "Cheque", child: Text("Cheque")),
                DropdownMenuItem(value: "Bank Transfer", child: Text("Bank Transfer")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPaymentType = value;
                });
              },
            ),
            TextField(controller: paymentDateController, decoration: const InputDecoration(labelText: "Payment Date")),

            const SizedBox(height: 20),
            const Text("Further Payment Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            
            TextField(
              controller: furtherPaymentDetailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Further Payment Terms",
                hintText: "Enter payment terms, installments, or other details...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _handleGenerate,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Generate Receipt", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
