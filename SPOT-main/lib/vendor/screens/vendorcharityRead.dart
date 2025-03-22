import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spot/vendor/screens/vendorCharitypage.dart';

class CharityRead extends StatefulWidget {
  const CharityRead({super.key});

  @override
  State<CharityRead> createState() => _CharityReadState();
}

class _CharityReadState extends State<CharityRead> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final Query charityReq = FirebaseFirestore.instance
        .collection('Charity_req')
        .where('userId', isEqualTo: currentUser?.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: currentUser == null
            ? const Center(
                child: Text(
                  'Please login to view your requests',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : StreamBuilder(
                stream: charityReq.snapshots(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'Error: ${snapshot.error.toString()}',
                      style: const TextStyle(color: Colors.white),
                    ));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text(
                      'You have no charity requests',
                      style: TextStyle(color: Colors.white),
                    ));
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot charitySnap =
                            snapshot.data.docs[index];
                        final String docId = charitySnap.id;

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Delete Button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red.shade600,
                                      size: 24,
                                    ),
                                    onPressed: () => _confirmDelete(docId),
                                  ),
                                ),

                                // Card Content
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title Row
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF053E51)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.volunteer_activism,
                                              color: Color(0xFF053E51),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              charitySnap['P_name'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF053E51),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Description
                                      Text(
                                        charitySnap['P_description'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          height: 1.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 16),

                                      // Info Row
                                      Row(
                                        children: [
                                          // Contact Info
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  color: Colors.blue.shade700,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    charitySnap['phone'],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.blue.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 16),

                                          // Quantity Info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.inventory_2,
                                                color: Colors.green.shade700,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${charitySnap['quantity']} items',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorCharityPage(),
            ),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF2E8B57)),
      ),
    );
  }

  // Function to create a gradient button
  Widget _gradientButton(
      String text, Color startColor, Color endColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this request?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            _gradientButton("Delete", Colors.red, Colors.pinkAccent, () {
              _deleteRequest(docId);
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
  }

  void _deleteRequest(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Charity_req')
          .doc(docId)
          .get();

      if (doc.exists && doc.get('userId') == currentUser?.uid) {
        await FirebaseFirestore.instance
            .collection('Charity_req')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request deleted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('You do not have permission to delete this request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete request. Please try again.')),
        );
      }
    }
  }
}
