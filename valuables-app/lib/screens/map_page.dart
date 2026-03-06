import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:geolocator/geolocator.dart';
import 'package:valuables/theme_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

// Map page -- needs API key
class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  bool _isLoadingLocation = false;
  Future<void>? _addMarkersFuture;

  @override
  void initState() {
    super.initState();
    _addMarkersFuture = _addMarkers();
    supabaseInitializedNotifier.addListener(_onSupabaseInitialized);
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
    zoom: 14.4746,
  );

  final Set<Marker> _markers = <Marker>{};

  Future<void> _addMarkers() async {
    if (!supabaseInitializedNotifier.value) return;

    try {
      final data = await Supabase.instance.client.from('items').select();

      for (var item in data) {
        if (item['id'] == null ||
            item['location_lat'] == null ||
            item['location_lng'] == null ||
            item['title'] == null) {
          continue;
        }

        final rawDescription = item['description'];
        final description =
            (rawDescription == null || rawDescription.toString().trim().isEmpty)
            ? 'No description added'
            : rawDescription.toString();

        Marker newMarker = Marker(
          markerId: MarkerId(item['id'].toString()),
          position: LatLng(item['location_lat'], item['location_lng']),
          onTap: () {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              builder: (context) => DraggableScrollableSheet(
                minChildSize: 0.25,
                initialChildSize: 0.8,
                maxChildSize: 0.8,
                snap: true,
                snapSizes: const [0.25, 0.4, 0.8],
                expand: false,
                builder: (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: IconButton(
                            padding: EdgeInsets.zero, // Remove internal padding
                            constraints:
                                const BoxConstraints(), // Remove the 48x48 restriction
                            visualDensity:
                                VisualDensity.compact, // Tighten up the layout
                            icon: const Icon(Icons.drag_handle),
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child:
                                  (item['image_url'] != null &&
                                      (item['image_url'] as String).isNotEmpty)
                                  ? Image.network(
                                      item['image_url'],
                                      height: 200,
                                      width: 200,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress != null) {
                                              return SizedBox(
                                                height: 200,
                                                width: 200,
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            } else {
                                              return child;
                                            }
                                          },
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          190,
                                          190,
                                          190,
                                        ), // The background color
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ), // Makes the background a circle
                                      ),
                                      child: Icon(Icons.image_not_supported),
                                    ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                item['description'],
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LostItemForm(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Submit Claim'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        _markers.add(newMarker);
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
              content: Text(
                'Location services are disabled. Please enable them.',
              ),
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
                    _controller.complete(controller);
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
                        : Icon(
                            Icons.my_location,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
