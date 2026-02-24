import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapPickerResult {
  final double lat;
  final double lng;
  final String? locationName;

  MapPickerResult({required this.lat, required this.lng, this.locationName});
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  
  // Test hooks: allow injecting initial search results and location name cache
  final List<Location>? initialSearchResults;
  final Map<String, String>? initialLocationNames;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialSearchResults,
    this.initialLocationNames,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _pickedLocation;
  
  static const CameraPosition _kDefaultCenter = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746,
  );
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

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
    // If tests injected initial search results or names, wire them into state
    if (widget.initialSearchResults != null) {
      _searchResults = widget.initialSearchResults!;
    }
    if (widget.initialLocationNames != null) {
      _locationNames.addAll(widget.initialLocationNames!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_pickedLocation != null) {
      Navigator.pop(
        context,
        MapPickerResult(
          lat: _pickedLocation!.latitude,
          lng: _pickedLocation!.longitude,
          locationName: '${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
              color: primaryColor,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: _pickedLocation != null ? const EdgeInsets.only(bottom: 100) : EdgeInsets.zero,
            initialCameraPosition: _pickedLocation != null
                ? CameraPosition(target: _pickedLocation!, zoom: 15)
                : _kDefaultCenter,
            onMapCreated: _onMapCreated,
            onTap: _onTap,
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedLocation!,
                    ),
                  }
                : {},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (_pickedLocation != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}