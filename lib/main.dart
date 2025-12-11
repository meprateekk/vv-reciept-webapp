import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'pdf_generator.dart'; // Ensure pdf_generator.dart is in the same folder

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace with your actual Supabase Keys
  await Supabase.initialize(
    url: 'https://tzqeqnmjcpvvkfbjwtyj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6cWVxbm1qY3B2dmtmYmp3dHlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzUxODIsImV4cCI6MjA4MDYxMTE4Mn0.AKR-VQKUOy6Is37ddIchYQ1CJFiOhGlVgklXd5OEHxM',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF001F3F), // Navy Blue
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF001F3F)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF001F3F),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

// --- DASHBOARD (Tabs) ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [CreateReceiptScreen(), HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF001F3F),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "New Receipt"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}

// --- TAB 1: CREATE RECEIPT ---
class CreateReceiptScreen extends StatefulWidget {
  @override
  _CreateReceiptScreenState createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  // Controllers
  final _receiptNo = TextEditingController(text: "1001");
  final _project = TextEditingController();
  final _buyerName = TextEditingController();
  final _phone = TextEditingController();
  final _flatNo = TextEditingController();
  final _type = TextEditingController();
  final _totalAmount = TextEditingController();
  final _paidAmount = TextEditingController();

  String _paymentMode = "Cheque";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("New Receipt", style: TextStyle(color: Colors.white))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Section 1: Receipt Details
            _buildSectionHeader("Receipt Details"),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _buildTextField(_receiptNo, "Receipt No", Icons.numbers)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField(_project, "Project Name", Icons.business)),
                  ]),
                ]),
              ),
            ),

            // Section 2: Buyer Details
            SizedBox(height: 10),
            _buildSectionHeader("Buyer Details"),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  _buildTextField(_buyerName, "Buyer Name", Icons.person),
                  SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildTextField(_phone, "Phone", Icons.phone)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField(_flatNo, "Flat No", Icons.home)),
                  ]),
                  SizedBox(height: 10),
                  _buildTextField(_type, "Flat Type (e.g. 2BHK)", Icons.layers),
                ]),
              ),
            ),

            // Section 3: Payment
            SizedBox(height: 10),
            _buildSectionHeader("Payment Info"),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  _buildTextField(_totalAmount, "Total Consideration (₹)", Icons.currency_rupee),
                  SizedBox(height: 10),
                  _buildTextField(_paidAmount, "Amount Received (₹)", Icons.attach_money),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Payment Mode",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    value: _paymentMode,
                    items: ["Cheque", "Cash", "NEFT", "UPI"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _paymentMode = val!),
                  ),
                ]),
              ),
            ),

            SizedBox(height: 30),

            // SAVE BUTTON
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                icon: _isLoading ? Container(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : Icon(Icons.save),
                label: Text(_isLoading ? "SAVING..." : "SAVE & DOWNLOAD PDF", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _isLoading ? null : _handleSaveAndPrint,
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveAndPrint() async {
    setState(() => _isLoading = true);

    // Calculations
    double total = double.tryParse(_totalAmount.text) ?? 0;
    double paid = double.tryParse(_paidAmount.text) ?? 0;
    double balance = total - paid;

    final data = ReceiptData(
      receiptNo: _receiptNo.text,
      date: DateTime.now().toString().split(' ')[0],
      projectName: _project.text,
      projectAddress: "Gwalior, MP",
      buyerName: _buyerName.text,
      address: "Gwalior, MP",
      phone: _phone.text,
      panNo: "NA",
      flatNo: _flatNo.text,
      floor: "NA",
      type: _type.text,
      superArea: "NA",
      totalConsideration: _totalAmount.text,
      amountReceived: _paidAmount.text,
      amountInWords: "Rupees ... Only",
      paymentTowards: "Booking",
      paymentMode: _paymentMode,
      balanceAmount: balance.toString(),
    );

    try {
      // 1. Save to Supabase
      await Supabase.instance.client.from('receipts').insert({
        'receipt_no': data.receiptNo,
        'buyer_name': data.buyerName,
        'details': data.toMap(), // Store full JSON
      });

      // 2. Generate PDF
      await PdfGenerator.generate(data);

      // 3. Clear Form (Optional)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved Successfully!")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helpers
  Widget _buildSectionHeader(String title) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title.toUpperCase(), style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold))));

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) => TextField(controller: ctrl, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Color(0xFF001F3F)), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15)));
}

// --- TAB 2: HISTORY SCREEN ---
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Search Query Store karne ke liye
  String _searchQuery = "";

  // Supabase Stream (Saara data layega, filter hum phone pe karenge for speed)
  final _stream = Supabase.instance.client
      .from('receipts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History", style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Name or Receipt No...",
                prefixIcon: Icon(Icons.search, color: Color(0xFF001F3F)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              onChanged: (val) {
                // Jaise hi user type kare, state update karo
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          // --- LIST ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return Center(child: Text("No receipts found"));

                final receipts = snapshot.data!;

                // --- FILTER LOGIC ---
                // Agar search bar khali hai to sab dikhao, nahi to filter karo
                final filteredList = receipts.where((item) {
                  final name = item['buyer_name'].toString().toLowerCase();
                  final receiptNo = item['receipt_no'].toString().toLowerCase();
                  return name.contains(_searchQuery) || receiptNo.contains(_searchQuery);
                }).toList();

                if (filteredList.isEmpty)
                  return Center(child: Text("No result found for '$_searchQuery'"));

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final details = item['details']; // JSON Data

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF001F3F),
                          child: Text(
                              item['buyer_name'].toString().isNotEmpty
                                  ? item['buyer_name'][0].toUpperCase()
                                  : "?",
                              style: TextStyle(color: Colors.white)
                          ),
                        ),
                        title: Text(item['buyer_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Receipt: ${item['receipt_no']}\nDate: ${details['date']}", style: TextStyle(height: 1.5)),
                        trailing: IconButton(
                          icon: Icon(Icons.download_rounded, color: Color(0xFF001F3F), size: 28),
                          onPressed: () {
                            // Re-generate PDF
                            final receiptData = ReceiptData.fromMap(details);
                            PdfGenerator.generate(receiptData);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}