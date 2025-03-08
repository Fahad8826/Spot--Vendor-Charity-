import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spot/vendor/authentication/login.dart';

import 'package:spot/vendor/screens/chatlist.dart';
import 'package:spot/vendor/screens/vendorReport.dart';
import 'package:spot/vendor/screens/vendorcharityRead.dart';
import 'package:spot/vendor/screens/vendorfeedback.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorBottomNavbar extends StatefulWidget {
  const VendorBottomNavbar({super.key});

  @override
  State<VendorBottomNavbar> createState() => _VendorBottomNavbarState();
}

class _VendorBottomNavbarState extends State<VendorBottomNavbar> {
  int indexnum = 0;
  String? currentVendorId;
  String? currentVendorName;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchVendorData();
  }

  Future<void> _fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentVendorId = user.uid;
      });

      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentVendorId)
          .get();

      if (vendorDoc.exists) {
        setState(() {
          currentVendorName = vendorDoc.data()?['name'] ?? 'Vendor';
          currentVendorId = vendorDoc.data()?['vendorId'] ?? 'Vendor';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String vendorEmail = _authService.getCurrentUserEmail();

    List<Widget> tabWidgets = [
      // BarChart(),
      ShopAnalyticsDashboard(),
      CharityRead(),
      // VendorProfilePage(),
      FeedbackPage(vendorEmail: vendorEmail),
      VendorChatListScreen(),
    ];

    return Scaffold(
      body: Container(
        child: Center(child: tabWidgets[indexnum]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.95),
            elevation: 5,
            type: BottomNavigationBarType.fixed,
            currentIndex: indexnum,
            showUnselectedLabels: true,
            selectedLabelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 10),
            onTap: (int index) {
              setState(() {
                indexnum = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home,
                    color:
                        indexnum == 0 ? Color(0xFF053E51) : Color(0xFF2E8B57)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person,
                    color:
                        indexnum == 1 ? Color(0xFF053E51) : Color(0xFF2E8B57)),
                label: "Donations",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feedback,
                    color:
                        indexnum == 2 ? Color(0xFF053E51) : Color(0xFF2E8B57)),
                label: 'Feedback',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat,
                    color:
                        indexnum == 3 ? Color(0xFF053E51) : Color(0xFF2E8B57)),
                label: 'Chat',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void gotologin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

class AuthService {
  String getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }
}
