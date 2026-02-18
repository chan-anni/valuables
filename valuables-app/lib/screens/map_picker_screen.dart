import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapPickerResult {
  final double lat;
  final double lng;
  final String locationName;

  MapPickerResult({
    required this.lat,
    required this.lng,
    required this.locationName,
  });
}

// This screen allows users to pick a location on the map, either by
// tapping, searching, or using their current location. It returns the
// selected coordinates and a human-readable name back to the caller.
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

// The state class manages the map controller, search functionality, 
// and location picking logic. It updates the UI based on the user 
// interactions and performs geocoding operations to convert between 
// coordinates and human-readable addresses.
class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();

  // Setup the necessary state variables to track the picked location,
  // its name, loading states, and search results.
  LatLng? _pickedLocation;
  String _locationName = 'Tap on the map to select a location';
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<Location> _searchResults = [];
  final Map<String, String> _locationNames = {}; // Cache for location names
  Timer? _debounceTimer;

  static const LatLng _defaultLocation = LatLng(
    47.6062,
    -122.3321,
  ); // Default to Seattle if no initial location is provided

  // This will allow us to initialize map with specific location coordinates if passed
  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  // Dispose of controllers to prevent memory leaks when
  // the widget is removed from the widget tree.
  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Deals with fetching the user's current location, checking 
  // permissions, and updating the map and picked location.
  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
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

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

      await _updatePickedLocation(latLng);
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

  // Updates the picked location based on user interaction and performs reverse geocoding
  // to get a human-readable address. If reverse geocoding fails, it shows the coordinates 
  // as location name.
  Future<void> _updatePickedLocation(LatLng latLng) async {
    setState(() {
      _pickedLocation = latLng;
      _locationName =
          '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = [
          place.name,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).toList();

        setState(() {
          _locationName = parts.join(', ');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error could not get address: ${e.toString()}'),
          ),
        );
      }
      // Keep coordinate fallback name if reverse geocoding fails
    }
  }

  // This is for seaching based on user typing a location in the search bar.
  // Converts the addresses to the geolocations as coordinates before updating map
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(query);
      if (mounted) {
        setState(() => _searchResults = locations);

        // Pre-fetch location names for all results
        _locationNames.clear();
        for (var loc in locations) {
          final key = '${loc.latitude},${loc.longitude}';
          try {
            final placemarks = await placemarkFromCoordinates(
              loc.latitude,
              loc.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              final parts = [
                place.name,
                place.locality,
                place.administrativeArea,
                place.country,
              ].where((part) => part != null && part.isNotEmpty).toList();
              _locationNames[key] = parts.join(', ');
            } else {
              _locationNames[key] = 'Unknown Location';
            }
          } catch (e) {
            _locationNames[key] = 'Unknown Location';
          }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchResults = []); // no related results found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No results found')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // When a user selects a search result, this method updates the map to center on
  // the selected location and updates the picked location state accordingly.
  Future<void> _selectSearchResult(Location location) async {
    final latLng = LatLng(location.latitude, location.longitude);

    _searchController.clear();
    setState(() => _searchResults = []);
    FocusScope.of(context).unfocus();

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

    await _updatePickedLocation(latLng);
  }

  // If user confirms the location chosen we return the latitude, longitude and location
  // to user. If no location is picked we return a snackbar message saying no location is chosen
  // and to choose one.
  void _confirmLocation() {
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    // Take us to the prev screen and pass back the picked location data
    Navigator.pop(
      context,
      MapPickerResult(
        lat: _pickedLocation!.latitude,
        lng: _pickedLocation!.longitude,
        locationName: _locationName,
      ),
    );
  }

  String _getLocationName(Location loc) {
    final key = '${loc.latitude},${loc.longitude}';
    return _locationNames[key] ??
        '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query);
    });
  }

  // Constructing basic UI for the map picker screen. Includes the Google Maps widget,
  // a search bar with results dropdown, a button to go to current location,
  // and a bottom panel to confirm the selected location.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pick Location',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation ?? _defaultLocation,
              zoom: _pickedLocation != null ? 15 : 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _updatePickedLocation,
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedLocation!,
                    ),
                  }
                : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Search bar + results
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchLocation,
                  ),
                ),

                // Search results dropdown
                // Search results dropdown
                if (_searchResults.isNotEmpty)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final loc = _searchResults[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                              title: Text(_getLocationName(loc)),
                              onTap: () => _selectSearchResult(loc),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

          // Bottom confirm panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _pickedLocation != null
                          ? _confirmLocation
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
