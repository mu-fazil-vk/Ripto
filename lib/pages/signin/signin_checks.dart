import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class SigninCheck {
  //username availability
  Future availableUsername(String? userSearch) async {
    if (userSearch?.isNotEmpty == true) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('userName', isEqualTo: userSearch)
          .get();

      //converts results to a list of documents
      final List<DocumentSnapshot> documents = result.docs;

      //checks the length of the document to see if its
      //greater than 0 which means the username has already been taken
      if (documents.isNotEmpty) {
        getRandomUsername(5);
      } else {
        return userSearch;
      }
    } else {
      return null;
    }
  }

  static const _chars =
      'abcdefghijklmnopqrstuvwxyz1234567890';
  final Random _rnd = Random();

  Future getRandomUsername(int length) {
    var username = String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)))).toLowerCase();
    return availableUsername('user$username');
  }
}

//check new username and accoun / dlt acc and relog again