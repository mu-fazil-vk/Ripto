import 'package:ripto/pages/signin/login_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 147, 184, 189),
      body: SafeArea(
          child: Column(
        children: [
          // Load a Lottie file from your assets
          Container(
              padding: EdgeInsets.all(media.width / 8),
              child: Lottie.asset('assets/intro/chatting.json')),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Container(
              width: media.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(25),
                      child: SizedBox(
                          child: Column(
                        children: [
                          const Text(
                            "Enjoy the new Experience of Chatting with global friends",
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
                            "Connect people around the world for free",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                              );
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 70,
                              width: 290,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: const Color.fromARGB(255, 152, 196, 217),
                              ),
                              child: const Text(
                                "Get Started",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          const Text(
                            "Powered by Fazil ✨",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )))
                ],
              ),
            ),
          )
        ],
      )),
    );
  }
}
