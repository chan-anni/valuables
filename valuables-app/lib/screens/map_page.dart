import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:geolocator/geolocator.dart';
import 'package:valuables/theme_controller.dart';


class MapPage extends StatefulWidget {
  final double? notifItemLat;    
  final double? notifItemLang;     
  final String? notifItemId; 
  final bool fromNotification;

  // For zooming into notifications location on tap , override the default map position and marker highlighting
  const MapPage({super.key, this.notifItemLat, this.notifItemLang, this.notifItemId, this.fromNotification = false}); 
  

  @override
  State<MapPage> createState() => _MapPageState();
}

// Map page -- needs API key
class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _isLoadingLocation = false;
  Future<void>? _addMarkersFuture;

@override
void initState() {
  super.initState();
  _addMarkersFuture = _addMarkers();
  supabaseInitializedNotifier.addListener(_onSupabaseInitialized);

  // Zoom to notification location if opened via notif tap
  // If the page was constructed with a notification payload we handle
  // the animation in the delayed flow below (which waits for markers).

    // If this MapPage was constructed with a notification payload (the
    // notif handler pushed it with lat/lng/itemId), animate to that
    // location after markers and controller are ready.
    if (widget.notifItemLat != null && widget.notifItemLang != null) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        final lat = widget.notifItemLat!;
        final lng = widget.notifItemLang!;
        if (!mounted) return;
        if (_addMarkersFuture != null) {
          try {
            await _addMarkersFuture;
          } catch (e) {
            debugPrint('Warning: _addMarkersFuture failed: $e');
          }
        }
        try {
          final controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
          );
        } catch (e) {
          debugPrint('Error animating to constructor notif target: $e');
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
        _addMarkersFuture = _addMarkers();
      });
    }
  }

  static const CameraPosition startPos = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746
    );

  final Set<Marker> _markers = <Marker>{};

  Future<void> _addMarkers() async {
    if (!supabaseInitializedNotifier.value) return;
    final newMarkers = <Marker>{};

    try {
      final data = await Supabase.instance.client.from('items').select();

      for (var item in data) {
        if (item['type'] != 'found') continue; // Only show found items on map, don't include items
        if (item['id'] == null || item['location_lat'] == null || item['location_lng'] == null || 
            item['title'] == null) {
              debugPrint('DB id: ${item['id']}  notif id: ${widget.notifItemId}');
          continue;
        }

        final rawDescription = item['description'];
        final description = (rawDescription == null || rawDescription.toString().trim().isEmpty)
            ? 'No description added'
            : rawDescription.toString();
        final bool isNotifItem =
          widget.notifItemLat != null &&
          widget.notifItemLang != null &&
          (item['location_lat'] - widget.notifItemLat!).abs() < 0.00001 &&
          (item['location_lng'] - widget.notifItemLang!).abs() < 0.00001;
            
        // Adding the actual marker with a different color if it's the one from the notification (only applicable if coming from a notif)
        newMarkers.add( Marker(
          markerId: MarkerId(item['id'].toString()),
          position: LatLng(item['location_lat'], item['location_lng']),
          icon: isNotifItem
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure) // Blue for now, can change later
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    height: 200, width: 200, 
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress != null) {
                        return SizedBox(height: 200, width: 200, child: CircularProgressIndicator(),);
                      } else {
                        return child;
                      }
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
                    child: Text(description,
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
              }
            );
          },
        )
        );
    }
    // Only update state if widget is still mounted to avoid setState on unmounted widget error
      if (mounted) {
        setState(() {
          _markers
            ..clear()
            ..addAll(newMarkers);
        });
      }
    } catch (e) {
      debugPrint('Error loading markers: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      // Make sure location services are enabled
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
      // Check/request location permissions
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
      // Get current positiion
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      final mapController = await _controller.future;
      mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

    } catch (e) {

      // error catching for any issues during location fetching, such as timeouts or service errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
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
            return const Center(
              child: CircularProgressIndicator(),
            ); // Show loading spinner while markers load
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            ); // Display error if marker loading fails
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
                        :  Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ]
            );
          }
        },
      ),
    );
  }
}