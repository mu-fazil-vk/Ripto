import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ripto/constants/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/color_constants.dart';
import 'pages/pages.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  final MaterialColor mycolor = MaterialColor(
    ColorConstants.primaryColor.value,
    const <int, Color>{
      50: Color.fromARGB(255, 255, 137, 136),
      100: Color.fromARGB(255, 255, 137, 137),
      200: Color.fromARGB(255, 255, 137, 138),
      300: Color.fromARGB(255, 255, 137, 139),
      400: Color.fromARGB(255, 255, 137, 140),
      500: Color.fromARGB(255, 255, 137, 141),
      600: Color.fromARGB(255, 255, 137, 142),
      700: Color.fromARGB(255, 255, 137, 143),
      800: Color.fromARGB(255, 255, 137, 144),
      900: Color.fromARGB(255, 255, 137, 145),
    },
  );

  final MaterialColor mycolor1 = MaterialColor(
    ColorConstants.leftMsg.value,
    const <int, Color>{
      50: Color.fromARGB(255, 255, 255, 255),
      100: Color.fromARGB(255, 255, 255, 255),
      200: Color.fromARGB(255, 255, 255, 255),
      300: Color.fromARGB(255, 255, 255, 255),
      400: Color.fromARGB(255, 255, 255, 255),
      500: Color.fromARGB(255, 255, 255, 255),
      600: Color.fromARGB(255, 255, 255, 255),
      700: Color.fromARGB(255, 255, 255, 255),
      800: Color.fromARGB(255, 255, 255, 255),
      900: Color.fromARGB(255, 255, 255, 255),
    },
  );

  MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
            prefs: prefs,
            firebaseFirestore: firebaseFirestore,
          ),
        ),
        Provider<SettingProvider>(
          create: (_) => SettingProvider(
            prefs: prefs,
            firebaseFirestore: firebaseFirestore,
            firebaseStorage: firebaseStorage,
          ),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
            firebaseFirestore: firebaseFirestore,
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
            prefs: prefs,
            firebaseFirestore: firebaseFirestore,
            firebaseStorage: firebaseStorage,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          primaryColor: Colors.white,
          primarySwatch: mycolor1,
        ),
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
