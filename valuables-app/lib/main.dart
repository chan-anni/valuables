import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_page.dart';
import 'package:valuables/screens/lost_item_form.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
    ), 
    home: const Navigation(),
    );
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

  void setPageIndex(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  late final List<Widget> pages = [
    HomePage(onBrowsePressed: () => setPageIndex(1)),
    const MapPage(),
    const MessagePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Valuables', style: TextStyle(color: Colors.white)),
      ),

      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
        ],
        onDestinationSelected: (int index) {
          setPageIndex(index);
        },
        selectedIndex: currentPageIndex,
      ),
      body: pages[currentPageIndex],
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _supabase.auth.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          bottom: TabBar(
            tabs: [
              Tab(text: _isLoggedIn ? 'Account Info' : 'Sign In'),
              const Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _isLoggedIn ? const _AccountInfoTab() : const _LoginSignUpTab(),
            const _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoTab extends StatefulWidget {
  const _AccountInfoTab();

  @override
  State<_AccountInfoTab> createState() => _AccountInfoTabState();
}

class _AccountInfoTabState extends State<_AccountInfoTab> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _nameController = TextEditingController(text: user?.userMetadata?['name'] ?? '');
    _usernameController = TextEditingController(text: user?.userMetadata?['username'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': _nameController.text,
            'username': _usernameController.text,
          },
        ),
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  (user?.userMetadata?['name'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileInfoBox(label: 'Email', value: user?.email ?? 'N/A'),
                  const SizedBox(height: 12),
                  _ProfileInfoBox(label: 'Name', value: user?.userMetadata?['name'] ?? 'Not set'),
                  const SizedBox(height: 12),
                  _ProfileInfoBox(label: 'Username', value: user?.userMetadata?['username'] ?? 'Not set'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _LoginSignUpTab extends StatefulWidget {
  const _LoginSignUpTab();

  @override
  State<_LoginSignUpTab> createState() => _LoginSignUpTabState();
}

class _LoginSignUpTabState extends State<_LoginSignUpTab> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            tabs: const [
              Tab(text: 'Sign In'),
              Tab(text: 'Sign Up'),
            ],
          ),
          Expanded(
            child: _selectedTab == 0 ? const _LoginForm() : const _SignUpForm(),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'name': _nameController.text,
          'username': _usernameController.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please verify your email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _supabase = Supabase.instance.client;
  bool _notificationsEnabled = true;
  bool _privacyEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Notifications Enabled'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            const SizedBox(height: 24),
            const Text('Privacy & Terms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Privacy Policy Agreed'),
              value: _privacyEnabled,
              onChanged: (value) => setState(() => _privacyEnabled = value),
            ),
            const SizedBox(height: 24),
            const Text('App Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('App Version'),
                  Text('1.0.0'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _supabase.auth.signOut();
                    if (!mounted) return;
                    navigator.popUntil((route) => route.isFirst);
                  },
                  child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _lostReports = [];
  List<dynamic> _foundReports = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final lost = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'lost')
            .order('created_at', ascending: false);
        
        final found = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'found')
            .order('created_at', ascending: false);

        // Sort both with unclaimed at top, then claimed at bottom
        _sortItems(lost);
        _sortItems(found);

        setState(() {
          _lostReports = lost;
          _foundReports = found;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _historyError = 'Failed to load activity: ${e.toString()}';
      });
    }
  }

  void _sortItems(List<dynamic> items) {
    items.sort((a, b) {
      final aClaimed = (a['status'] == 'claimed' || a['status'] == 'found');
      final bClaimed = (b['status'] == 'claimed' || b['status'] == 'found');
      if (aClaimed != bClaimed) return aClaimed ? 1 : -1;
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  List<dynamic> _filterItems(List<dynamic> items) {
    return items.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Activity'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_historyError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _historyError!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.red),
                              onPressed: () => setState(() => _historyError = null),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search your reports...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Lost Reports Section
                    _buildHistorySection(
                      title: 'Lost Reports',
                      subtitle: 'Items not yet found at bottom',
                      icon: Icons.search,
                      color: Colors.red,
                      items: _filterItems(_lostReports),
                      allowDelete: true,
                    ),
                    const SizedBox(height: 24),
                    // Found Reports Section
                    _buildHistorySection(
                      title: 'Found Reports',
                      subtitle: 'Items not yet claimed at bottom',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      items: _filterItems(_foundReports),
                      allowDelete: false,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHistorySection({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
    required bool allowDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No ${title.toLowerCase()} yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildHistoryItem(items[index], allowDelete),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic item, bool allowDelete) {
    final itemType = item['item_type']?.toString().toUpperCase() ?? 'UNKNOWN';
    final isLost = itemType == 'LOST';
    final hasImage = item['image_url'] != null && item['image_url'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLost ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item['image_url'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          isLost ? Icons.search : Icons.check_circle,
                          color: isLost ? Colors.red : Colors.green,
                        );
                      },
                    ),
                  )
                : Icon(
                    isLost ? Icons.search : Icons.check_circle,
                    color: isLost ? Colors.red : Colors.green,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['category'] ?? 'Uncategorized',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item['created_at']),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (allowDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () => _deleteItem(item['id']),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Delete report',
            ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _supabase.from('items').delete().eq('id', itemId);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Future<void>? _addMarkersFuture;

  @override
  void initState() {
    super.initState();
    _addMarkersFuture = _addMarkers();
  }

  static const CameraPosition startPos = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746
    );

  final Set<Marker> _markers = {};

  Future<void> _addMarkers() async {

    final data = await Supabase.instance.client
    .from('items')
    .select();

    for (var item in data) {
      Marker newMarker = Marker(
        markerId: MarkerId(item['id']),
        position: LatLng(item['location_lat'], item['location_lng']),
        onTap: () {
          showModalBottomSheet(context: context, 
          builder: (BuildContext context){
            return SizedBox.expand(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: <Widget>[
                                  Text(item['title'],
                                  style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.6),
                                  textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                child: Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Image.network(item['image_url'], height: 200, width: 200),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(item['description']),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LostItemForm()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Submit Claim'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      ],
                    ),
                  );
          }
          );
        }
      );
        _markers.add(newMarker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _addMarkersFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator()); // Show loading spinner while markers load
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                      'Error: ${snapshot.error}')); // Display error if marker loading fails
            } else {
              return GoogleMap(
                initialCameraPosition: startPos,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              );
            }
        }
        
        ),
    );
  }
}

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Messages'));
  }
}
