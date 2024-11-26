import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/Features/User_Auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/login.dart';
import 'package:fyp/global/common/toast.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isSigningUp = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    setState(() {
      passwordError = validatePassword(password)
          ? null
          : "Password must:\n- Be at least 8 characters long\n- Contain at least one uppercase letter\n- Contain at least one digit\n- Contain at least one special character";
    });
  }

  void _validatePasswordMatch() {
    if (_confirmPasswordController.text.trim() !=
        _passwordController.text.trim()) {
      setState(() {
        passwordError = "Passwords do not match";
      });
    } else {
      _validatePassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/Features/User_Auth/Presentation/images/logo.png',
                width: 100,
                height: 150,
              ),
              Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.white60),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    passwordError!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
              SizedBox(height: 20),
              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  labelText: "Confirm Password",
                  labelStyle: const TextStyle(color: Colors.white60),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                enableInteractiveSelection: false, // Disable text selection
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: "")); // Clear clipboard data
                },
                buildCounter:
                    null, // No paste actions will trigger in most cases
              ),

              SizedBox(height: 30),
              GestureDetector(
                onTap: _signUp,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSigningUp
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    setState(() {
      isSigningUp = true;
      passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate that all fields are filled
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showToast(message: "All fields are mandatory.");
      setState(() {
        isSigningUp = false;
      });
      return;
    }

    // Password validation
    if (password != confirmPassword) {
      showToast(message: "Passwords do not match.");
      setState(() {
        isSigningUp = false;
      });
      return;
    }

    // Check if password meets requirements
    if (!validatePassword(password)) {
      setState(() {
        passwordError =
            "Password must:\n- Be at least 8 characters long\n- Contain at least one uppercase letter\n- Contain at least one digit\n- Contain at least one special character";
        isSigningUp = false;
      });
      return;
    }

    try {
      // Register user in Firebase Authentication
      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      // Add email to Firestore for email existence checks
      if (user != null) {
        await _firestore.collection('userAuth').doc(email).set({
          'email': email,
          'createdAt': Timestamp.now(),
        });

        showToast(message: "User is successfully created");
        Navigator.pushNamed(context, "/home");
      } else {
        showToast(message: "An error occurred during signup.");
      }
    } catch (e) {
      showToast(message: "Error: $e");
    } finally {
      setState(() {
        isSigningUp = false;
      });
    }
  }

  bool validatePassword(String password) {
    RegExp passwordRegExp = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&^#_-]).{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }
}
