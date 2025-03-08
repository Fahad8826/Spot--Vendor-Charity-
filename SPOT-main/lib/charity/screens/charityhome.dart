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
        title: const Text('Charity Home'),
      ),
      body: StreamBuilder(
        stream: charityReq.snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot charitySnap = snapshot.data.docs[index];
                if (removedRequests.contains(charitySnap.id)) {
                  return const SizedBox.shrink();
                }
                return FutureBuilder<String>(
                  future: _fetchVendorName(charitySnap['userId']),
                  builder: (context, vendorSnapshot) {
                    String vendorName = vendorSnapshot.data ?? 'Loading...';
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.volunteer_activism,
                                        color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      charitySnap['P_name'],
                                      style: GoogleFonts.roboto(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red, size: 28),
                                  onPressed: () =>
                                      _rejectRequest(charitySnap.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vendor: $vendorName',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              charitySnap['P_description'],
                              style: GoogleFonts.roboto(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Contact Number : ${charitySnap['phone']}',
                              style: GoogleFonts.roboto(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quantity: ${charitySnap['quantity']}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 32),
                                onPressed: () => _acceptRequest(
                                  charitySnap.id,
                                  charitySnap['userId'],
                                  charitySnap['P_name'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
