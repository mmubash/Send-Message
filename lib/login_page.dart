import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:send_message/roomListScreen.dart';
import 'package:send_message/signUp_page.dart';
class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> validateEmpty = GlobalKey<FormState>();
  bool _isHidden = true;
  late IO.Socket socket;
  void login(String email, String password) async {
    try {
      var body = jsonEncode({'email': email, 'password': password});
      http.Response response = await http.post(
        Uri.parse("http://192.168.2.189:3001/api/user/login"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        print(response.body);
        var data = jsonDecode(response.body);
        String userName = data['user']['name'] ?? 'Unknown User';
        print(userName);
        String userId = data['user']['_id'] ?? 'Unknown id';
        print("*******USERID  $userId");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', userName);
        socket = IO.io('ws://192.168.2.189:3001', IO.OptionBuilder()
            .setTransports(['websocket'])
            .build());
        socket.connect();
        socket.onConnect((_) {
          print('Connected to the server');
        });
        print("Loggedd innnnn");
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RoomListScreen(currentUserId: userId, currentUserName: userName,))
        );
      } else {
        print('Failed to log in: ${response.body}');
      }
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: validateEmpty,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 130),
            child: Column(
              children: [
                Center(
                  child: Text("Welcome To login ")
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: passwordController,
                  obscureText: _isHidden,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isHidden ? Icons.visibility_off : Icons.visibility),
                      onPressed: _togglePasswordView,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (validateEmpty.currentState!.validate()) {
                      login(emailController.text, passwordController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill out all fields')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Center(child: Text('Login')),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => SignupPage()));
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
