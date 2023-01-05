import 'package:ripto/pages/pages.dart';
import 'package:flutter/material.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({Key? key}) : super(key: key);

  @override
  HomeNavScreenState createState() => HomeNavScreenState();
}

class HomeNavScreenState extends State<HomeNavScreen> {
  int _currentSelectedIndex = 0;

  final _pages = [
    const HomePage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentSelectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.purple,
        currentIndex: _currentSelectedIndex,
        onTap: (newIndex) {
          setState(() {
            _currentSelectedIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
