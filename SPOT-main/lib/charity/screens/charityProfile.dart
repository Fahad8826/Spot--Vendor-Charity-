import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spot/Firbase/auth_service.dart';
import 'package:spot/vendor/authentication/login.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _emailController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    super.dispose();
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

    await FirebaseFirestore.instance
        .collection('CV_users')
        .doc(currentUser.uid)
        .set(data, SetOptions(merge: true));

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_sharp),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? NetworkImage(_imageUrl!)
                          : null) as ImageProvider?,
                  child: (_image == null &&
                          (_imageUrl == null || _imageUrl!.isEmpty))
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField('Username', Icons.person, _nameController),
            const SizedBox(height: 15),
            _buildTextField('Email', Icons.email, _emailController),
            const SizedBox(height: 15),
            _buildTextField('Phone', Icons.phone, _numberController),
            const SizedBox(height: 15),
            _buildTextField('Category', Icons.category, _categoryController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving || _isUploadingImage
                  ? null
                  : () async {
                      setState(() => _isEditing = !_isEditing);
                      if (!_isEditing) await _updateUserData();
                    },
              child: _isEditing ? const Text('Save') : const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller) {
    return TextField(
      readOnly: !_isEditing,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              gotologin(context);
            },
            child: const Text('Yes'),
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
