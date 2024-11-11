import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/global/common/toast.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      showToast(message: "Password reset email sent!");
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      showToast(message: "Error: ${e.toString()}");
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/Features/User_Auth/Presentation/images/logo.png',
              width: 100,
              height: 150,
            ),
            Text(
              "Reset Password",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              "Enter your email to reset your password",
              style: TextStyle(
                  fontSize: 18, color: Colors.white), // Set title color
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,

              // Set input text color and hint style
              style: TextStyle(color: Colors.white), // Text color
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person, color: Colors.white),
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white), // Label text color
                hintText: "Enter your email",
                hintStyle: TextStyle(color: Colors.white70), // Hint text color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.white), // Enabled border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.blueAccent), // Focused border color
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Send Reset Email"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
