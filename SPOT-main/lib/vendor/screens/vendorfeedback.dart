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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No feedback available for your shop.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            final feedbackDocs = snapshot.data!.docs;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10, left: 16, right: 16, bottom: 16),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: feedbackDocs.length,
                  itemBuilder: (context, index) {
                    final feedback =
                        feedbackDocs[index].data() as Map<String, dynamic>;
                    final userEmail = feedback['userEmail'] ?? 'Anonymous';
                    final rating = (feedback['rating'] ?? 0.0) is int
                        ? (feedback['rating'] ?? 0.0).toDouble()
                        : feedback['rating'] ?? 0.0;
                    final comment = feedback['comment'] ?? 'No comment';
                    final timestamp = feedback['timestamp'] as Timestamp?;
                    final date = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                            timestamp.millisecondsSinceEpoch)
                        : null;

                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                    child: Text(
                                      userEmail,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF053E51),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(right: 3),
                                      child: FadeIn(
                                        delay: Duration(
                                            milliseconds: 200 + (index * 100)),
                                        child: Icon(
                                          index < rating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(thickness: 1),
                              const SizedBox(height: 8),
                              Text(
                                comment,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
