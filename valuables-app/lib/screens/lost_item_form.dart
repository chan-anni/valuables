import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'map_picker_screen.dart';

class LostItemForm extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  
  const LostItemForm({super.key, this.supabaseClient});

  @override
  State<LostItemForm> createState() => _LostItemFormState();
}

class _LostItemFormState extends State<LostItemForm> {
  SupabaseClient? _supabase;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form values
  String _selectedType = 'lost';
  String? _selectedCategory;
  File? _imageFile;
  String? _imageUrl;
  DateTime? _dateFound;
  DateTime? _dateLost;
  bool _isLoading = false;
  
  // Location values
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
    // Initialize Supabase client - can be injected for testing
        _supabase = widget.supabaseClient ?? Supabase.instance.client;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Item Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'lost',
                                label: Text('Lost'),
                                icon: Icon(Icons.search),
                              ),
                              ButtonSegment(
                                value: 'found',
                                label: Text('Found'),
                                icon: Icon(Icons.check_circle),
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
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Item Title *',
                      hintText: 'e.g., Black iPhone 14 Pro',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    initialValue: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Provide detailed information...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_selectedType == 'lost' ? 'Date Lost *' : 'Date Found *'),
                      subtitle: Text(
                        _dateLost != null || _dateFound != null
                            ? DateFormat('MMMM dd, yyyy').format(
                                _selectedType == 'lost' ? _dateLost! : _dateFound!)
                            : 'Tap to select date',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickDate,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Location'),
                      subtitle: Text(
                        _locationName ?? 'Tap to select on map',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickLocation,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Image upload
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Add Photo'),
                          subtitle: Text(_imageFile != null 
                              ? 'Photo selected' 
                              : 'Optional'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _pickImage,
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
                                    onPressed: () {
                                      setState(() {
                                        _imageFile = null;
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
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
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Submit Report',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show options: Camera or Gallery
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
    
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_supabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to database'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'items/$fileName';
      
      await _supabase!.storage.from('items').upload(path, _imageFile!);
      
      final imageUrl = _supabase!.storage.from('items').getPublicUrl(path);
      
      return imageUrl;
    } catch (e) {
      // return a snackbar error message instead of returning null
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check date
    if ((_selectedType == 'lost' && _dateLost == null) ||
        (_selectedType == 'found' && _dateFound == null)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Skip Supabase operations if no client is provided (testing mode)
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
      
      // For now, use a test user ID if no user is logged in
      // TODO: Implement proper authentication
      final userId = user?.id;
      
      // Upload image if selected
      if (_imageFile != null) {
        _imageUrl = await _uploadImage();
      }
      
      final data = {
        'user_id': userId,
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'location_lat': _locationLat,
        'location_lng': _locationLng,
        'location_name': _locationName,
        'image_url': _imageUrl,
        'date_lost': _selectedType == 'lost'
            ? _dateLost?.toIso8601String()
            : null,
        'date_found': _selectedType == 'found'
            ? _dateFound?.toIso8601String()
            : null,
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
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
