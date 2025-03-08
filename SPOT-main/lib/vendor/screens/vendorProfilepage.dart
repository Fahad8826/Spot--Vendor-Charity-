import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';
import 'package:spot/Firbase/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:spot/charity/screens/charityProfile.dart';
import 'package:spot/vendor/authentication/login.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _emailController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  File? _image;
  String? _imageUrl;

  bool _isEditing = false;
  bool _isSaving = false;
  String _errorMessage = '';

  // Validation patterns

  final _phonePattern = r'^\+?[0-9]{10,12}$';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _emailController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_image == null) return null;

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/datygsam7/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'SpotApplication';
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] as String;
      } else {
        throw HttpException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading image: $e';
      });
      return null;
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (_image != null) {
        _imageUrl = await _uploadToCloudinary();
        if (_imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      final data = {
        'name': _nameController.text.trim(),
        'phone': _numberController.text.trim(),
        'email': _emailController.text.trim(),
        'category': _categoryController.text.trim(),
        'Description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'image': _imageUrl ?? '',
      };

      await FirebaseFirestore.instance
          .collection('vendor_reg')
          .doc(currentUser.uid)
          .set(data, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Update failed: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('vendor_reg')
          .doc(currentUser.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('User document does not exist');
      }

      return docSnapshot.data() ?? {};
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: ${e.toString()}';
      });
      return {};
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                gotologin(context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void gotologin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: Icon(Icons.logout))
        ],
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage.isNotEmpty
                            ? _errorMessage
                            : 'Unable to load user data'),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final user = snapshot.data!;
                if (!_isEditing) {
                  _nameController.text = user['name'] ?? '';
                  _numberController.text = user['phone'] ?? '';
                  _emailController.text = user['email'] ?? '';
                  _categoryController.text = user['category'] ?? '';
                  _descriptionController.text = user['Description'] ?? '';
                  _locationController.text = user['location'] ?? '';
                  _imageUrl = user['image'] ?? '';
                }

                return _buildProfileContent(user);
              },
            ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> user) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Image Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty
                              ? Image.network(_imageUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                )),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Form Fields Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Shop Name',
                    icon: Icons.storefront,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop name is required';
                      }
                      if (value.length < 3) {
                        return 'Shop name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      String pattern = r'^[a-zA-Z0-9._%+-]{1,30}@gmail\.com$';
                      RegExp regex = RegExp(pattern);
                      if (!regex.hasMatch(value)) {
                        return 'Please enter a valid @gmail.com email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _numberController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(_phonePattern).hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _categoryController,
                    label: 'Business Category',
                    icon: Icons.category_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Business category is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _descriptionController,
                    label: 'Business Description',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      if (value.length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _locationController,
                    label: 'Business Location',
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: _isEditing
              ? [Colors.green.shade400, Colors.green.shade600]
              : [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isEditing ? Colors.green : Theme.of(context).primaryColor)
                .withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isEditing
            ? _updateUserData
            : () => setState(() => _isEditing = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(_isEditing ? 'Save Changes' : 'Edit Profile',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 17)),
          ],
        ),
      ),
    );
  }
}
