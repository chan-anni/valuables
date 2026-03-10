import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/theme_controller.dart';
import 'package:valuables/pages/history_page.dart';
import 'package:valuables/screens/home_page.dart';

import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:valuables/screens/map_page.dart';

final _supabase = Supabase.instance.client;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  late final StreamSubscription<AuthState> _authSubscription;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isLoggedIn = _supabase.auth.currentUser != null;
    
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final bool loggedIn = data.session != null;
      if (loggedIn != _isLoggedIn) {
        if (mounted) {
          setState(() {
            _isLoggedIn = loggedIn;
          });
          if (!loggedIn) {
            // Switch to the first tab (Sign In) if logged out
            _tabController.animateTo(0);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: _isLoggedIn ? 'Account Info' : 'Sign In'),
              const Tab(text: 'Settings'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _isLoggedIn ? const _AccountInfoTab() : const _LoginSignUpTab(),
            _SettingsTab(),
          ],
        ),
    );
  }
}

class _AccountInfoTab extends StatefulWidget {
  const _AccountInfoTab();

  @override
  State<_AccountInfoTab> createState() => _AccountInfoTabState();
}

class _AccountInfoTabState extends State<_AccountInfoTab> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  bool _isEditing = false;
  bool _isLoading = false;
  List<dynamic> _userItems = [];
  List<dynamic> _alertItems = [];
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _nameController = TextEditingController(
      text: user?.userMetadata?['name'] ?? '',
    );
    _usernameController = TextEditingController(
      text: user?.userMetadata?['username'] ?? '',
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return;

  try {
    // Fetch user listings
    final items = await _supabase
        .from('items')
        .select()
        .eq('user_id', userId)
        .neq('status', 'claimed')
        .order('created_at', ascending: false);

    // Fetch notifications from the specific notifications table
    final notificationData = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false) // Only show active matches
        .order('created_at', ascending: false)
        .limit(20);

    if (mounted) {
      setState(() {
        _userItems = items;
        _alertItems = notificationData;
      });
    }
  } catch (e) {
    debugPrint('Error loading profile data: $e');
  }
}

  Future<void> _onClaimItem(dynamic item) async {
    final itemId = item['id'].toString();
    final rawType = item['type'] ?? item['item_type'];
    final isLost = rawType?.toString().toLowerCase() == 'lost';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLost ? 'Remove Listing' : 'Claim Item'),
        content: Text(isLost 
            ? 'Are you sure you want to remove this listing? This implies you have found the item.' 
            : 'Are you sure you want to mark this item as claimed? This implies the owner has received the item.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isLost ? 'Remove' : 'Claimed')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('items').update({'status': 'claimed'}).eq('id', itemId);
        await _supabase
          .from('notifications')
          .delete()
          .contains('data', {'found_item_id': itemId});
          await _supabase
          .from('notifications')
          .delete()
          .contains('data', {'lost_item_id': itemId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item marked as claimed')));
          _loadUserData(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error claiming item: $e')));
        }
      }
    }
  }

  Future<void> _dismissNotification(int index) async {
    final notifId = _alertItems[index]['id'];
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);

      if (!mounted) return;
      setState(() {
        _alertItems.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _viewAlertItem(int index) async {
    final notif = _alertItems[index];
    final data = notif['data'] as Map<String, dynamic>? ?? {};
    
    // Extract data needed for MapPage
    final foundItemId = data['found_item_id'];
    final lat = (data['found_lat'] as num?)?.toDouble();
    final lng = (data['found_lng'] as num?)?.toDouble();

    if (foundItemId == null || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item location data is missing.')),
      );
      return;
    }

    // Navigate to MapPage using your existing notification parameters
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          notifItemLat: lat,
          notifItemLng: lng,
          notifItemId: foundItemId.toString(),
          fromNotification: true, // This ensures the back button shows up
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // NOTE: Ensure NSCameraUsageDescription and NSPhotoLibraryUsageDescription are in Info.plist
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String message = 'Error picking image: ${e.message}';
        if (e.code == 'camera_access_denied') {
          message = 'Camera access denied. Please enable it in settings.';
        } else if (e.code == 'source_not_available') {
          message = 'Camera not available on this device/simulator.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      String? avatarUrl;
      if (_imageFile != null) {
        final userId = _supabase.auth.currentUser!.id;
        final path = 'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('items').upload(path, _imageFile!);
        avatarUrl = _supabase.storage.from('items').getPublicUrl(path);
      }

      final Map<String, dynamic> updates = {
        'name': _nameController.text,
        'username': _usernameController.text,
      };
      
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user.userMetadata!['avatar_url'] as String)
                            : null) as ImageProvider?,
                    child: (_imageFile == null && user.userMetadata?['avatar_url'] == null)
                        ? Text(
                            ((user.userMetadata?['name'] as String?) ?? 'U')[0]
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : primaryColor,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: Text(user.userMetadata?['name'] as String? ?? 'No Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Center(child: Text('@${user.userMetadata?['username'] as String? ?? 'username'}', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[300] : Colors.grey[800]))),
                  const SizedBox(height: 4),
                  Center(child: Text(user.email ?? '', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[800]))),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : primaryColor,
                        side: BorderSide(color: isDark ? Colors.white : primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() {
                            _isEditing = false;
                            _imageFile = null;
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 32),
            
            // My Listings Section
            if (!_isEditing) ...[
              Text(
                'My Active Listings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              if (_userItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, size: 40, color: isDark ? Colors.grey[600] : Colors.grey),
                      SizedBox(height: 8),
                      Text('No active listings', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userItems.length,
                  itemBuilder: (context, index) {
                    final item = _userItems[index];
                    return ItemCard(
                      item: item,
                      onClaim: () => _onClaimItem(item),
                    );
                  },
                ),
            ],

            const SizedBox(height: 32),

            // Alerts Section (Moved below listings)
            if (!_isEditing) ...[
              Text(
                'Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              if (_alertItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 40, color: isDark ? Colors.grey[600] : Colors.grey),
                      SizedBox(height: 8),
                      Text('No potential matches', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black)),
                    ],
                  ),
                )
              else
                ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alertItems.length,
                itemBuilder: (context, index) {
                  final notif = _alertItems[index];
                  return _NotificationCard(
                    title: notif['title'] ?? 'Potential Match',
                    body: notif['body'] ?? 'An item was found near your location.',
                    onDismiss: () => _dismissNotification(index),
                    onClaim: () => _viewAlertItem(index),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback onClaim;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.announcement_rounded, size: 18, color: secondaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(width: 14),
          Row(
            children: [
              // Main Action
              Expanded(
                child: FilledButton.icon(
                  onPressed: onClaim,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('View on Map'),
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Secondary Action
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color.fromARGB(255, 58, 58, 58) : Colors.grey[100],
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginSignUpTab extends StatefulWidget {
  const _LoginSignUpTab();

  @override
  State<_LoginSignUpTab> createState() => _LoginSignUpTabState();
}

class _LoginSignUpTabState extends State<_LoginSignUpTab> {
  @override
  Widget build(BuildContext context) {
    return const _LoginForm();
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GetIt.I<AuthService>().signInWithGoogle();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $err")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign In With Google'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Sign Up')),
                        body: const _SignUpForm(),
                      ),
                    ),
                  );
                },
                child: Text("Don't have an account? Sign Up", style: TextStyle(color: isDark ? Colors.white : null)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'name': _nameController.text,
          'username': _usernameController.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful! Please verify your email.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign up error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: isDark ? Colors.white : Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notificationsEnabled = true;
  bool _privacyEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Notifications Enabled'),
              value: _notificationsEnabled,
              onChanged: (value) =>
                  setState(() => _notificationsEnabled = value),
            ),
            const SizedBox(height: 24),
            const Text(
              'Privacy & Terms',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Privacy Policy Agreed'),
              value: _privacyEnabled,
              onChanged: (value) => setState(() => _privacyEnabled = value),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Appearance'),
              subtitle: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => Text(mode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
              ),
              trailing: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (value) => themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'App Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('App Version'), Text('1.0.0', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black))],
              ),
            ),
            const SizedBox(height: 24),
            if (user != null)
            Center(
              child: TextButton(
                onPressed: () async {
                  await _supabase.auth.signOut();
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
