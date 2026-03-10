import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/theme_controller.dart';

class HomePage extends StatefulWidget {
  final void Function(dynamic item)? onBrowsePressed;
  final SupabaseClient? supabaseClient;
  
  const HomePage({super.key, this.onBrowsePressed, this.supabaseClient});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SupabaseClient? _supabase;
  List<dynamic> _recentItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    supabaseInitializedNotifier.addListener(_onSupabaseInitialized);
    
    // Use injected client or fallback to singleton if initialized
    try {
      _supabase = widget.supabaseClient ?? Supabase.instance.client;
    } catch (e) {
      _supabase = null;
    }

    // Debug: trace HomePage init
    debugPrint('HomePage.initState: start');
    if (_supabase != null) {
      _loadRecentItems().then((_) => debugPrint('HomePage.initState: recent loaded'));
    } else {
      debugPrint('HomePage.initState: Supabase not ready, skipping data loads');
      _isLoading = false;
    }
    debugPrint('HomePage.initState: end');
  }

  @override
  void dispose() {
    supabaseInitializedNotifier.removeListener(_onSupabaseInitialized);
    super.dispose();
  }

  void _onSupabaseInitialized() {
    if (supabaseInitializedNotifier.value && mounted) {
      setState(() {
        _supabase = Supabase.instance.client;
        _isLoading = true;
      });
      _loadRecentItems();
    }
  }

  Future<void> _loadRecentItems() async {
    try {
      if (_supabase == null) {
        debugPrint('_loadRecentItems: Supabase not initialized, skipping load');
        return;
      }
      dynamic query = _supabase!.from('items').select();
      final data = await query.order('created_at', ascending: false).limit(50);

      // Filter to only unclaimed items and sort by upload time (newest first)
      List<dynamic> unclaimedItems = data.where((item) {
        final type = (item['type'] ?? item['item_type'] ?? '').toString().toLowerCase();
        final status = (item['status'] ?? '').toString().toLowerCase();
        return type.contains('found') && !type.contains('lost') && status != 'claimed';
      }).toList();
      
      unclaimedItems.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _recentItems = unclaimedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recentItems = [];
        _isLoading = false;
        _errorMessage = 'Failed to load recent items: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

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
                    return ItemCard(
                      item: item,
                      onViewOnMap: (selectedItem) {
                        widget.onBrowsePressed?.call(selectedItem);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class ItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onClaim;
  final void Function(dynamic item)? onViewOnMap;

  const ItemCard({super.key, required this.item, this.onClaim, this.onViewOnMap});

  @override
  Widget build(BuildContext context) {
    final rawType = item['type'] ?? item['item_type'];
    final itemType = rawType?.toString().toUpperCase() ?? 'UNKNOWN';
    final isLost = itemType == 'LOST';
    final isFound = itemType == 'FOUND';
    final hasImage = item['image_url'] != null && item['image_url'].toString().isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final typeColor = isLost ? primaryColor : (isFound ? secondaryColor : Colors.grey);
    final typeBgColor = typeColor.withValues(alpha: 0.1);
    
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
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              if (onViewOnMap != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onViewOnMap!(item);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (onClaim != null)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onClaim!();
                  },
                  child: Text(isLost ? 'Remove' : 'Mark Claimed'),
                ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Image or Icon placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: typeBgColor,
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
                            isLost ? Icons.help_outline : (isFound ? Icons.location_on : Icons.help),
                            color: typeColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      isLost ? Icons.help_outline : (isFound ? Icons.location_on : Icons.help),
                      color: typeColor,
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
                    '${item['category'] ?? 'Uncategorized'} • $itemType',
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
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    itemType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                if (onClaim != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLost ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        child: Text(isLost ? 'Remove' : 'Mark Claimed'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}