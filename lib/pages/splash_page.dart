import 'package:ripto/pages/home_navigation.dart';
import 'package:ripto/pages/intro/intro_page.dart';
import 'package:flutter/material.dart';
import 'package:ripto/constants/color_constants.dart';
import 'package:ripto/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      // just delay for showing this slash page clearer because it too fast
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavScreen()),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IntroPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.splashBgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'RI',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5),
                  ),
                  Text(
                    'PT',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey,
                        letterSpacing: 3),
                  ),
                  Text(
                    'O',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyan,
                        letterSpacing: 3),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 7,
            ),
            Image.asset(
              "assets/images/app_icon.png",
              width: 200,
              height: 300,
            ),
            const SizedBox(height: 5),
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(color: ColorConstants.themeColor),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 7,
            ),
            const Text(
              'By Fazil vk',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
