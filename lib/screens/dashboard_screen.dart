import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Formatter ke liye zaroori hai
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
  final TextEditingController _searchController = TextEditingController(); // Search ke liye controller
  String _searchQuery = ""; // Search text store karne ke liye

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
    final nameController = TextEditingController(text: site != null ? site.name : '');
    final locationController = TextEditingController(text: site != null ? site.location : '');
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
              // Laptop ke liye ye formatter zaroori hai
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(hintText: 'Site Name', labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationController,
              // Location me bhi first letter capital hoga
              inputFormatters: [CapitalizeWordsFormatter()],
              decoration: const InputDecoration(hintText: 'Location', labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final location = locationController.text.trim();
              final userId = _supabase.auth.currentUser!.id;

              if (name.isNotEmpty && location.isNotEmpty) {
                if (isEditMode) {
                  await _supabase.from('sites').update({
                    'name': name,
                    'location': location,
                  }).eq('id', site.id);
                } else {
                  await _supabase.from('sites').insert({
                    'name': name,
                    'location': location,
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
          // --- REFRESH BUTTON ADDED HERE ---
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // setState call karne se UI rebuild hoga aur Stream dobara connect ho sakti hai
              setState(() {});
            },
          ),
          IconButton(onPressed: _confirmLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      // Column use kiya taaki Search Bar upar fix rahe aur list scroll kare
      body: Column(
        children: [
          // --- SEARCH BAR ADDED HERE ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sites...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // Jaise hi type karoge, UI update hoga
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // --- SITE LIST ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('sites').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data!;

                // --- FILTERING LOGIC ---
                // Data aane ke baad search query se filter kar rahe hain
                final filteredData = data.where((siteData) {
                  final siteName = siteData['name'].toString().toLowerCase();
                  return siteName.contains(_searchQuery);
                }).toList();

                if (filteredData.isEmpty) {
                  return const Center(child: Text("No sites found."));
                }

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
                        subtitle: Text(site.location),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SiteDetailScreen(
                                siteId: site.id,
                                siteName: site.name,
                              ),
                            ),
                          );
                        },
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