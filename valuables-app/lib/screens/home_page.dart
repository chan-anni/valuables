import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Debug: trace HomePage init
    print('HomePage.initState: start');
    if (Supabase.instance.client != null) {
      _loadRecentItems().then((_) => print('HomePage.initState: recent loaded'));
    } else {
      print('HomePage.initState: Supabase not ready, skipping data loads');
    }
    print('HomePage.initState: end');
  }

  Future<void> _loadRecentItems() async {
    try {
      if (Supabase.instance.client == null) {
        print('_loadRecentItems: Supabase not initialized, skipping load');
        return;
      }
      dynamic query = _supabase.from('items').select();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRecentItems();
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

              if (_recentItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('No items found.'),
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
        ),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate expiration (dummy logic: 30 days from creation)
    String expirationText = 'Expires soon';
    bool showExpirationOnCard = false;
    DateTime? expirationDate;

    try {
      final created = DateTime.parse(item['created_at']);
      expirationDate = created.add(const Duration(days: 30));
      final daysLeft = expirationDate.difference(DateTime.now()).inDays;
      
      if (daysLeft <= 5) {
        showExpirationOnCard = true;
        expirationText = daysLeft > 0 ? 'Expires in $daysLeft days' : 'Expired';
      }
    } catch (_) {}

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item['title'] ?? 'Item Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${item['category'] ?? 'Uncategorized'}'),
                const SizedBox(height: 8),
                Text(item['description'] ?? 'No description provided.'),
                const SizedBox(height: 16),
                if (expirationDate != null)
                  Text(
                    'Expires on: ${expirationDate.year}-${expirationDate.month}-${expirationDate.day}',
                    style: TextStyle(color: Colors.red.shade300, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Image or Icon placeholder
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
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  if (item['description'] != null)
                    Text(
                      item['description'] ?? '',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showExpirationOnCard) ...[
                    const SizedBox(height: 4),
                    Text(
                      expirationText,
                      style: TextStyle(fontSize: 10, color: Colors.red.shade300, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLost ? primaryColor.withOpacity(0.1) : secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isLost ? 'LOST' : 'FOUND',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLost ? primaryColor : secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}