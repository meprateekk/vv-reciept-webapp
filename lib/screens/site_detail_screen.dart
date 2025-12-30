import 'package:flutter/material.dart';
import 'client_detail_screen.dart'; // Isme ab ClientListScreen maujood hai
import 'document_selection_dialog.dart';

class SiteDetailScreen extends StatelessWidget {
  final String siteId;
  final String siteName;

  const SiteDetailScreen({super.key, required this.siteId, required this.siteName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(siteName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. SALES RECEIPTS CARD ---
            _buildCategoryCard(
              context,
              title: "Sales Receipts",
              icon: Icons.receipt_long,
              color: Colors.blue,
              type: 'receipt',
            ),

            const SizedBox(height: 20),

            // --- 2. CONTRACTOR AGREEMENTS CARD ---
            _buildCategoryCard(
              context,
              title: "Contractor Agreements",
              icon: Icons.handshake,
              color: Colors.green,
              type: 'agreement',
            ),
          ],
        ),
      ),
      // Floating button wahi rahega jo dono forms dikhata hai
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => DocumentSelectionDialog(siteId: siteId, siteName: siteName),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper Widget for Dashboard Cards
  Widget _buildCategoryCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String type
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Navigating to ClientListScreen (Level 3 of your sketch)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientListScreen(
                siteId: siteId,
                siteName: siteName,
                type: type,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)
              ),
            ],
          ),
        ),
      ),
    );
  }
}