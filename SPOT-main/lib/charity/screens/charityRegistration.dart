import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:spot/charity/Navbar/charitybottomnavigation.dart';

class CharityRegistration extends StatefulWidget {
  const CharityRegistration({super.key});

  @override
  State<CharityRegistration> createState() => _CharityRegistrationState();
}

class _CharityRegistrationState extends State<CharityRegistration> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _categoryController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;

  // Function to upload image to Cloudinary
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  // Function to pick an image from gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Form Validation
  bool _validateForm() {
    return _formKey.currentState!.validate();
  }

  // Save data to Firestore
  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in to save your profile")));
      return;
    }

    String? imageUrl = await _uploadToCloudinary();
    if (imageUrl == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to upload image")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('charity_reg')
          .doc(user.uid)
          .set({
        'name': _usernameController.text,
        'number': _numberController.text,
        'email': _emailController.text,
        'category': _categoryController.text,
        'image': imageUrl,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Profile saved successfully!")));
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => CharityBottomNav()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registration',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.grey.shade600)
                          : null,
                    ),
                  ),
                ),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                          _usernameController, 'Username', Icons.person),
                      _buildTextField(_emailController, 'Email', Icons.email,
                          isEmail: true),
                      _buildTextField(
                          _numberController, 'Phone Number', Icons.phone,
                          isPhone: true),
                      _buildTextField(
                          _categoryController, 'Category', Icons.category),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Register',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Widget for TextField
  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          hintText: hint,
          prefixIcon: Icon(icon),
          hintStyle: GoogleFonts.poppins(),
        ),
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $hint';
          if (isEmail &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
            return 'Enter a valid email';
          if (isPhone && !RegExp(r'^\d{10}$').hasMatch(value))
            return 'Enter a valid 10-digit phone number';
          return null;
        },
      ),
    );
  }
}
