import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CharityHome extends StatefulWidget {
  const CharityHome({super.key});

  @override
  State<CharityHome> createState() => _CharityHomeState();
}

class _CharityHomeState extends State<CharityHome> {
  List<String> removedRequests = [];

  @override
  void initState() {
    super.initState();
    _checkRoleAndSetupNotifications();
  }

  Future<void> _checkRoleAndSetupNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('CV_users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == 'charity') {
        _listenForCharityRequests();
      }
    }
  }

  void _listenForCharityRequests() {
    FirebaseFirestore.instance
        .collection('Charity_req')
        .where('notification_flag', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('CV_users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == 'charity') {
        for (var doc in snapshot.docs) {
          _triggerNotification(doc['P_name']);
          await FirebaseFirestore.instance
              .collection('Charity_req')
              .doc(doc.id)
              .update({'notification_flag': false});
        }
      }
    });
  }

  void _triggerNotification(String productName) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'spot',
        title: 'New Donation Request',
        body: 'You have a donation request for $productName',
      ),
    );
  }

  Future<String> _fetchVendorName(String vendorId) async {
    final vendorDoc = await FirebaseFirestore.instance
        .collection('CV_users')
        .doc(vendorId)
        .get();
    return vendorDoc['name'];
  }

  void _acceptRequest(String docId, String vendorId, String productName) async {
    final vendorName = await _fetchVendorName(vendorId);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 20,
        channelKey: 'spot',
        title: 'Request Accepted',
        body: 'Your donation request for $productName has been accepted.',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Donation request from $vendorName accepted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      removedRequests.add(docId);
    });
  }

  void _rejectRequest(String docId) {
    setState(() {
      removedRequests.add(docId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation request removed from your list.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference charityReq =
        FirebaseFirestore.instance.collection('Charity_req');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donation Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder(
          stream: charityReq.snapshots(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E8B57),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading requests',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Color(0xFF053E51).withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No donation requests yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF053E51),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter out removed requests
            final visibleDocs = snapshot.data!.docs
                .where((doc) => !removedRequests.contains(doc.id))
                .toList();

            if (visibleDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Color(0xFF2E8B57).withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'All requests processed!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: visibleDocs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot charitySnap = visibleDocs[index];
                return FutureBuilder<String>(
                  future: _fetchVendorName(charitySnap['userId']),
                  builder: (context, vendorSnapshot) {
                    String vendorName = vendorSnapshot.data ?? 'Loading...';
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.white, Color(0xFFE8F5E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF2E8B57)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.volunteer_activism,
                                            color: Color(0xFF2E8B57),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            charitySnap['P_name'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF053E51),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _rejectRequest(charitySnap.id),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.store, 'Vendor', vendorName,
                                  Color(0xFF053E51)),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.description, 'Description',
                                  charitySnap['P_description'], Colors.black87),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.phone, 'Contact',
                                  charitySnap['phone'], Colors.black87),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  Icons.shopping_basket,
                                  'Quantity',
                                  charitySnap['quantity'].toString(),
                                  Colors.black87),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _acceptRequest(
                                    charitySnap.id,
                                    charitySnap['userId'],
                                    charitySnap['P_name'],
                                  ),
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.white),
                                  label: Text(
                                    'Accept Request',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF2E8B57),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
