import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateDocumentScreen extends StatefulWidget {
  final String siteId;
  final String type; // 'receipt' or 'agreement'

  const CreateDocumentScreen({
    super.key,
    required this.siteId,
    required this.type
  });

  @override
  State<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends State<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers for Form Fields
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Date Picker Logic
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- SAVE DATA TO SUPABASE ---
  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Prepare JSON Data (Scalable Logic)
    // Hum alag columns nahi bana rahe, sab JSON me daal rahe hain.
    // Isse kal ko agar naya field aaya to database change nahi karna padega.
    final contentData = {
      'party_name': _nameController.text.trim(),
      'date': _selectedDate.toIso8601String(),
      'description': _descriptionController.text.trim(),
      // Sirf receipt ke liye amount save karenge
      if (widget.type == 'receipt') 'amount': _amountController.text.trim(),
    };

    try {
      await _supabase.from('documents').insert({
        'site_id': widget.siteId,
        'type': widget.type,
        'content': contentData, // Saving as JSON
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document Saved!')));
        Navigator.pop(context); // Go back to Site Detail
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = widget.type == 'receipt';

    return Scaffold(
      appBar: AppBar(
        title: Text(isReceipt ? "New Sales Receipt" : "New Agreement"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Common Field: Party Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Party Name (Client/Contractor)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // 2. Common Field: Date
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 3. Receipt Specific: Amount
              if (isReceipt) ...[
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 15),
              ],

              // 4. Common Field: Description / Terms
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isReceipt ? "Item Details" : "Agreement Terms",
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),

              // 5. Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Document", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}