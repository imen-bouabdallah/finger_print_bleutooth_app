import 'package:finger_print_bleutooth_app/screens/MainPage.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Door key',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.brown[200],
          accentColor: Colors.brown,
        ),
        home : MainPage(),
    );
  }
}
