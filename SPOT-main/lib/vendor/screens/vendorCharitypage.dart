import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:spot/vendor/Navbar/vendorbottomnavigation.dart';

class VendorCharityPage extends StatefulWidget {
  const VendorCharityPage({super.key});

  @override
  _VendorCharityPageState createState() => _VendorCharityPageState();
}

class _VendorCharityPageState extends State<VendorCharityPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final requestData = {
        'P_name': _productNameController.text,
        'P_description': _productDescriptionController.text,
        'quantity': _quantityController.text,
        'phone': _phoneController.text,
        'timestamp': Timestamp.now(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'notification_flag': true, // To trigger the notification
      };

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VendorBottomNavbar(),
          ));

      // Add the request to Firestore
      await FirebaseFirestore.instance
          .collection('Charity_req')
          .add(requestData);

      // Show local confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation request submitted successfully!')),
      );

      _clearForm();
    }
  }

  void _clearForm() {
    _productNameController.clear();
    _productDescriptionController.clear();
    _quantityController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Charity Form',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _productNameController,
                label: 'Product Name',
                icon: Icons.card_giftcard,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _productDescriptionController,
                label: 'Product Description',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number';
                  }

                  if (value.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Submit Donation Request',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _quantityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    validator: validator,
  );
}
