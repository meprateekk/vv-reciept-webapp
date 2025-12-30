import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site_model.dart';
import '../utils/formatters.dart';
import 'site_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGOUT WITH CONFIRMATION ---
  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- DELETE WITH CONFIRMATION ---
  Future<void> _confirmDelete(String siteId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _supabase.from('sites').delete().eq('id', siteId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site deleted successfully')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- ADD OR EDIT SITE DIALOG ---
  void _showSiteDialog({Site? site}) {
    // Controller names unified to addressController
    final nameController = TextEditingController(text: site != null ? site.name : '');
    final addressController = TextEditingController(text: site != null ? site.location : '');
    final isEditMode = site != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditMode ? 'Edit Site' : 'Add New Site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              inputFormatters: [CapitalizeWordsFormatter()], // Strict Capitalization
              decoration: const InputDecoration(hintText: 'Site Name', labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              inputFormatters: [CapitalizeWordsFormatter()], // Maintain capitalization for Address
              decoration: const InputDecoration(
                labelText: "Address", // Location renamed to Address
                hintText: "Enter Site Address",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final address = addressController.text.trim(); // Fixed: Using addressController
              final userId = _supabase.auth.currentUser!.id;

              if (name.isNotEmpty && address.isNotEmpty) {
                if (isEditMode) {
                  await _supabase.from('sites').update({
                    'name': name,
                    'location': address, // Database column remains 'location'
                  }).eq('id', site.id);
                } else {
                  await _supabase.from('sites').insert({
                    'name': name,
                    'location': address,
                    'user_id': userId,
                  });
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditMode ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
          IconButton(onPressed: _confirmLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sites...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('sites').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data!;
                final filteredData = data.where((siteData) {
                  final siteName = siteData['name'].toString().toLowerCase();
                  return siteName.contains(_searchQuery);
                }).toList();

                if (filteredData.isEmpty) return const Center(child: Text("No sites found."));

                return ListView.builder(
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final site = Site.fromJson(filteredData[index]);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.apartment, color: Colors.white),
                        ),
                        title: Text(site.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(site.location), // Displaying address as subtitle
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSiteDialog(site: site),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(site.id),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiteDetailScreen(siteId: site.id, siteName: site.name),
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSiteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}