import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razgorsek/screens/authentication.dart';

class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  final String keyId = 'rzp_test_52dp1Z8qV4bxDM';
  final String keySecret = '5fbghfhOvpq1gur8mgQS1Sbk';
  late final String authString;
  late final String basicAuth;

  @override
  void initState() {
    super.initState();
    authString = '$keyId:$keySecret';
    basicAuth = 'Basic ${base64.encode(utf8.encode(authString))}';
  }

  Future<void> _initiateRazorpayRefund(String transactionId, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/payments/$transactionId/refund'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'speed': 'normal',
          'notes': {'reason': 'User requested refund'},
        }),
      );
      if (response.statusCode == 200) {
        Get.snackbar('Success'.tr, 'Refund processed successfully.'.tr);
      } else {
        Get.snackbar('Error'.tr, 'Refund failed: ${response.body}'.tr);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, 'Refund initiation failed: $e'.tr);
    }
  }

  Future<void> _changeProviderStatus(String providerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .update({'isBooked': false});
      Get.snackbar('Success'.tr, 'Provider status updated to available.'.tr);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to update provider status: $e'.tr);
    }
  }

  Widget _buildRefundsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Refund Requests'.tr,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refundrequests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                final refunds = snapshot.data!.docs;
                if (refunds.isEmpty) {
                  return Center(child: Text('No pending refund requests.'.tr));
                }
                return ListView.separated(
                  itemCount: refunds.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final refund = refunds[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(refund['userId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return Container();
                        var userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final amountInPaise = (refund['price'] * 100).toInt();
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service: ${refund['service']}'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text('User: ${userData['email']}'.tr),
                                Text('Price: ₹${refund['price']}'.tr),
                                Text(
                                  'Transaction ID: ${refund['transactionId']}.'.tr,
                                ),
                                Text(
                                  'Requested: ${refund['timestamp']?.toDate().toLocal().toString().split(' ')[0] ?? 'N/A'}'.tr,
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Refund Approve'.tr,
                                        style: TextStyle(fontSize: 8),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await _initiateRazorpayRefund(
                                            refund['transactionId'],
                                            amountInPaise,
                                          );
                                          await FirebaseFirestore.instance
                                              .collection('refundrequests')
                                              .doc(refund.id)
                                              .update({'status': 'approved'});
                                          await FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(refund['bookingId'])
                                              .update({'status': 'refunded'});
                                        } catch (e) {
                                          Get.snackbar(
                                            'Error'.tr,
                                            'Refund processing failed.'.tr,
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Refund Reject'.tr,
                                        style: TextStyle(fontSize: 8),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('refundrequests')
                                            .doc(refund.id)
                                            .update({'status': 'rejected'});
                                        Get.snackbar(
                                          'Success'.tr,
                                          'Refund rejected.'.tr,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: () async {
                                    await _changeProviderStatus(
                                      refund['providerId'],
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    side: BorderSide(color: Colors.blueAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Update Provider status to available '.tr,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    final String adminId = FirebaseAuth.instance.currentUser!.email!;
    return DefaultTabController(
      length: 2,
      child: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'User Chats'.tr,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: 'Users'.tr),
                Tab(text: 'Providers'.tr),
              ],
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey[600],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Users Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: adminId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final chats = snapshot.data!.docs;

                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: () async {
                          List<Map<String, dynamic>> filtered = [];
                          for (var chat in chats) {
                            final participants = chat['participants'] as List;
                            final peerId = participants.firstWhere(
                              (id) => id != adminId,
                            );
                            if (await _isUser(peerId)) {
                              // Fetch user details
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', isEqualTo: peerId)
                                  .limit(1)
                                  .get();
                              final userData = userDoc.docs.isNotEmpty
                                  ? userDoc.docs.first.data()
                                  : {};
                              filtered.add({
                                'chat': chat,
                                'user': userData,
                                'peerId': peerId,
                              });
                            }
                          }
                          return filtered;
                        }(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final userChats = userSnapshot.data!;
                          if (userChats.isEmpty) {
                            return Center(child: Text('No user chats found.'.tr));
                          }

                          return ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: userChats.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final chat = userChats[index]['chat'];
                              final user = userChats[index]['user'];
                              final peerId = userChats[index]['peerId'];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 18,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    user['name'] ?? peerId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                  onTap: () {
                                    Get.to(
                                      () => ChatDetailScreen(
                                        chatId: chat.id,
                                        userId: peerId,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  // Providers Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: adminId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final chats = snapshot.data!.docs;

                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: () async {
                          List<Map<String, dynamic>> filtered = [];
                          for (var chat in chats) {
                            final participants = chat['participants'] as List;
                            final peerId = participants.firstWhere(
                              (id) => id != adminId,
                            );
                            if (await _isProvider(peerId)) {
                              // Fetch provider details
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', isEqualTo: peerId)
                                  .limit(1)
                                  .get();
                              final userData = userDoc.docs.isNotEmpty
                                  ? userDoc.docs.first.data()
                                  : {};
                              filtered.add({
                                'chat': chat,
                                'user': userData,
                                'peerId': peerId,
                              });
                            }
                          }
                          return filtered;
                        }(),
                        builder: (context, providerSnapshot) {
                          if (!providerSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final providerChats = providerSnapshot.data!;
                          if (providerChats.isEmpty) {
                            return Center(
                              child: Text('No provider chats found.'.tr),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: providerChats.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final chat = providerChats[index]['chat'];
                              final user = providerChats[index]['user'];
                              final peerId = providerChats[index]['peerId'];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 18,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orangeAccent,
                                    child: Icon(
                                      Icons.work,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    user['name'] ?? peerId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.orangeAccent,
                                  ),
                                  onTap: () {
                                    Get.to(
                                      () => ChatDetailScreen(
                                        chatId: chat.id,
                                        userId: peerId,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to check if an email belongs to a user
  Future<bool> _isUser(String email) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return userDoc.docs.isNotEmpty && userDoc.docs.first['role'] == 'user';
  }

  // Helper method to check if an email belongs to a provider
  Future<bool> _isProvider(String email) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return userDoc.docs.isNotEmpty && userDoc.docs.first['role'] == 'provider';
  }

  Widget _buildSearchTab() {
    String dropdownValue = 'All Users'.tr;
    List<String> dropdownOptions = ['All Users'.tr, 'All Providers'.tr];

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Search'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Show:'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(width: 12),
                  DropdownButton<String>(
                    value: dropdownValue,
                    items: dropdownOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setInnerState(() {
                        dropdownValue = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        'role',
                        isEqualTo: dropdownValue == 'All Users'.tr
                            ? 'user'
                            : 'provider',
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());
                    final users = snapshot.data!.docs;
                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${dropdownValue == 'All Users'.tr ? 'users'.tr : 'providers'.tr} found.'.tr,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final data = user.data() as Map<String, dynamic>;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dropdownValue == 'All Users'.tr
                                      ? 'User: ${data['email'] ?? ''}'.tr
                                      : 'Provider: ${data['email'] ?? ''}'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 6),
                                if (dropdownValue == 'All Users'.tr) ...[
                                  Text('Name: ${data['name'] ?? ''}'.tr),
                                  Text('Phone: ${data['phone'] ?? ''}'.tr),
                                  Text('Address: ${data['location'] ?? ''}'.tr),
                                  Text('User ID: ${user.id}'.tr),
                                ] else ...[
                                  Text('Name: ${data['name'] ?? ''}'.tr),
                                  Text('Category: ${data['category'] ?? ''}'.tr),
                                  Text('Location: ${data['location'] ?? ''}'.tr),
                                  Text('Phone: ${data['phone'] ?? ''}'.tr),
                                  Text('Provider ID: ${user.id}'.tr),
                                  Text(
                                    'Is Booked: ${data['isBooked'] == true ? "Yes".tr : "No".tr}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutTab() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 48),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to logout?'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'.tr),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await FirebaseAuth.instance.signOut();
                      Get.offAll(() => AuthScreen());
                    },
                    child: Text('Logout'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return SizedBox.shrink();
  }

  List<Widget> get _pages => [
        _buildRefundsTab(),
        _buildChatsTab(),
        _buildSearchTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        toolbarHeight: 70,
      ),
      body: Container(color: Colors.grey[100], child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index == 3) {
                _buildLogoutTab();
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.monetization_on_rounded, size: 28),
                label: 'Refunds'.tr,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded, size: 28),
                label: 'Chats'.tr,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded, size: 28),
                label: 'Search'.tr,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout_rounded, size: 28),
                label: 'Logout'.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  ChatDetailScreen({required this.chatId, required this.userId});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final String adminId = FirebaseAuth.instance.currentUser!.email!;
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage(String message) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'sender': adminId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    Get.snackbar(
      'Success'.tr,
      'Message sent.'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId),
        backgroundColor: Colors.pink[50],
        elevation: 0,
      ),
      body: Container(
        color: Colors.pink[50],
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  if (messages.isEmpty) {
                    return Center(child: Text('No messages yet.'.tr));
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      bool isSentByAdmin = message['sender'] == adminId;
                      return Align(
                        alignment: isSentByAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSentByAdmin
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
                        hintText: 'Type your reply...'.tr,
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
