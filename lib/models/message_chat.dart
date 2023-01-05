import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ripto/constants/constants.dart';

class MessageChat {
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  String read;
  int type;

  MessageChat({
    required this.idFrom,
    required this.idTo,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.read,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.content: content,
      FirestoreConstants.read: read,
      FirestoreConstants.type: type,
    };
  }

  factory MessageChat.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    String read = doc.get(FirestoreConstants.read);
    int type = doc.get(FirestoreConstants.type);
    return MessageChat(
        idFrom: idFrom,
        idTo: idTo,
        timestamp: timestamp,
        content: content,
        read: read,
        type: type);
  }
}
