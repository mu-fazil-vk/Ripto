import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ripto/constants/app_constants.dart';
import 'package:ripto/constants/constants.dart';
import 'package:ripto/models/models.dart';
import 'package:ripto/providers/providers.dart';
import 'package:ripto/widgets/loading_view.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.accountTitle,
          style: TextStyle(
              color: ColorConstants.titleColor,
              fontSize: 25,
              fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        //centerTitle: true,
      ),
      body: const AccountPageState(),
    );
  }
}

class AccountPageState extends StatefulWidget {
  const AccountPageState({super.key});

  @override
  State createState() => AccountPageStateState();
}

class AccountPageStateState extends State<AccountPageState> {
  TextEditingController? controllerName;
  TextEditingController? controllerAboutMe;
  TextEditingController? controllerUsername;

  late HomeProvider homeProvider;

  String id = '';
  String name = '';
  String username = '';
  String aboutMe = '';
  String photoUrl = '';
  String oldUsername = '';

  bool isLoading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeName = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();
  final FocusNode focusNodeUsername = FocusNode();

  @override
  void initState() {
    super.initState();
    homeProvider = context.read<HomeProvider>();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? "";
      name = settingProvider.getPref(FirestoreConstants.name) ?? "";
      username = settingProvider.getPref(FirestoreConstants.userName) ?? "";
      oldUsername = settingProvider.getPref(FirestoreConstants.userName) ?? "";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });

    controllerName = TextEditingController(text: name);
    controllerUsername = TextEditingController(text: username);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        name: name,
        username: username,
        aboutMe: aboutMe,
      );
      settingProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Upload success");
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeName.unfocus();
    focusNodeAboutMe.unfocus();
    focusNodeUsername.unfocus();

    setState(() {
      isLoading = true;
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      name: name,
      username: username,
      aboutMe: aboutMe,
    );
    settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingProvider.setPref(FirestoreConstants.name, name);
      await settingProvider.setPref(FirestoreConstants.userName, username);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  final _formKeyName = GlobalKey<FormState>();
  final _formKeyUser = GlobalKey<FormState>();
  final _formKeyBio = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Avatar
              CupertinoButton(
                onPressed: getImage,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, object, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 90,
                                    height: 90,
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
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              // Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Username
                  Container(
                    margin: const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                    child: Text(
                      'Name',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600]),
                    ),
                  ),
                  Form(
                    key: _formKeyName,
                    child: Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Sweetie',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerName,
                          validator: (text) {
                            if (text == null ||
                                text.isEmpty ||
                                text.length < 3) {
                              return 'Minimum 3 characters are required';
                            } else if (text.length > 10) {
                              return "Too much characters";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            name = value;
                            _formKeyName.currentState!.validate();
                          },
                          focusNode: focusNodeName,
                        ),
                      ),
                    ),
                  ),

                  //username
                  Container(
                    margin: const EdgeInsets.only(left: 10, bottom: 5, top: 30),
                    child: Text(
                      'Username',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600]),
                    ),
                  ),
                  Form(
                    key: _formKeyUser,
                    child: Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'messi',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerUsername,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp("[0-9a-zA-Z_.-]")),
                          ], // Only numbers can be entered
                          validator: (text) {
                            if (text == null ||
                                text.isEmpty ||
                                text.length < 3) {
                              return 'Minimum 3 characters are required';
                            } else if (text.contains('..')) {
                              return "You can't have more than one period";
                            } else if (text.endsWith('.')) {
                              return "You can't end with period";
                            } else if (text.startsWith('.')) {
                              return "You can't end with period";
                            } else if (text.endsWith('-')) {
                              return "You can't end with period";
                            } else if (text.startsWith('-')) {
                              return "You can't end with period";
                            } else if (text.length > 10) {
                              return "Too much characters";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            username = value.toLowerCase();
                            _formKeyUser.currentState!.validate();
                          },
                          focusNode: focusNodeUsername,
                        ),
                      ),
                    ),
                  ),

                  // About me
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: Text(
                      'About me',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600]),
                    ),
                  ),
                  Form(
                    key: _formKeyBio,
                    child: Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Fun, like travel and play PES...',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          minLines: 1,
                          maxLines: 6,
                          controller: controllerAboutMe,
                          validator: (text) {
                            if (text!.length > 250) {
                              return 'Too much characters';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            aboutMe = value;
                            _formKeyBio.currentState!.validate();
                          },
                          focusNode: focusNodeAboutMe,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              // Button
              InkWell(
                onTap: checkInput,
                child: Container(
                  alignment: Alignment.center,
                  height: 70,
                  width: 290,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: ColorConstants.primaryColor,
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading
        Positioned(
            child: isLoading ? const LoadingView() : const SizedBox.shrink()),
      ],
    );
  }

  checkInput() {
    if (_formKeyName.currentState!.validate() &&
        _formKeyUser.currentState!.validate()) {
      if (oldUsername != username) {
        availableUsername(username);
      } else {
        handleUpdateData();
      }
    }
  }

  //username availability
  availableUsername(String? userSearch) async {
    if (userSearch?.isNotEmpty == true) {
      final QuerySnapshot result = await homeProvider.firebaseFirestore
          .collection('users')
          .where('userName', isEqualTo: userSearch)
          .get();

      //converts results to a list of documents
      final List<DocumentSnapshot> documents = result.docs;

      //checks the length of the document to see if its
      //greater than 0 which means the username has already been taken
      if (documents.isNotEmpty) {
        Fluttertoast.showToast(
            msg: '${userSearch!} is already taken choose another name');
      } else {
        handleUpdateData();
        setState(() {
          oldUsername = userSearch!;
        });
      }
    } else {
      return null;
    }
  }
}
