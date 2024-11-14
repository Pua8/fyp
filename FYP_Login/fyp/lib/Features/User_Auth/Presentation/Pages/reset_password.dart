import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/global/common/toast.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Check if the email exists in Firestore
  Future<bool> _checkEmailExists(String email) async {
    final doc = await _firestore.collection('userAuth').doc(email).get();
    return doc.exists;
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();

      // Verify if the email exists in Firestore
      bool emailExists = await _checkEmailExists(email);

      if (!emailExists) {
        showToast(message: "Email does not exist in our records.");
      } else {
        // If email exists, send the reset password email
        await _auth.sendPasswordResetEmail(email: email);
        showToast(message: "Password reset email sent! Check your inbox.");
        Navigator.pop(context); // Go back to the previous screen
      }
    } on FirebaseAuthException catch (e) {
      // Display Firebase-specific error messages
      String errorMessage;
      if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      } else {
        errorMessage = e.message ?? "An unknown error occurred.";
      }
      showToast(message: "Error: $errorMessage");
    } catch (e) {
      showToast(message: "An error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
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
              "Reset password",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(
              height: 30,
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white), // Text input color
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.email, // Change this to your desired icon
                  color: Colors.white, // Icon color
                ),
                labelText: "Enter your email",
                labelStyle:
                    TextStyle(color: Colors.white60), // Label text color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.white), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.white), // Border color when focused
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Reset Password"),
                  ),
          ],
        ),
      ),
    );
  }
}
