import 'package:flutter/material.dart';
import 'package:send_message/chat_screen.dart';
import 'package:send_message/login_page.dart';
import 'package:send_message/roomListScreen.dart';
import 'package:send_message/signUp_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  void initState() {

  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}


