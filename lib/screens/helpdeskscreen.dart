import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class HelpDeskScreen extends StatefulWidget {
  @override
  _HelpDeskScreenState createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen> {
  final List<Color> _backgroundThemes = [
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.purple[100]!,
  ];
  int _currentThemeIndex = 0;
  final TextEditingController _messageController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.email!; // Use email as userId
  String? adminId; // Admin email to be fetched
  String? chatId; // Chat ID for the user-admin conversation

  @override
  void initState() {
    super.initState();
    _fetchAdminAndChat();
  }

  // Fetch admin email and existing chat
  Future<void> _fetchAdminAndChat() async {
    // Step 1: Find admin user
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      setState(() {
        adminId = adminSnapshot.docs.first['email']; // Assuming 'email' field exists
      });

      // Step 2: Find or create chat between user and admin
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      bool chatExists = false;
      for (var doc in chatSnapshot.docs) {
        List participants = doc['participants'];
        if (participants.contains(adminId)) {
          setState(() {
            chatId = doc.id;
          });
          chatExists = true;
          break;
        }
      }

      // Create new chat if none exists
      if (!chatExists && adminId != null) {
        final newChat = await FirebaseFirestore.instance.collection('chats').add({
          'participants': [userId, adminId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        setState(() {
          chatId = newChat.id;
        });
      }
    } else {
      Get.snackbar('Error', 'No admin found.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _changeTheme() {
    setState(() {
      _currentThemeIndex = (_currentThemeIndex + 1) % _backgroundThemes.length;
    });
  }

  void _sendMessage(String message) async {
    if (chatId == null || adminId == null) {
      Get.snackbar('Error', 'Chat or admin not initialized.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Add message to the messages subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'sender': userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the lastMessage and lastMessageTime in the chat document
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    Get.snackbar('Success', 'Message sent to admin.', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundThemes[_currentThemeIndex],
              _backgroundThemes[_currentThemeIndex].withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Help Desk',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.palette, color: Colors.black87),
                      onPressed: _changeTheme,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Chat with Admin',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: chatId == null
                            ? Center(child: CircularProgressIndicator())
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chatId)
                                    .collection('messages')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  final messages = snapshot.data!.docs;
                                  if (messages.isEmpty) {
                                    return Center(child: Text('No messages yet.'));
                                  }

                                  return ListView.builder(
                                    reverse: true, // Show latest messages at the bottom
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];
                                      bool isSentByUser = message['sender'] == userId;
                                      return Align(
                                        alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSentByUser ? Colors.blue[100] : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message['message'],
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                message['timestamp'] != null
                                                    ? (message['timestamp'] as Timestamp).toDate().toLocal().toString().split('.')[0]
                                                    : 'N/A',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          FloatingActionButton(
                            onPressed: () {
                              if (_messageController.text.isNotEmpty) {
                                _sendMessage(_messageController.text);
                              }
                            },
                            child: Icon(Icons.send),
                            backgroundColor: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}