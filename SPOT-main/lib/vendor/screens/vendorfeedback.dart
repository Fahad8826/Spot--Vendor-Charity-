import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class FeedbackPage extends StatelessWidget {
  final String vendorEmail;

  const FeedbackPage({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feedback',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feedback')
              .where('vendorId', isEqualTo: vendorEmail)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No feedback available for your shop.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final feedbackDocs = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 90),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: feedbackDocs.length,
                itemBuilder: (context, index) {
                  final feedback =
                      feedbackDocs[index].data() as Map<String, dynamic>;
                  final userEmail = feedback['userEmail'] ?? 'Anonymous';
                  final rating = feedback['rating'] ?? 0.0;
                  final comment = feedback['comment'] ?? 'No comment';

                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User: $userEmail',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(
                                  rating.round(),
                                  (index) => BounceInDown(
                                    delay: Duration(
                                        milliseconds: 200 + (index * 100)),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                            Text(
                              'Comment: $comment',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
