import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:geolocator/geolocator.dart';
import 'package:valuables/theme_controller.dart';


class MapPage extends StatefulWidget {
  final double? notifItemLat;    
  final double? notifItemLng;     
  final String? notifItemId; 
  final bool fromNotification;

  // For zooming into notifications location on tap , override the default map position and marker highlighting
  const MapPage({super.key, this.notifItemLat, this.notifItemLng, this.notifItemId, this.fromNotification = false}); 
  

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
          final controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(widget.notifItemLat!, widget.notifItemLng!), 16),
          );
        } catch (e) {
          debugPrint('Error animating to notif: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    supabaseInitializedNotifier.removeListener(_onSupabaseInitialized);
    super.dispose();
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
      final data = await Supabase.instance.client.from('items').select();
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

  Marker _buildMarker(Map<String, dynamic> item, {bool isNotifItem = false}) {
    final rawDescription = item['description'];
    final description = (rawDescription == null || rawDescription.toString().trim().isEmpty)
        ? 'No description added'
        : rawDescription.toString();

    return Marker(
      markerId: MarkerId(item['id'].toString()),
      position: LatLng(item['location_lat'] as double, item['location_lng'] as double),
      icon: isNotifItem
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
          : BitmapDescriptor.defaultMarker,
      onTap: () {
            showModalBottomSheet(context: context, 
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            builder: (BuildContext context){
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  (item['image_url'] != null && (item['image_url'] as String).isNotEmpty) 
                    ? Image.network(
                        item['image_url'],
                        height: 200,
                        width: 200,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress != null) {
                            return const SizedBox(
                              height: 200,
                              width: 200,
                              child: CircularProgressIndicator(),
                            );
                          }
                          return child;
                        },
                      )
                    : Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
              ),
            ],
          );
        },
      );
    },
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

  Future<void> _goToCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
            ),
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
              content: Text(
                'Location permission denied. Please change it in settings to use this feature.',
              ),
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
          // Category dropdown
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
          // Time dropdown
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
                // Current location button
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
