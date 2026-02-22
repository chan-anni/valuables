import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _claimedLostItems = [];
  List<dynamic> _claimedFoundItems = [];
  List<dynamic> _unclaimedLostItems = [];
  List<dynamic> _unclaimedFoundItems = [];
  List<dynamic> _oldAlerts = [];
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
        // Load claimed lost items
        final claimedLost = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'lost')
            .eq('status', 'claimed')
            .order('created_at', ascending: false);
        
        // Load claimed found items
        final claimedFound = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'found')
            .eq('status', 'claimed')
            .order('created_at', ascending: false);

        // Load unclaimed lost items
        final unclaimedLost = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'lost')
            .neq('status', 'claimed')
            .order('created_at', ascending: false);
        
        // Load unclaimed found items
        final unclaimedFound = await _supabase
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('item_type', 'found')
            .neq('status', 'claimed')
            .order('created_at', ascending: false);

        // Load old alerts
        List<dynamic> oldAlerts = [];
        try {
          final alerts = await _supabase
              .from('alerts')
              .select('*, item:items(*)')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(50);
          for (var a in alerts) {
            if (a['item'] != null) oldAlerts.add(a['item']);
          }
        } catch (e) {
          // Fallback if alerts table structure is different
          oldAlerts = [];
        }

        setState(() {
          _claimedLostItems = claimedLost;
          _claimedFoundItems = claimedFound;
          _unclaimedLostItems = unclaimedLost;
          _unclaimedFoundItems = unclaimedFound;
          _oldAlerts = oldAlerts;
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & History'),
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
                        hintText: 'Search your items...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Active Items (Combined)
                    _buildHistorySection(
                      title: 'Active Items',
                      icon: Icons.access_time,
                      color: Colors.grey,
                      items: _filterItems([..._unclaimedLostItems, ..._unclaimedFoundItems]),
                    ),
                    const SizedBox(height: 24),
                    // Claimed Lost Items Section
                    _buildHistorySection(
                      title: 'Past Lost Items',
                      icon: Icons.help_outline,
                      color: primaryColor,
                      items: _filterItems(_claimedLostItems),
                    ),
                    const SizedBox(height: 24),
                    // Claimed Found Items Section
                    _buildHistorySection(
                      title: 'Past Found Items',
                      icon: Icons.location_on,
                      color: secondaryColor,
                      items: _filterItems(_claimedFoundItems),
                    ),
                    const SizedBox(height: 24),
                    // Old Alerts Section
                    _buildHistorySection(
                      title: 'Past Match Alerts',
                      icon: Icons.notifications,
                      color: Colors.grey,
                      items: _filterItems(_oldAlerts),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildHistorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
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
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${items.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
                'No items in this category',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildHistoryItem(items[index]),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    final itemType = item['item_type']?.toString().toUpperCase() ?? 'UNKNOWN';
    final isLost = itemType == 'LOST';
    final hasImage = item['image_url'] != null && item['image_url'].toString().isNotEmpty;
    final status = item['status']?.toString() ?? 'unknown';
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLost ? primaryColor.withOpacity(0.1) : secondaryColor.withOpacity(0.1),
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
                          isLost ? Icons.help_outline : Icons.location_on,
                          color: isLost ? primaryColor : secondaryColor,
                        );
                      },
                    ),
                  )
                : Icon(
                    isLost ? Icons.help_outline : Icons.location_on,
                    color: isLost ? primaryColor : secondaryColor,
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
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(item['created_at']),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'claimed' ? Colors.grey.shade300 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'claimed' ? Colors.grey.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}