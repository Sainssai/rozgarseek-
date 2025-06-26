import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:razgorsek/screens/chatscreen.dart';

class ProviderChatList extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Future<String?> _getUserName(String email) async {
  //   final userDoc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .where('email', isEqualTo: email)
  //       .limit(1)
  //       .get();
  //   if (userDoc.docs.isNotEmpty) {
  //     return userDoc.docs.first['name'] ?? email;
  //   }
  //   return email;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          final userList = chats
              .map((doc) {
                final participants = doc['participants'] as List<dynamic>;
                return participants.firstWhere(
                  (email) => email != currentUser!.email,
                );
              })
              .toSet()
              .toList();

          return FutureBuilder<List<Map<String, String>>>(
            future: Future.wait(
              userList.map((email) async {
                // Fetch user info
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();
                if (userDoc.docs.isNotEmpty &&
                    userDoc.docs.first['role'] != 'admin') {
                  return {
                    'email': email,
                    'name': userDoc.docs.first['name'] ?? email,
                  };
                }
                return {};
              }),
            ),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final filteredUsers = userSnapshot.data!
                  .where((user) => user.isNotEmpty)
                  .toList();

              if (filteredUsers.isEmpty) {
                return Center(child: Text('No user conversations.'));
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return ListTile(
                    title: Text(user['name'] ?? user['email']!),
                    subtitle: Text(user['email']!),
                    trailing: Icon(Icons.chat),
                    onTap: () {
                      Get.to(
                        () => ChatScreen(
                          peerEmail: user['email']!,
                          peerName: user['name'] ?? "User",
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProviderToAdminChatScreen extends StatefulWidget {
  @override
  _ProviderToAdminChatScreenState createState() =>
      _ProviderToAdminChatScreenState();
}

class _ProviderToAdminChatScreenState extends State<ProviderToAdminChatScreen> {
  final String providerId = FirebaseAuth.instance.currentUser!.email!;
  String? adminId; // Admin email to be fetched
  String? chatId; // Chat ID for the provider-admin conversation
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminAndChat();
  }

  Future<void> _fetchAdminAndChat() async {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      setState(() {
        adminId = adminSnapshot.docs.first['email'];
      });

      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: providerId)
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

      if (!chatExists && adminId != null) {
        final newChat = await FirebaseFirestore.instance
            .collection('chats')
            .add({
              'participants': [providerId, adminId],
              'lastMessage': '',
              'lastMessageTime': FieldValue.serverTimestamp(),
            });
        setState(() {
          chatId = newChat.id;
        });
      }
    } else {
      Get.snackbar(
        'Error',
        'No admin found.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _sendMessage(String message) async {
    if (chatId == null || adminId == null) {
      Get.snackbar(
        'Error',
        'Chat or admin not initialized.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'sender': providerId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    Get.snackbar(
      'Success',
      'Message sent to admin.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Admin'),
        backgroundColor: Colors.pink[50],
        elevation: 0,
      ),
      body: Container(
        color: Colors.pink[50],
        child: Column(
          children: [
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
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            bool isSentByProvider =
                                message['sender'] == providerId;
                            return Align(
                              alignment: isSentByProvider
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSentByProvider
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message['message'],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
