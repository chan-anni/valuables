import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:valuables/main.dart' show HistoryPage;

// Trivial comment to test the code coverage comments setup
class HomePage extends StatefulWidget {
  final VoidCallback? onBrowsePressed;
  
  const HomePage({super.key, this.onBrowsePressed});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _recentItems = [];
  List<dynamic> _alertItems = [];
  bool _isLoading = true;
  bool _itemsExpanded = false;
  String? _errorMessage;
  // Notification preferences
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadRecentItems();
    _loadAlerts();
  }

  Future<void> _loadRecentItems() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      dynamic query = _supabase.from('items').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final data = await query.order('created_at', ascending: false).limit(50);

      // Filter to only unclaimed items and sort by upload time (newest first)
      List<dynamic> unclaimedItems = data
          .where((item) => item['status'] != 'claimed' && item['status'] != 'found')
          .toList();
      
      unclaimedItems.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _recentItems = unclaimedItems;
      });
    } catch (e) {
      setState(() {
        _recentItems = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recent items: $e')),
        );
      }
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      List items = [];

      if (userId != null) {
        // Try to load alerts joined to items (schema-dependent). If that fails, fall back.
        try {
          final alerts = await _supabase
              .from('alerts')
              .select('*, item:items(*)')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(50);
          for (var a in alerts) {
            if (a['item'] != null) items.add(a['item']);
          }
        } catch (e) {
          // Fallback: try to fetch items where status is 'found' as a placeholder
          final data = await _supabase
              .from('items')
              .select()
              .eq('status', 'found')
              .order('created_at', ascending: false)
              .limit(10);
          items = data;
        }
      } else {
        final data = await _supabase
            .from('items')
            .select()
            .eq('status', 'found')
            .order('created_at', ascending: false)
            .limit(10);
        items = data;
      }

      // Sort alerts: unclaimed at top, then by upload time desc
      items.sort((a, b) {
        final aClaimed = (a['status'] == 'claimed' || a['status'] == 'found');
        final bClaimed = (b['status'] == 'claimed' || b['status'] == 'found');
        if (aClaimed != bClaimed) return aClaimed ? 1 : -1;
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _alertItems = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _alertItems = [];
        _isLoading = false;
        _errorMessage = 'Failed to load alerts: ${e.toString()}';
      });
    }
  }

  String _displayName() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['name'] ?? user?.email ?? 'Guest User';
  }

  void _showSettingsModal(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Account Section
              if (isLoggedIn) ...[
                const Text(
                  'Account',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/account');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final navigationContext = context;
                    Navigator.pop(navigationContext);
                    await _supabase.auth.signOut();
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(navigationContext).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
              
              // Notifications Section
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Notifications'),
                trailing: Switch(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Push Notifications'),
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Match alerts are always enabled to help you find your items and connect with others.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // About Section
              const Text(
                'About',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About Valuables'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About Valuables'),
                      content: const Text(
                        'Valuables is a community-driven platform where people can report lost items and upload found items. Our mission is to reunite valuable possessions with their owners by connecting people who have found items with those searching for them.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help & Support'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'How to Use Valuables',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '📱 Reporting Items\n'
                              'You can report lost or found items by tapping the "Report Item" button on the home screen. Provide details like item description, location, and images to help others identify it.\n\n'
                              '🔔 Notifications\n'
                              'When someone uploads a found item that matches your lost item report, you\'ll receive a notification. Similarly, if your found item matches someone\'s lost item report, they\'ll be notified.\n\n'
                              '💬 Messaging & Claims\n'
                              'Once you see a potential match, you can message the other user directly through the app. Discuss details like the item\'s condition, location, and meeting arrangements. Users can claim items, and claimed items are moved to your activity history.\n\n'
                              '📋 Activity History\n'
                              'Your Activity & History section shows claimed items and past match alerts. This helps you keep track of your transactions and maintain a record of items you\'ve successfully recovered or helped others retrieve.\n\n'
                              '🔍 Browsing\n'
                              'Use the Map view to search for items in specific locations. Filter by category or date to find what you\'re looking for.\n\n'
                              '❓ Need More Help?\n'
                              'If you have questions, please contact our support team through the app.',
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityModal(BuildContext context) {
    final outerContext = context; // Save the outer context for navigation
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity & History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Activity Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          'View your reports, alerts, and messages',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(modalContext);
                  // Import HistoryPage from main.dart and navigate directly
                  Navigator.of(outerContext).push(
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Full Activity History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getWelcomeMessage() {
    final user = _supabase.auth.currentUser;
    final name = user?.userMetadata?['name'] as String?;
    if (name != null && name.isNotEmpty) {
      return 'Welcome, $name';
    }
    return 'Welcome';
  }

  void _showProfileModal(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                _displayName().isNotEmpty ? _displayName()[0].toUpperCase() : 'G',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Text(_displayName(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSettingsModal(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile & Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/account');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In to Your Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRecentItems();
        await _loadAlerts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (_errorMessage != null)
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
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.red),
                        onPressed: () => setState(() => _errorMessage = null),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

              // Profile Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showProfileModal(context),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            _displayName().isNotEmpty ? _displayName()[0].toUpperCase() : 'G',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showSettingsModal(context),
                        icon: const Icon(Icons.settings),
                      ),
                      IconButton(
                        onPressed: () => _showActivityModal(context),
                        icon: const Icon(Icons.history),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Welcome Section with User Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWelcomeMessage(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Report Item Section
              Text(
                'Report lost or found items',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LostItemForm()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 32),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text('Report Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Browse Items Section
              Text(
                'Search for your items',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onBrowsePressed,
                  icon: const Icon(Icons.explore, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Browse Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Alerts Section Instructions
              const SizedBox(height: 4),
              Text(
                'Get notified when potential matches are found',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Alerts On Your Lost Items Section (collapsible)
              ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active, size: 20),
                        SizedBox(width: 8),
                        Text('Alerts On Your Lost Items', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_alertItems.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_alertItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('No active alerts. Create alerts on items to get notified when matches appear.', style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _alertItems.length,
                      itemBuilder: (context, index) {
                        final item = _alertItems[index];
                        return _NotificationCard(item: item);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Your Listings Section Instructions
              const SizedBox(height: 4),
              Text(
                'Keep track of items waiting to be claimed',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Your Unclaimed Listings (collapsible)
              ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Your Listings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_recentItems.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                initiallyExpanded: _itemsExpanded,
                onExpansionChanged: (v) => setState(() => _itemsExpanded = v),
                children: [
                  if (_recentItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text('You have not listed any items yet.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentItems.length,
                      itemBuilder: (context, index) {
                        final item = _recentItems[index];
                        return _ItemCard(item: item);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _NotificationCard extends StatelessWidget {
  final dynamic item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.amber.shade600,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check_circle, size: 16, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Item Found',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${item['category'] ?? 'Unknown'} • ${item['item_type']?.toUpperCase() ?? 'UNKNOWN'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              item['description'] ?? '',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final itemType = item['item_type']?.toUpperCase() ?? 'UNKNOWN';
    final isLost = itemType == 'LOST';
    final hasImage = item['image_url'] != null && item['image_url'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Image or Icon placeholder
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['category'] ?? 'Uncategorized'} • ${item['item_type'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                if (item['description'] != null)
                  Text(
                    item['description'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLost ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isLost ? 'LOST' : 'FOUND',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isLost ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
