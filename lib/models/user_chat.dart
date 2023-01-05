import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ripto/constants/constants.dart';

class UserChat {
  String id;
  String photoUrl;
  String name;
  String username;
  String aboutMe;

  UserChat(
      {required this.id,
      required this.photoUrl,
      required this.name,
      required this.username,
      required this.aboutMe});

  Map<String, String> toJson() {
    return {
      FirestoreConstants.name: name,
      FirestoreConstants.userName: username,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String name = "";
    String username = "";
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      name = doc.get(FirestoreConstants.name);
    } catch (e) {}
    try {
      username = doc.get(FirestoreConstants.userName);
    } catch (e) {}
    return UserChat(
      id: doc.id,
      photoUrl: photoUrl,
      name: name,
      username: username,
      aboutMe: aboutMe,
    );
  }
}
