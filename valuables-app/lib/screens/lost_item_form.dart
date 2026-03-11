import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'map_picker_screen.dart';

class LostItemForm extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final String? forceType;
  final bool testMode;
  
  const LostItemForm({super.key, this.supabaseClient, this.forceType, this.testMode = false});

  @override
  State<LostItemForm> createState() => _LostItemFormState();
}

class _LostItemFormState extends State<LostItemForm> {
  SupabaseClient? _supabase;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentLocationNameController = TextEditingController();

  // Form values
  String _selectedType = 'lost';
  String? _selectedCategory;
  File? _imageFile;
  File? _imageFile2;
  String? _imageUrl;
  DateTime? _dateFound;
  DateTime? _dateLost;
  bool _isLoading = false;
  
  // Where the item was lost/found (map pin)
  double? _locationLat;
  double? _locationLng;
  String? _locationName;

  final List<String> _categories = [
    'Phones',
    'Laptops',
    'Clothing',
    'Accessories',
    'Keys',
    'Bags',
    'Wallets',
    'Misc. Electronics',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient;
    if (widget.forceType != null) {
      _selectedType = widget.forceType!;
    }
    _supabase = widget.supabaseClient ?? (widget.testMode ? null : Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isLost = _selectedType == 'lost';
    final themeColor = isLost ? primaryColor : secondaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[800] : Colors.grey[200];

    // Dynamic labels based on type
    final mapLocationLabel = isLost ? 'Last Seen Location *' : 'Location Found *';
    final mapLocationHint = isLost ? 'Tap to mark where it was last seen' : 'Tap to mark where you found it';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Type selector
                  if (widget.forceType == null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Item Type',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'lost',
                                  label: Text('Lost'),
                                  icon: Icon(Icons.help_outline),
                                ),
                                ButtonSegment(
                                  value: 'found',
                                  label: Text('Found'),
                                  icon: Icon(Icons.location_on),
                                ),
                              ],
                              selected: {_selectedType},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _selectedType = newSelection.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.forceType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'Reporting ${widget.forceType == 'lost' ? 'Lost' : 'Found'} Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Item Title *',
                      hintText: 'e.g., Black iPhone 14 Pro',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: cardColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a title';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category),
                      filled: true,
                      fillColor: cardColor,
                    ),
                    initialValue: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    validator: (value) {
                      if (value == null) return 'Please select a category';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Provide detailed information...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: cardColor,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a description';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  !isLost?// Current Item Location (optional, text only)
                  TextFormField(
                    controller: _currentLocationNameController,
                    decoration: InputDecoration(
                      labelText: 'Current Item Location - Optional',
                      hintText: 'e.g., University Lost and Found, Room 204',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.store_mall_directory),
                      filled: true,
                      fillColor: cardColor,
                    ),
                  )
                  : const SizedBox.shrink(),

                  const SizedBox(height: 16),
                  
                  // Date picker
                  Card(
                    color: cardColor,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(isLost ? 'Date Lost *' : 'Date Found *'),
                      subtitle: Text(
                        _dateLost != null || _dateFound != null
                            ? DateFormat('MMMM dd, yyyy').format(
                                isLost ? _dateLost! : _dateFound!)
                            : 'Tap to select date',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickDate,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Map location picker — identical style to other cards
                  Card(
                    color: cardColor,
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(mapLocationLabel),
                      subtitle: Text(_locationName ?? mapLocationHint),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickLocation,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Photo 1 — required for Found, optional for Lost
                  Card(
                    color: cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: Text(isLost ? 'Photo 1' : 'Photo 1 *'),
                          subtitle: Text(_imageFile != null
                              ? 'Photo selected'
                              : isLost ? 'Optional - tap to add' : 'Required - tap to add'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _pickImage(slot: 1),
                        ),
                        if (_imageFile != null) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => setState(() {
                                      _imageFile = null;
                                      _imageFile2 = null;
                                    }),
                                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Photo 2 — optional, only for Found, only shown after Photo 1 is set
                  if (!isLost && _imageFile != null)
                    Card(
                      color: cardColor,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.add_a_photo),
                            title: const Text('Photo 2'),
                            subtitle: Text(_imageFile2 != null
                                ? 'Photo selected'
                                : 'Optional - tap to add'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _pickImage(slot: 2),
                          ),
                          if (_imageFile2 != null) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _imageFile2!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => setState(() => _imageFile2 = null),
                                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  FilledButton(
                    onPressed: _submitForm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: themeColor,
                    ),
                    child: Text(
                      'Submit Report',
                      style: TextStyle(fontSize: 18, color: isLost ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      if (!mounted) return;
      setState(() {
        if (_selectedType == 'lost') {
          _dateLost = date;
        } else {
          _dateFound = date;
        }
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLat: _locationLat,
          initialLng: _locationLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _locationLat = result.lat;
        _locationLng = result.lng;
        _locationName = result.locationName;
      });
    }
  }

  Future<void> _pickImage({required int slot}) async {
    final picker = ImagePicker();

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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          if (slot == 1) {
            _imageFile = File(pickedFile.path);
          } else {
            _imageFile2 = File(pickedFile.path);
          }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile, String fileName) async {
    if (_supabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to database'), backgroundColor: Colors.red),
      );
      return null;
    }
    
    try {
      final path = 'items/$fileName';
      await _supabase!.storage.from('items').upload(path, imageFile);
      return _supabase!.storage.from('items').getPublicUrl(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check date
    if ((_selectedType == 'lost' && _dateLost == null) ||
        (_selectedType == 'found' && _dateFound == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
      }
      return;
    }

    // Enforce map location required
    if (_locationLat == null || _locationLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedType == 'lost'
                  ? 'Please mark where the item was last seen'
                  : 'Please mark where you found the item',
            ),
          ),
        );
      }
      return;
    }

    // Photo 1 required only for Found items
    if (_selectedType == 'found' && _imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one photo for found items')),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_supabase == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item reported successfully! (Test mode)'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      final user = _supabase!.auth.currentUser;
      final userId = user?.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload Photo 1 if provided
      if (_imageFile != null) {
        _imageUrl = await _uploadImage(_imageFile!, '$timestamp-1.jpg');
      }

      // Upload Photo 2 if provided — stored as pipe-separated value in image_url
      // since the schema has a single image_url column
      String? imageUrl2;
      if (_imageFile2 != null) {
        imageUrl2 = await _uploadImage(_imageFile2!, '$timestamp-2.jpg');
      }

      final currentLocationName = _currentLocationNameController.text.trim();

      final data = {
        'user_id': userId,
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        // Where it was lost/found
        'location_lat': _locationLat,
        'location_lng': _locationLng,
        'location_name': _locationName,
        // Where the item currently is
        'current_location_name': currentLocationName.isEmpty ? null : currentLocationName,
        'current_location_lat': null,
        'current_location_lng': null,
        // Photo 1 URL; Photo 2 appended with | separator if present
        'image_url': imageUrl2 != null
            ? '${_imageUrl ?? ''}|$imageUrl2'
            : _imageUrl,
        'date_lost': _selectedType == 'lost' ? _dateLost?.toIso8601String() : null,
        'date_found': _selectedType == 'found' ? _dateFound?.toIso8601String() : null,
        'status': 'active',
      };

      await _supabase!.from('items').insert(data).select();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item reported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _currentLocationNameController.dispose();
    super.dispose();
  }
}