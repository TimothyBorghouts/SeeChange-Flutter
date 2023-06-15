import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'home_screen.dart';


class LoginScreen extends StatelessWidget {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  var error = false;


  @override
  void initState(){
    passwordVisible = false;
    error = false;
  }

  void login(BuildContext context) async {
    var url = Uri.parse('http://145.49.7.81:3000/auth/login');

    var body = {
      'username': emailController.text,
      'password': passwordController.text,
    };

    print(body);

    try {
      var response = await http.post(url, body: body);

      if (response.statusCode == 201) {
        print('Login successful!');
        print('Response body: ${response.body}');

        // Decode the JWT token
        var token = response.body;
        var decodedToken = JwtDecoder.decode(token);

        // Validate the token
        var isTokenExpired = JwtDecoder.isExpired(token);
        if (!isTokenExpired) {
          // Token is valid, enter the application
          print('Token is valid');
          print('Decoded token: $decodedToken');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );

        } else {
          print('Token is invalid');
        }

      } else {
        print('Login failed with status code: ${response.statusCode}');
        print('Error: ${response.body}');
        error = true;

      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildEmailTextField(IconData icon, String labelText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: emailController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.grey),
          icon: Icon(icon, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(IconData icon, String labelText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        keyboardType: TextInputType.text,
        obscureText: !passwordVisible,
        controller: passwordController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.grey),
          icon: Icon(icon, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Visibility(
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(10.0),
    ),
          child: Text(
            'Invalid username or password',
            style: TextStyle(color: Colors.red),
          ),
        ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("login");
        login(context);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFFFE4237),
        backgroundColor: const Color(0xFFFFECEB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      child: const Text(
        'Login',
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFE4237),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Container(),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEmailTextField(Icons.email, 'Email'),
                    const SizedBox(height: 20.0),
                    _buildPasswordTextField(Icons.lock, 'Password'),
                    const SizedBox(height: 40.0),
                    _buildErrorMessage(),
                    const SizedBox(height: 30.0),
                    _buildLoginButton(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
