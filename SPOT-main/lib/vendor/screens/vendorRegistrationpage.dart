import 'dart:convert';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spot/vendor/Navbar/vendorbottomnavigation.dart';
import 'dart:async';

class VendorRegistrationpage extends StatefulWidget {
  const VendorRegistrationpage({super.key});

  @override
  State<VendorRegistrationpage> createState() => _VendorRegistrationpageState();
}

class _VendorRegistrationpageState extends State<VendorRegistrationpage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _image;
  LatLng selectedLocation = LatLng(10.7676, 76.6614); // Default Location
  Timer? _debounce;
  final String nominatimApiUrl = "https://nominatim.openstreetmap.org/search";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final response =
          await http.get(Uri.parse("$nominatimApiUrl?q=$query&format=json"));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            selectedLocation = LatLng(
              double.parse(data[0]['lat']),
              double.parse(data[0]['lon']),
            );
          });
        }
      } else {
        debugPrint('Error searching location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
    }
  }

  Future<void> _selectLocation() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchLocation(_searchController.text),
                    ),
                  ),
                  onChanged: (query) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _searchLocation(query);
                    });
                  },
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    center: selectedLocation,
                    zoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        selectedLocation = point;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: selectedLocation,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Widget _buildTextFormField(TextEditingController controller, String hintText,
      TextInputType inputType,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $hintText';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shop Registration',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          spreadRadius: 2,
                          offset: const Offset(2, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? Icon(Icons.camera_alt,
                                  size: 30, color: Colors.grey.shade600)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Upload Shop Image',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildTextFormField(
                  _nameController,
                  'Shop Name',
                  TextInputType.text,
                ),
                _buildTextFormField(
                  _emailController,
                  'Email',
                  TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    String pattern = r'^[a-zA-Z0-9._%+-]{1,30}@gmail\.com$';
                    RegExp regex = RegExp(pattern);
                    if (!regex.hasMatch(value)) {
                      return 'Enter a valid @gmail.com email (1 to 30 characters before @)';
                    }
                    return null;
                  },
                ),
                _buildTextFormField(
                  _numberController,
                  'Phone Number',
                  TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter Phone Number';
                    if (value.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                _buildTextFormField(
                  _categoryController,
                  'Category',
                  TextInputType.text,
                ),
                _buildTextFormField(
                  _locationController,
                  'Address',
                  TextInputType.text,
                ),
                _buildTextFormField(
                  _descriptionController,
                  'Description',
                  TextInputType.multiline,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Selected Location:",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Latitude: ${selectedLocation.latitude}, Longitude: ${selectedLocation.longitude}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _selectLocation,
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text('Select Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please log in to save your profile"),
                          ),
                        );
                        return;
                      }

                      String? imageUrl = await _uploadToCloudinary();
                      if (imageUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to upload image"),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('vendor_reg')
                            .doc(user.uid)
                            .set({
                          'name': _nameController.text.trim(),
                          'phone': _numberController.text.trim(),
                          'email': _emailController.text.trim(),
                          'category': _categoryController.text.trim(),
                          'Description': _descriptionController.text.trim(),
                          'location': _locationController.text.trim(),
                          'image': imageUrl,
                          'latitude': selectedLocation.latitude,
                          'longitude': selectedLocation.longitude,
                          'timestamp': FieldValue.serverTimestamp(),
                          'vendorId': FirebaseAuth.instance.currentUser?.uid,
                        }, SetOptions(merge: true));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile saved successfully!"),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => VendorBottomNavbar()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to save profile: $e"),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Shop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
