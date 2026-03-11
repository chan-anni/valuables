import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:valuables/claims/claims_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:valuables/theme_controller.dart';


class MapPage extends StatefulWidget {
  final dynamic itemToFocus;
  final double? notifItemLat;    
  final double? notifItemLng;     
  final String? notifItemId; 
  final bool fromNotification;

  const MapPage({super.key, this.itemToFocus, this.notifItemLat, this.notifItemLng, this.notifItemId, this.fromNotification = false});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _isLoadingLocation = false;
  Future<void>? _addMarkersFuture;

  List<Map<String, dynamic>> _allItems = [];
  String _selectedCategory = 'All';
  String _selectedTimeRange = 'all';

  static const List<String> _categories = [
    'All', 'Phones', 'Laptops', 'Clothing', 'Accessories',
    'Keys', 'Bags', 'Wallets', 'Misc. Electronics', 'Other',
  ];

  static const Map<String, String> _timeLabels = {
    'all': 'All Time',
    'today': 'Today',
    'week': 'This Week',
    'month': 'This Month',
  };

  static const Map<String, double> _categoryHues = {
    'Phones': BitmapDescriptor.hueBlue,
    'Laptops': BitmapDescriptor.hueCyan,
    'Clothing': BitmapDescriptor.hueRose,
    'Accessories': BitmapDescriptor.hueMagenta,
    'Keys': BitmapDescriptor.hueYellow,
    'Bags': BitmapDescriptor.hueOrange,
    'Wallets': BitmapDescriptor.hueGreen,
    'Misc. Electronics': BitmapDescriptor.hueAzure,
    'Other': BitmapDescriptor.hueViolet,
  };

