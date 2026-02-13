import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_gate.dart';

void main() async {
  // Supabase Setup
  await Supabase.initialize(
    anonKey: "sb_publishable_sbp4gelcpvGhbYNg6i6kqQ_hyht0uCc",
    url: "https://zhurzsbvxcsaexcbqown.supabase.co",
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthGate());
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

// Stores and navigates through the different pages with a Widget array.
final pages = const <Widget>[HomePage(), MapPage(), MessagePage()];

// Each page has their own build function to make things simple
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userId;

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(_userId ?? "Not signed it"),
            ElevatedButton(
              onPressed: () async {
                const webClientId =
                    '398491837853-hvd35lt2rgjb0g4ui20ft8kqg0oa4bmm.apps.googleusercontent.com';

                const iosClientId =
                    '398491837853-k279v0djfia5g0s9itnnnbumo2a24aab.apps.googleusercontent.com';

                // Google sign in on Android will work without providing the Android
                // Client ID registered on Google Cloud.

                final GoogleSignIn signIn = GoogleSignIn.instance;

                // At the start of your app, initialize the GoogleSignIn instance
                unawaited(
                  signIn.initialize(
                    clientId: iosClientId,
                    serverClientId: webClientId,
                  ),
                );

                // Perform the sign in
                final googleAccount = await signIn.authenticate();
                final googleAuthorization = await googleAccount
                    .authorizationClient
                    .authorizationForScopes([]);
                final googleAuthentication = googleAccount!.authentication;
                final idToken = googleAuthentication.idToken;
                final accessToken = googleAuthorization?.accessToken;

                if (idToken == null) {
                  throw 'No ID Token found.';
                }

                await supabase.auth.signInWithIdToken(
                  provider: OAuthProvider.google,
                  idToken: idToken,
                  accessToken: accessToken,
                );
              },
              child: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

// Map needs API key
class _MapPageState extends State<MapPage> {
  //final Completer<GoogleMapsController> _controller = Completer<GoogleMapsController>();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Map'));
    /* return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    ); */
  }
}

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Messages'));
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
        title: const Text('Valuables', style: TextStyle(color: Colors.white)),
      ),

      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
      ),
      body: pages[currentPageIndex],
    );
  }
}
