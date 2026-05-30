import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<void> sendMessage(String rideId, String senderId, String text) async {
    try {
      final chatMessage = ChatMessage(
        id: '',
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .add(chatMessage.toJson());
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Get messages stream
  Stream<List<ChatMessage>> getMessages(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}
