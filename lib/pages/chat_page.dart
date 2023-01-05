import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ripto/utils/utilities.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ripto/constants/constants.dart';
import 'package:ripto/models/models.dart';
import 'package:ripto/providers/providers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/widgets.dart';
import 'pages.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.arguments}) : super(key: key);

  final ChatPageArguments arguments;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late String currentUserId;

  //network
  late bool netConnection = false;

  late StreamSubscription subscription;

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
    //connectivityCheck();
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        if (result.name == 'wifi' || result.name == 'mobile') {
          netConnection = true;
        } else {
          netConnection = false;
        }
      });
    });
  }

  @override
  dispose() {
    super.dispose();

    subscription.cancel();
  }

  _scrollListener() {
    if (!listScrollController.hasClients) return;
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
    String peerId = widget.arguments.peerId;
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    //PickedFile? pickedFile;

    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.arguments.peerId);
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: ColorConstants.greyColor);
    }
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        // Right (my message)
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                messageChat.type == TypeMessage.text
                    // Text
                    ? Container(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        constraints:
                            const BoxConstraints(minWidth: 10, maxWidth: 250),
                        decoration: const BoxDecoration(
                            color: ColorConstants.myMsg,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8))),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 20 : 10,
                            right: 10),
                        child: Text(
                          messageChat.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : messageChat.type == TypeMessage.image
                        // Image
                        ? Container(
                            margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 20 : 10,
                                right: 10),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullPhotoPage(
                                      url: messageChat.content,
                                    ),
                                  ),
                                );
                              },
                              style: ButtonStyle(
                                  padding:
                                      MaterialStateProperty.all<EdgeInsets>(
                                          const EdgeInsets.all(0))),
                              child: Material(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                clipBehavior: Clip.hardEdge,
                                child: Image.network(
                                  messageChat.content,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      decoration: const BoxDecoration(
                                        color: ColorConstants.greyColor2,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.themeColor,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, object, stackTrace) {
                                    return Material(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Image.asset(
                                        'assets/images/img_not_available.jpeg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        // Sticker
                        : Container(
                            margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 20 : 10,
                                right: 10),
                            child: Image.asset(
                              'assets/images/stickers/${messageChat.content}.gif',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
              ],
            ),

            // Time
            isLastMessageRight(index)
                ? Container(
                    margin: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width - 130,
                        top: 1,
                        bottom: 5),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM kk:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(messageChat.timestamp))),
                          style: const TextStyle(
                              color: ColorConstants.greyColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                        ReadedCheckClass.msgReaded == true
                            ? const Text(
                                ' Seen',
                                style: TextStyle(
                                    color: ColorConstants.greyColor,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  )
                : const SizedBox.shrink()
          ],
        );
      } else {
        // Left (peer message)
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  isLastMessageLeft(index)
                      ? Material(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              if (Utilities.isKeyboardShowing()) {
                                Utilities.closeKeyboard(context);
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                    peerId: widget.arguments.peerId,
                                    peerAvatar: widget.arguments.peerAvatar,
                                    peerUsername: widget.arguments.peerUsername,
                                    peerName: widget.arguments.peerName,
                                    peerAbout: widget.arguments.peerAbout,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              widget.arguments.peerAvatar,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: ColorConstants.themeColor,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, object, stackTrace) {
                                return const Icon(
                                  Icons.account_circle,
                                  size: 35,
                                  color: ColorConstants.greyColor,
                                );
                              },
                              width: 35,
                              height: 35,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(width: 35),
                  messageChat.type == TypeMessage.text
                      ? Container(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          constraints:
                              const BoxConstraints(minWidth: 10, maxWidth: 250),
                          decoration: const BoxDecoration(
                              color: ColorConstants.leftMsg,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8))),
                          margin: const EdgeInsets.only(left: 10),
                          child: Text(
                            messageChat.content,
                            style: const TextStyle(color: Colors.black),
                          ),
                        )
                      : messageChat.type == TypeMessage.image
                          ? Container(
                              margin: const EdgeInsets.only(left: 10),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullPhotoPage(
                                          url: messageChat.content),
                                    ),
                                  );
                                },
                                style: ButtonStyle(
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                            const EdgeInsets.all(0))),
                                child: Material(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    messageChat.content,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        decoration: const BoxDecoration(
                                          color: ColorConstants.greyColor2,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        width: 200,
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: ColorConstants.themeColor,
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, object, stackTrace) =>
                                            Material(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Image.asset(
                                        'assets/images/img_not_available.jpeg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.only(
                                  bottom: isLastMessageRight(index) ? 20 : 10,
                                  right: 10),
                              child: Image.asset(
                                'assets/images/stickers/${messageChat.content}.gif',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                ],
              ),

              // Time
              isLastMessageLeft(index)
                  ? Container(
                      margin:
                          const EdgeInsets.only(left: 50, top: 5, bottom: 5),
                      child: Text(
                        DateFormat('dd MMM kk:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                int.parse(messageChat.timestamp))),
                        style: const TextStyle(
                            color: ColorConstants.greyColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: null},
      );
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundClr,
      appBar: AppBar(
        elevation: 0,
        title: TextButton(
          onPressed: () {
            if (Utilities.isKeyboardShowing()) {
              Utilities.closeKeyboard(context);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  peerId: widget.arguments.peerId,
                  peerAvatar: widget.arguments.peerAvatar,
                  peerUsername: widget.arguments.peerUsername,
                  peerName: widget.arguments.peerName,
                  peerAbout: widget.arguments.peerAbout,
                ),
              ),
            );
          },
          child: Text(
            widget.arguments.peerName,
            style:
                const TextStyle(color: ColorConstants.titleColor, fontSize: 20),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              child: const Icon(Icons.more_horiz),
              onTap: () {
                if (Utilities.isKeyboardShowing()) {
                  Utilities.closeKeyboard(context);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      peerId: widget.arguments.peerId,
                      peerAvatar: widget.arguments.peerAvatar,
                      peerUsername: widget.arguments.peerUsername,
                      peerName: widget.arguments.peerName,
                      peerAbout: widget.arguments.peerAbout,
                    ),
                  ),
                );
              },
            ),
          )
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildListMessage(),

                  // Sticker
                  isShowSticker ? buildSticker() : const SizedBox.shrink(),

                  // Input content
                  buildInput(),
                ],
              ),

              // Loading
              buildLoading()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
            color: Colors.white),
        padding: const EdgeInsets.all(5),
        height: 180,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              //sticker

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_1', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_1.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_2', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_2.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_3', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_3.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_4', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_4.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_5', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_5.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_6', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_6.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_7', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_7.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_8', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_8.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_9', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_9.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_10', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_10.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_11', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_11.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_12', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_12.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_13', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_13.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_14', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_14.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_15', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_15.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_16', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_16.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_17', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_17.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_18', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_18.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_19', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_19.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_20', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_20.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_21', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_21.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_22', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_22.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_23', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_23.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_24', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_24.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_25', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_25.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_26', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_26.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_27', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_27.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_28', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_28.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_29', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_29.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onSendMessage('sticker_30', TypeMessage.sticker),
                    child: Image.asset(
                      'assets/images/stickers/sticker_30.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? const LoadingView() : const SizedBox.shrink(),
    );
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white),
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.image),
                onPressed: getImage,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: const Icon(Icons.face),
                onPressed: getSticker,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),

          // Edit text
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style:
                  const TextStyle(color: ColorConstants.inputTxt, fontSize: 15),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: ColorConstants.greyColor),
              ),
              focusNode: focusNode,
              autofocus: true,
            ),
          ),

          // Button send message
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  if (listMessage.isNotEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemBuilder: (context, index) {
                        if (netConnection) {
                          if (snapshot.data!.docs.length - index ==
                              snapshot.data!.docs.length) {
                            chatProvider.readMessage(groupChatId,
                                listMessage[index].id, currentUserId);
                          }
                        }
                        return buildItem(index, snapshot.data?.docs[index]);
                      },
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  } else {
                    return const Center(child: Text("No message here yet..."));
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
            )
          : const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
    );
  }
}

class ChatPageArguments {
  final String peerId;
  final String peerAvatar;
  final String peerName;
  final String peerUsername;
  final String peerAbout;

  ChatPageArguments(
      {required this.peerId,
      required this.peerAvatar,
      required this.peerName,
      required this.peerUsername,
      required this.peerAbout});
}
