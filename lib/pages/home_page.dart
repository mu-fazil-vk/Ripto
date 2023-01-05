import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ripto/constants/constants.dart';
import 'package:ripto/providers/providers.dart';
import 'package:ripto/utils/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';
import 'pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key});

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;
  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
    listScrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(PopupChoices choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const AccountPage()));
    }
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                color: ColorConstants.themeColor,
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: const Icon(
                        Icons.exit_to_app,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(
                        Icons.cancel,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color.fromARGB(255, 255, 0, 4),
                      ),
                    ),
                    const Text(
                      'Yes',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 0, 4),
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[175],
      body: SafeArea(
        child: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(
            children: <Widget>[
              // List
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 20, top: 30),
                        child: const Text(
                          "Chats",
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.titleColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                          padding: const EdgeInsets.only(top: 20),
                          child: buildPopupMenu())
                    ],
                  ),
                  buildSearchBar(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: homeProvider.getStreamFireStore(
                          FirestoreConstants.pathUserCollection,
                          _limit,
                          _textSearch),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if ((snapshot.data?.docs.length ?? 0) > 0) {
                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(10),
                              itemBuilder: (context, index) => buildItem(
                                  context, snapshot.data?.docs[index]),
                              itemCount: snapshot.data?.docs.length,
                              controller: listScrollController,
                            );
                          } else {
                            return const Center(
                              child: Text("No users"),
                            );
                          }
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.themeColor,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Loading
              Positioned(
                child:
                    isLoading ? const LoadingView() : const SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.search,
                  color: ColorConstants.greyColor, size: 20),
              const SizedBox(width: 5),
              Expanded(
                child: TextFormField(
                  textInputAction: TextInputAction.search,
                  controller: searchBarTec,
                  onChanged: (value) {
                    searchDebouncer.run(() {
                      if (value.isNotEmpty) {
                        btnClearController.add(true);
                        setState(() {
                          _textSearch = value;
                        });
                      } else {
                        btnClearController.add(false);
                        setState(() {
                          _textSearch = "";
                        });
                      }
                    });
                  },
                  decoration: const InputDecoration.collapsed(
                    hintText: ' Search name',
                    hintStyle: TextStyle(
                        fontSize: 13, color: ColorConstants.greyColor),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              StreamBuilder<bool>(
                  stream: btnClearController.stream,
                  builder: (context, snapshot) {
                    return snapshot.data == true
                        ? GestureDetector(
                            onTap: () {
                              searchBarTec.clear();
                              btnClearController.add(false);
                              setState(() {
                                _textSearch = "";
                              });
                            },
                            child: const Icon(Icons.clear_rounded,
                                color: ColorConstants.greyColor, size: 20))
                        : const SizedBox.shrink();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
      onSelected: onItemMenuPress,
      itemBuilder: (BuildContext context) {
        return choices.map((PopupChoices choice) {
          return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: <Widget>[
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: const TextStyle(color: ColorConstants.primaryColor),
                  ),
                ],
              ));
        }).toList();
      },
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        return Container(
          margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
          child: TextButton(
            onPressed: () {
              if (Utilities.isKeyboardShowing()) {
                Utilities.closeKeyboard(context);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    arguments: ChatPageArguments(
                        peerId: userChat.id,
                        peerAvatar: userChat.photoUrl,
                        peerUsername: userChat.username,
                        peerName: userChat.name,
                        peerAbout: userChat.aboutMe),
                  ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Material(
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 50,
                              color: ColorConstants.greyColor,
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 50,
                          color: ColorConstants.greyColor,
                        ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: <Widget>[
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                          child: Text(
                            userChat.name,
                            maxLines: 1,
                            style: const TextStyle(
                                color: ColorConstants.titleColor),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            'Username: ${userChat.username}',
                            maxLines: 1,
                            style: const TextStyle(
                                color: ColorConstants.greyColor),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
