import 'package:flutter/material.dart';
import 'receipt_form_screen.dart';
import 'contract_form.dart';

class DocumentSelectionDialog extends StatelessWidget {
  final String siteId;
  final String siteName;

  const DocumentSelectionDialog({
    super.key,
    required this.siteId,
    required this.siteName
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title ---
            const Text(
              "Select Document",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Choose a document type to generate or view:",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // --- Option 1: Sales Receipt ---
            _buildOptionTile(
              context,
              icon: Icons.receipt_long,
              color: Colors.blueAccent,
              title: "Sales Receipt",
              subtitle: "Generate payment receipt PDF",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiptFormScreen(
                      siteId: siteId,
                      siteName: siteName,
                    ),
                  ),
                );
              },
            ), // <--- THIS WAS MISSING (Closing parenthesis and comma)

            const SizedBox(height: 10),

            // --- Option 2: Contract Agreement ---
            _buildOptionTile(
              context,
              icon: Icons.handshake,
              color: Colors.orangeAccent,
              title: "Contract Agreement",
              subtitle: "Draft builder-buyer agreement",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContractFormScreen( // <--- NAVIGATE TO NEW SCREEN
                      siteId: siteId,
                      siteName: siteName,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(),

            // --- Add New Button ---
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Add New Document feature clicked")),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Add New Document", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Cancel Button ---
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget
  Widget _buildOptionTile(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}