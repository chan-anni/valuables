import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_page.dart';
import 'package:valuables/pages/profile_page.dart';
import 'package:valuables/pages/history_page.dart';
import 'package:valuables/screens/lost_item_form.dart';
import 'package:valuables/theme_controller.dart';
// Global flag: track if Supabase is initialized
bool _supabaseInitialized = false;
// Theme controller is provided by theme_controller.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env and initialize Supabase in the background (non-blocking).
  await _initializeAsync();

  // Start the UI immediately.
  runApp(MyApp());
}

Future<void> _initializeAsync() async {
  try {
    print('_initializeAsync: loading .env');
    await dotenv.load(fileName: '.env');
    print('_initializeAsync: .env loaded');
  } catch (e) {
    print('_initializeAsync: dotenv.load failed: $e');
  }

  try {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url != null && key != null) {
      print('_initializeAsync: initializing Supabase');
      try {
        // Use a timeout to prevent hanging.
        await Supabase.initialize(url: url, anonKey: key).timeout(const Duration(seconds: 10));
        _supabaseInitialized = true;
        print('_initializeAsync: Supabase initialized successfully');
      } on TimeoutException catch (e) {
        print('_initializeAsync: Supabase.initialize timed out: $e');
        _supabaseInitialized = false;
      }
    } else {
      print('_initializeAsync: Supabase env vars missing; skipping initialize');
    }
  } catch (e) {
    print('_initializeAsync: Supabase.initialize failed: $e');
    _supabaseInitialized = false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepPurple = Color(0xFF5E2B8A);
    const Color goldColor = Color(0xFFFBC02D); // Darker yellow for contrast
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: deepPurple, primary: deepPurple, secondary: goldColor, tertiary: goldColor),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      useMaterial3: true,
    );
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: deepPurple, primary: deepPurple, secondary: goldColor, tertiary: goldColor, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark Gray
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), foregroundColor: Colors.white, elevation: 0),
      useMaterial3: true,
      cardColor: const Color(0xFF1E1E1E),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: const Navigation(),
          routes: {
            '/account': (context) => const ProfilePage(),
            '/history': (context) => const HistoryPage(),
          },
        );
      },
    );
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

  void setPageIndex(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  // pages left->right: Map, Listings, (center FAB), Messages, Account
  late final List<Widget> pages = [
    const MapPage(),
    const HomePage(),
    const SizedBox.shrink(), // placeholder for center FAB
    const MessagePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valuables'),
      ),
      body: pages[currentPageIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Map
              _buildNavItem(
                context,
                icon: Icons.pin_drop_rounded,
                index: 0,
              ),
              // Listings
              _buildNavItem(
                context,
                icon: Icons.format_list_bulleted_rounded,
                index: 1,
              ),
              // Center + Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FloatingActionButton(
                  onPressed: _onCreatePressed,
                  backgroundColor: colorScheme.primary,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, size: 36, color: Colors.white),
                ),
              ),
              // Messages (with badge placeholder)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.chat_bubble_rounded,
                    index: 3,
                    onTap: () {
                      // Auth guard for messages
                      if (Supabase.instance.client.auth.currentUser == null) {
                        _showLoginPrompt();
                      } else {
                        setPageIndex(3);
                      }
                    }
                  ),
                  // unread badge placeholder
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              // Account/Profile
              _buildNavItem(
                context,
                icon: Icons.person_rounded,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required int index, VoidCallback? onTap}) {
    final isSelected = currentPageIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap ?? () => setPageIndex(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.grey[800] : colorScheme.primary.withOpacity(0.15)) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? (isDark ? Colors.grey[300] : colorScheme.primary) : Colors.grey,
        ),
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in required'),
        content: const Text('You must be signed in to access this feature.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { 
              Navigator.pop(context); 
              setPageIndex(4); // Go to profile/login
            }, 
            child: const Text('Sign in')
          ),
        ],
      ),
    );
  }

  void _onCreatePressed() {
    // If user not logged in, prompt to login first
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('What would you like to report?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LostItemForm(forceType: 'lost')));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Text('Report Lost Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LostItemForm(forceType: 'found')));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Text('Report Found Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

// Map page -- needs API key
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

  // Test dummy markers
  final Set<Marker> _markers = <Marker>{
    Marker(
      markerId: MarkerId('1'), 
      position: LatLng(46.65428653800135, -122.30802267054545)
      ),
    Marker(markerId: MarkerId('2'), position: LatLng(48.65428653800135, -122.30802267054545))
  };

  Future<void> _addMarkers() async {
    if (!_supabaseInitialized) return;

    try {
      final data = await Supabase.instance.client.from('items').select();

      for (var item in data) {
        final id = item['id']?.toString() ?? 'unknown';
        final lat = (item['location_lat'] as num?)?.toDouble();
        final lng = (item['location_lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          Marker newMarker = Marker(
            markerId: MarkerId(id),
            position: LatLng(lat, lng),
          );
          _markers.add(newMarker);
        }
      }
    } catch (e) {
      print('Error loading markers: $e');
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
  }
}

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Messages'));
  }
}
