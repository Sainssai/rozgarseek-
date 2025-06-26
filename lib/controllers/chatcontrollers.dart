// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ChatController extends GetxController {
//   final TextEditingController messageController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   Stream<QuerySnapshot> getMessages(String receiverEmail) {
//     final currentEmail = _auth.currentUser!.email;
//     return _firestore
//         .collection('chats')
//         .orderBy('timestamp')
//         .where('participants', arrayContains: currentEmail)
//         .snapshots();
//   }

//   void sendMessage(String toEmail) {
//     final String message = messageController.text.trim();
//     if (message.isEmpty) return;

//     final currentEmail = _auth.currentUser!.email;

//     _firestore.collection('chats').add({
//       'sender': currentEmail,
//       'receiver': toEmail,
//       'message': message,
//       'timestamp': Timestamp.now(),
//       'participants': [currentEmail, toEmail]
//     });

//     messageController.clear();
//   }

//   FirebaseAuth get auth => _auth;
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getMessages(String receiverEmail) {
    final currentEmail = _auth.currentUser!.email!;
    // Generate consistent chatId
    final chatId = [currentEmail, receiverEmail]..sort();
    final chatDocId = chatId.join('_');
    return _firestore
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void sendMessage(String toEmail) async {
    final String message = messageController.text.trim();
    if (message.isEmpty) return;

    final currentEmail = _auth.currentUser!.email!;
    // Generate consistent chatId
    final chatId = [currentEmail, toEmail]..sort();
    final chatDocId = chatId.join('_');

    try {
      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .add({
            'sender': currentEmail,
            'message': message,
            'timestamp': Timestamp.now(),
          });
      // Update chat metadata
      await _firestore.collection('chats').doc(chatDocId).set({
        'participants': [currentEmail, toEmail],
        'lastMessage': message,
        'lastMessageTime': Timestamp.now(),
      }, SetOptions(merge: true));
      messageController.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    }
  }

  FirebaseAuth get auth => _auth;
}
