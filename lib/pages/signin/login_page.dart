import 'package:ripto/constants/color_constants.dart';
import 'package:ripto/pages/home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:ripto/providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../widgets/loading_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign in success");
        break;
      default:
        break;
    }
    return Scaffold(
        backgroundColor: ColorConstants.backgroundClr,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30), // Image border
                      child: SizedBox.fromSize(
                        //size: Size.fromRadius(48), // Image radius
                        child: Image.asset('assets/intro/login.jpg',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 70,
                  ),
                  const Text(
                    "Sign in simply using Google",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    "Chat with anyone around you",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  InkWell(
                    onTap: () async {
                      authProvider.handleSignIn().then((isSuccess) {
                        if (isSuccess) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeNavScreen(),
                            ),
                          );
                        }
                      }).catchError((error, stackTrace) {
                        Fluttertoast.showToast(msg: error.toString());
                        authProvider.handleException();
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 70,
                      width: 290,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: ColorConstants.primaryColor,
                      ),
                      child: const Text(
                        "Google",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              // Loading
              Positioned(
                child: authProvider.status == Status.authenticating
                    ? const LoadingView()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ));
  }
}
