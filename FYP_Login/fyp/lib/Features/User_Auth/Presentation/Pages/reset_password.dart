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
      // Check if the email exists in Firebase
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(
        _emailController.text.trim(),
      );

      if (signInMethods.isEmpty) {
        // If the email does not exist
        showToast(message: "Email does not exist in our records.");
      } else {
        // If the email exists, send the reset password email
        await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
        showToast(message: "Password reset email sent! Check your inbox.");
        Navigator.pop(context); // Go back to the previous screen
      }
    } on FirebaseAuthException catch (e) {
      // Check for specific error codes to customize the message
      String errorMessage;
      if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      } else {
        errorMessage = e.message ?? "An unknown error occurred.";
      }
      showToast(message: "Error: $errorMessage");
    } catch (e) {
      showToast(message: "An error occurred. Please try again.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Enter your email to reset your password",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person, color: Colors.white),
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white),
                hintText: "Enter your email",
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
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
