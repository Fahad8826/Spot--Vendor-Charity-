import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spot/Firbase/auth_service.dart';
import 'package:spot/vendor/authentication/login.dart';
import 'package:google_fonts/google_fonts.dart';

class Charityprofile extends StatefulWidget {
  const Charityprofile({super.key});

  @override
  State<Charityprofile> createState() => _CharityprofileState();
}

class _CharityprofileState extends State<Charityprofile> {
  final _auth = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _emailController;
  late TextEditingController _categoryController;

  File? _image;
  String? _imageUrl;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _emailController = TextEditingController();
    _categoryController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('charity_reg')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _numberController.text = data?['number'] ?? '';
          _emailController.text = data?['email'] ?? '';
          _categoryController.text = data?['category'] ?? '';
          _imageUrl = data?['image'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_image == null) return null;
    setState(() => _isUploadingImage = true);
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/datygsam7/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = 'SpotApplication';
      request.files
          .add(await http.MultipartFile.fromPath('file', _image!.path));

      final response = await request.send();
      setState(() => _isUploadingImage = false);

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final jsonMap = jsonDecode(utf8.decode(responseData));
        return jsonMap['secure_url'] as String;
      } else {
        throw HttpException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _updateUserData() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;
    setState(() => _isSaving = true);

    if (_image != null) {
      _imageUrl = await _uploadToCloudinary();
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final data = {
      'name': _nameController.text,
      'number': _numberController.text,
      'email': _emailController.text,
      'category': _categoryController.text,
      'image': _imageUrl ?? '',
    };

    try {
      await FirebaseFirestore.instance
          .collection('charity_reg')
          .doc(currentUser.uid)
          .set(data, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF2E8B57),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Charity Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF053E51),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E8B57),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF053E51).withOpacity(0.05),
                    Color(0xFF2E8B57).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile header with background
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(
                          children: [
                            // Profile image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _image != null
                                        ? FileImage(_image!)
                                        : (_imageUrl != null &&
                                                _imageUrl!.isNotEmpty
                                            ? NetworkImage(_imageUrl!)
                                            : null) as ImageProvider?,
                                    child: (_image == null &&
                                            (_imageUrl == null ||
                                                _imageUrl!.isEmpty))
                                        ? Icon(Icons.person,
                                            size: 60, color: Color(0xFF053E51))
                                        : null,
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: Color(0xFF2E8B57),
                                          radius: 20,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            onPressed: _pickImage,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              _nameController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              _categoryController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Profile form section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF053E51),
                                ),
                              ),
                              Divider(thickness: 1.5),
                              SizedBox(height: 15),
                              _buildTextField('Organization Name',
                                  Icons.business, _nameController),
                              SizedBox(height: 15),
                              _buildTextField('Email Address', Icons.email,
                                  _emailController),
                              SizedBox(height: 15),
                              _buildTextField('Phone Number', Icons.phone,
                                  _numberController),
                              SizedBox(height: 15),
                              _buildTextField('Category', Icons.category,
                                  _categoryController),
                              SizedBox(height: 25),
                              _isSaving || _isUploadingImage
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2E8B57),
                                      ),
                                    )
                                  : Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (_isEditing) {
                                              await _updateUserData();
                                            }
                                            setState(
                                                () => _isEditing = !_isEditing);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: _isEditing
                                                ? Color(0xFF2E8B57)
                                                : Color(0xFF053E51),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                          ),
                                          child: Text(
                                            _isEditing
                                                ? 'Save Changes'
                                                : 'Edit Profile',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: TextField(
        readOnly: !_isEditing,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Color(0xFF053E51).withOpacity(0.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF2E8B57),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isEditing ? Color(0xFF2E8B57) : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF2E8B57),
              width: 2,
            ),
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF053E51),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: GoogleFonts.poppins(
          fontSize: 15,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              gotologin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF053E51),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void gotologin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }
}
