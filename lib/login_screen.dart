import 'package:flutter/material.dart';
import 'package:rtmpppp/home_screen.dart';

class LoginScreen extends StatelessWidget {
  void _loginButtonPressed(BuildContext context) {
    // TODO: Implement login functionality

    // After successful login, navigate to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Widget _buildTextField(IconData icon, String labelText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
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

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _loginButtonPressed(context);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFFFE4237), backgroundColor: const Color(0xFFFFECEB),
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
                    _buildTextField(Icons.email, 'Email'),
                    const SizedBox(height: 20.0),
                    _buildTextField(Icons.lock, 'Password'),
                    const SizedBox(height: 40.0),
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
