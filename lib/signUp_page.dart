import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:send_message/login_page.dart';
class SignupPage extends StatefulWidget {
   SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isHidden = true;
  bool _isHiddenCp=true;
  String mtoken='';
  final GlobalKey<FormState> validateconfirm=GlobalKey<FormState>();

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }
  void _toggleCPasswordView() {
    setState(() {
      _isHiddenCp = !_isHiddenCp;
    });
  }
  void signup(String email, String password, String name) async {
    try {

      var body = jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      });
      http.Response response = await http.post(
        Uri.parse("http://192.168.2.189:3001/api/user/register"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {

        print("Account Created Successfully");
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account Created Successfully')),
        );
      } else {

        print("Account creation failed: ${response.body}");
      }
    } catch (e) {

      print("Error: ${e.toString()}");
    }
  }
  TextEditingController nameController= new TextEditingController();
  TextEditingController emailController= new TextEditingController();
  TextEditingController passwordController= new TextEditingController();
  TextEditingController cPasswordController= new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign up "),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Form(
        key: validateconfirm,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 40.0,right: 40,top: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                TextFormField(
                  validator: (value){
                    if(value!.isEmpty){
                      return "Please Enter name";
                    }
                  },
                  controller: nameController,
                  decoration: InputDecoration(

                      labelText: 'Name',
                      hintText: "Enter Name",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                      isDense: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.person),
                      )
                  ),
                ),
                SizedBox(height: 30,),
                TextFormField(
                  validator: (value){
                    if(value!.isEmpty){
                      return "Please Enter Email";
                    }
                  },
                  controller: emailController,
                  decoration: InputDecoration(
                      labelText: "Email" ,
                      hintText: "Enter Email",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                      isDense: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.email_outlined),
                      )
                  ),
                ),
                SizedBox(height: 30,),
                TextFormField(
                  validator: (value){
                    if(value!.isEmpty){
                      return "Please Enter Password";
                    }
                  },
                  controller: passwordController,
                  obscureText: _isHidden,
                  decoration: InputDecoration(
                    label: Text('Password'),
                    hintText: "Password",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                    isDense: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.password),
                    ),
                    suffixIcon: InkWell(
                      onTap: _togglePasswordView,
                      child: Icon(
                        _isHidden ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30,),
                TextFormField(
                  validator: (value){
                    if(value!=passwordController.text){
                      return "Password dont match";
                    }
                  },
                  controller: cPasswordController,
                  obscureText: _isHiddenCp,
                  decoration: InputDecoration(
                    label: Text('Confirm Password'),
                    hintText: "Confirm Password",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                    isDense: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.password),
                    ),
                    suffixIcon: InkWell(
                      onTap: _toggleCPasswordView,
                      child: Icon(
                        _isHiddenCp ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 35,),
                GestureDetector(
                  onTap: (){
                    if(validateconfirm.currentState!.validate()){
                      signup(emailController.text.toString(),passwordController.text.toString(),nameController.text.toString());
                    }

                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                      child: Text('Sign Up',style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ),
                SizedBox(height: 15,),
                Row(
                  children: [
                    Text("Already have an Account ?"),
                    SizedBox(width: 10,),
                    GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                        },
                        child: Text("Log In",style: TextStyle(fontWeight: FontWeight.bold),)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
