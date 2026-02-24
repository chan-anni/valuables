import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';


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
  }

  static const CameraPosition startPos = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = <Marker>{};

  Future<void> _addMarkers() async {
    final data = await Supabase.instance.client.from('items').select();

    for (var item in data) {
      if (item['id'] == null || item['location_lat'] == null || item['location_lng'] == null || 
          item['title'] == null) {
        continue;
      }

    final rawDescription = item['description'];
    final description = (rawDescription == null || rawDescription.toString().trim().isEmpty)
        ? 'No description added'
        : rawDescription.toString();
        
      Marker newMarker = Marker(
        markerId: MarkerId(item['id']),
        position: LatLng(item['location_lat'], item['location_lng']),
        onTap: () {
          showModalBottomSheet(context: context, 
          builder: (BuildContext context){
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['title'],
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.6),
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
            }
          );
        },
      );
      _markers.add(newMarker);
    }
  }

  // Deals with fetching the user's current location, checking 
  // permissions, and updating the map and picked location.
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
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

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
                        : const Icon(Icons.my_location, color: Colors.green),
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