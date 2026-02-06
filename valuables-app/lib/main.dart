import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_custom_marker/google_maps_custom_marker.dart';

void main() {
  runApp( MyApp() );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return const MaterialApp(home: Navigation());
  }

}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

// Stores and navigates through the different pages with a Widget array.
final pages = const <Widget>[
    HomePage(),
    MapPage(),
    MessagePage()
  ];

// Each page has their own build function to make things simple
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home'),);
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

// Map needs API key
class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Future<void>? _addMarkersFuture;

  @override
  void initState() {
    super.initState();
    _addMarkersFuture = _addMarkers();
  }

  static const CameraPosition startPos = CameraPosition(
    target: LatLng(47.65428653800135, -122.30802267054545),
    zoom: 14.4746
    );

  final Set<Marker> _markers = <Marker>{
    Marker(
      markerId: MarkerId('1'), 
      position: LatLng(46.65428653800135, -122.30802267054545)
      ),
    Marker(markerId: MarkerId('2'), position: LatLng(48.65428653800135, -122.30802267054545))
  };

  Future<void> _addMarkers() async {

    Marker pinMarker = await GoogleMapsCustomMarker.createCustomMarker(
    marker: const Marker(
        markerId: MarkerId('pin'),
        position: LatLng(47.68428653900135, -122.30802267054545),
    ),
    shape: MarkerShape.pin,
    pinOptions: PinMarkerOptions(diameter: 20.0)
  );
  _markers.add(pinMarker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _addMarkersFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator()); // Show loading spinner while markers load
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                      'Error: ${snapshot.error}')); // Display error if marker loading fails
            } else {
              return GoogleMap(
                initialCameraPosition: startPos,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              );
            }
        }
        
        ),
    );
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: startPos,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
      ),
    );
  }
}

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Messages'),);
  }
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Valuables', style: TextStyle(color: Colors.white),),
        ),

        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon (Icons.home),
              label: 'Home'
            ),
            NavigationDestination(
              icon: Icon (Icons.map),
              label: 'Map'
            ),
            NavigationDestination(
              icon: Icon (Icons.message),
              label: 'Messages'
            ),
          ],
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          } ,
          selectedIndex: currentPageIndex,
        ),
        body: pages[currentPageIndex],
    );
  }
}