  @override
  void initState() {
    super.initState();
    _addMarkersFuture = _loadItems();
    supabaseInitializedNotifier.addListener(_onSupabaseInitialized);
    if (widget.notifItemLat != null && widget.notifItemLng != null) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        try { await _addMarkersFuture; } catch (_) {}
        try {
          if (_controller.isCompleted) {
            final controller = await _controller.future;
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(widget.notifItemLat!, widget.notifItemLng!), 16),
            );
          }
        } catch (e) {
          debugPrint('Error animating to notif: $e');
        }
      });
    }
    if (widget.itemToFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToItemLocation(widget.itemToFocus);
        _showItemDetailsModal(widget.itemToFocus);
      });
    }
  }

  @override
  void dispose() {
    supabaseInitializedNotifier.removeListener(_onSupabaseInitialized);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemToFocus != null && widget.itemToFocus != oldWidget.itemToFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToItemLocation(widget.itemToFocus);
        _showItemDetailsModal(widget.itemToFocus);
      });
    }
  }

  void _onSupabaseInitialized() {
    if (supabaseInitializedNotifier.value) {
      setState(() {
        _addMarkersFuture = _loadItems();
      });
    }
  }

  static const CameraPosition startPos = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = <Marker>{};

  Future<void> _loadItems() async {
    if (!supabaseInitializedNotifier.value) return;
    try {
      final data = await Supabase.instance.client
          .from('items')
          .select()
          .eq('type', 'found')
          .eq('status', 'active');
      _allItems = List<Map<String, dynamic>>.from(data);
      if (widget.notifItemId != null) {
        _buildNotificationMarker();
      } else {
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  void _buildNotificationMarker() {
    final newMarkers = <Marker>{};
    for (final item in _allItems) {
      if (item['id']?.toString() != widget.notifItemId) continue;
      if (item['location_lat'] == null || item['location_lng'] == null) continue;
      if (item['title'] == null) continue;
      newMarkers.add(_buildMarker(item, isNotifItem: true));
    }
    if (mounted) {
      setState(() {
        _markers..clear()..addAll(newMarkers);
      });
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Marker _buildMarker(Map<String, dynamic> item, {bool isNotifItem = false}) {
    final category = item['category'] as String? ?? 'Unknown';

    return Marker(
      markerId: MarkerId(item['id'].toString()),
      position: LatLng(item['location_lat'] as double, item['location_lng'] as double),
      icon: isNotifItem
          ? BitmapDescriptor.defaultMarker
          : BitmapDescriptor.defaultMarkerWithHue(
              _categoryHues[category] ?? BitmapDescriptor.hueRed,
            ),
      onTap: () {
        _showItemDetailsModal(item);
      },
    );
  }

  void _showItemDetailsModal(dynamic item) {
    final rawDescription = item['description'];
    final description = (rawDescription == null || rawDescription.toString().trim().isEmpty)
        ? 'No description added'
        : rawDescription.toString();
    final itemType = (item['type'] as String?)?.toUpperCase() ?? 'UNKNOWN';
    final category = item['category'] as String? ?? 'Unknown';
    final createdAt = DateTime.tryParse(item['created_at'] ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final primary = Theme.of(context).colorScheme.primary;
        final secondary = Theme.of(context).colorScheme.secondary;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isLost = itemType == 'LOST';
        final typeColor = isLost ? primary : secondary;

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Image
                  (item['image_url'] != null && (item['image_url'] as String).isNotEmpty)
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  extendBodyBehindAppBar: true,
                                  appBar: AppBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    leading: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      minScale: 1.0,
                                      maxScale: 5.0,
                                      child: Image.network(
                                        item['image_url'],
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['image_url'],
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress != null
                                      ? const SizedBox(
                                          height: 180,
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      : child,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                  const SizedBox(height: 12),
                  // Type + Category badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          itemType,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Date
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // "This is mine" claim button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openClaimSheet(
                        sheetContext: context,
                        item: item,
                      ),
                      icon: const Icon(Icons.pan_tool_alt_outlined),
                      label: const Text('This is mine'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openClaimSheet({
    required BuildContext sheetContext,
    required Map<String, dynamic> item,
  }) {
    final finderId = item['user_id'] as String?;
    if (finderId == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Could not identify the finder of this item.')),
      );
      return;
    }

    final currentUser = GetIt.I<AuthService>().getCurrentUserSession()?.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Please sign in to claim an item.')),
      );
      return;
    }

    if (currentUser.id == finderId) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('You cannot claim your own item.')),
      );
      return;
    }

    Navigator.pop(sheetContext);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ClaimSheet(
        itemId: item['id'].toString(),
        finderId: finderId,
        itemTitle: item['title'] as String? ?? 'Item',
      ),
    );
  }

  void _applyFilters() {
    final now = DateTime.now();
    final filtered = _allItems.where((item) {
      if (item['id'] == null ||
          item['location_lat'] == null ||
          item['location_lng'] == null ||
          item['title'] == null) { return false; }

      if (_selectedCategory != 'All' && item['category'] != _selectedCategory) return false;

      if (_selectedTimeRange != 'all') {
        final createdAt = DateTime.tryParse(item['created_at'] ?? '');
        if (createdAt == null) { return false; }
        final age = now.difference(createdAt);
        if (_selectedTimeRange == 'today' && age.inHours > 24) { return false; }
        if (_selectedTimeRange == 'week' && age.inDays > 7) { return false; }
        if (_selectedTimeRange == 'month' && age.inDays > 30) { return false; }
      }

      return true;
    });

    setState(() {
      _markers
        ..clear()
        ..addAll(filtered.map(_buildMarker));
    });
  }

  Future<void> _goToItemLocation(dynamic item) async {
    if (item == null || item['location_lat'] == null || item['location_lng'] == null) return;
    final latLng = LatLng(item['location_lat'] as double, item['location_lng'] as double);
    final mapController = await _controller.future;
    mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
  }

  Future<void> _goToCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please change it in settings to use this feature.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      final mapController = await _controller.future;
      mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Widget _buildFilterBar() {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    final categoryLabel = _selectedCategory;
    final timeLabel = _timeLabels[_selectedTimeRange]!;
    final categoryActive = _selectedCategory != 'All';
    final timeActive = _selectedTimeRange != 'all';

    return Positioned(
      top: 8,
      left: 12,
      child: Row(
        children: [
          _dropdownButton(
            label: categoryLabel,
            active: categoryActive,
            chipBg: chipBg,
            selectedBg: primary,
            child: PopupMenuButton<String>(
              initialValue: _selectedCategory,
              onSelected: (value) {
                setState(() => _selectedCategory = value);
                _applyFilters();
              },
              itemBuilder: (_) => [
                ..._categories.map((cat) => PopupMenuItem(value: cat, child: Text(cat))),
              ],
              child: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          _dropdownButton(
            label: timeLabel,
            active: timeActive,
            chipBg: chipBg,
            selectedBg: primary,
            child: PopupMenuButton<String>(
              initialValue: _selectedTimeRange,
              onSelected: (value) {
                setState(() => _selectedTimeRange = value);
                _applyFilters();
              },
              itemBuilder: (_) => _timeLabels.entries
                  .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownButton({
    required String label,
    required bool active,
    required Color chipBg,
    required Color selectedBg,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: active ? selectedBg : chipBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? Colors.white : null,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: active ? Colors.white : null,
                ),
              ],
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.fromNotification
          ? AppBar(
              title: const Text('Map'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: FutureBuilder(
        future: _addMarkersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: startPos,
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                  },
                ),
                if (!widget.fromNotification) _buildFilterBar(),
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location',
                    backgroundColor: Colors.white,
                    onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location,
                            color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}