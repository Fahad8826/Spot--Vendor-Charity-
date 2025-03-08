import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spot/vendor/screens/chatscreen.dart';

class VendorChatListScreen extends StatelessWidget {
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
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final chatRooms = snapshot.data!.docs;

            if (chatRooms.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom =
                    chatRooms[index].data() as Map<String, dynamic>;
                final participantDetails =
                    chatRoom['participantDetails'] as Map<String, dynamic>;

                final customerId = (chatRoom['participants'] as List)
                    .firstWhere((id) => id != currentVendorId);
                final customerData = participantDetails[customerId];

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: _getAvatarColor(customerData['name']),
                        child: Text(
                          customerData['name'][0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        customerData['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        chatRoom['lastMessage'] ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                      trailing: Text(
                        chatRoom['lastMessageTime'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                chatRoom['lastMessageTime']
                                    .millisecondsSinceEpoch,
                              ).toString().substring(11, 16)
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      onTap: () {
                        final customerData = {
                          'customerId': customerId,
                          'name': participantDetails[customerId]['name'],
                          'email': participantDetails[customerId]['email'],
                        };

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VendorChatScreen(customerData: customerData),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange
    ];
    return colors[name.length % colors.length].withOpacity(0.8);
  }
}
