import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:spot/vendor/screens/chatscreen.dart';
import 'package:intl/intl.dart';

class VendorChatListScreen extends StatelessWidget {
  const VendorChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentVendorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Chats',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
              .collection('chat_rooms')
              .where('participants', arrayContains: currentVendorId)
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final chatRooms = snapshot.data?.docs ?? [];

            if (chatRooms.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No messages yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10, left: 16, right: 16, bottom: 16),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom =
                        chatRooms[index].data() as Map<String, dynamic>;
                    final participantDetails =
                        chatRoom['participantDetails'] as Map<String, dynamic>;

                    // Extract customer ID
                    final participants = chatRoom['participants'] as List;
                    final customerId = participants.firstWhere(
                        (id) => id != currentVendorId,
                        orElse: () => '');

                    if (customerId.isEmpty ||
                        !participantDetails.containsKey(customerId)) {
                      return const SizedBox.shrink();
                    }

                    final customerData = participantDetails[customerId];
                    final customerName = customerData['name'] ?? 'Unknown';
                    final lastMessage =
                        chatRoom['lastMessage'] ?? 'No messages yet';

                    // Format timestamp
                    String formattedTime = '';
                    if (chatRoom['lastMessageTime'] != null) {
                      final timestamp =
                          chatRoom['lastMessageTime'] as Timestamp;
                      final messageDate = DateTime.fromMillisecondsSinceEpoch(
                        timestamp.millisecondsSinceEpoch,
                      );

                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final messageDay = DateTime(
                          messageDate.year, messageDate.month, messageDate.day);

                      if (today.difference(messageDay).inDays == 0) {
                        // Today - show time only
                        formattedTime = DateFormat('HH:mm').format(messageDate);
                      } else if (today.difference(messageDay).inDays == 1) {
                        // Yesterday
                        formattedTime = 'Yesterday';
                      } else if (today.difference(messageDay).inDays < 7) {
                        // This week - show day name
                        formattedTime = DateFormat('EEE').format(messageDate);
                      } else {
                        // Older - show date
                        formattedTime = DateFormat('dd/MM').format(messageDate);
                      }
                    }

                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: GestureDetector(
                        onTap: () {
                          final customerData = {
                            'customerId': customerId,
                            'name': participantDetails[customerId]['name'] ??
                                'Unknown',
                            'email':
                                participantDetails[customerId]['email'] ?? '',
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VendorChatScreen(customerData: customerData),
                            ),
                          );
                        },
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
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      _getAvatarColor(customerName),
                                  child: Text(
                                    customerName.isNotEmpty
                                        ? customerName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Message content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              customerName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF053E51),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            formattedTime,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFE53935), // Red
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFEF6C00), // Orange
      const Color(0xFF3949AB), // Indigo
      const Color(0xFF00ACC1), // Cyan
    ];

    // Use hash code for better distribution
    final hashCode = name.isNotEmpty ? name.hashCode : 0;
    final index = hashCode.abs() % colors.length;
    return colors[index];
  }
}
