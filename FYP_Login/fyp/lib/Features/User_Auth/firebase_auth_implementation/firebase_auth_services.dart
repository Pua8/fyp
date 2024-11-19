import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../global/common/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = credential.user;

      if (user != null) {
        // Call createUserInFirestore after successful sign-up
        await createUserInFirestore(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<void> createUserInFirestore(User user) async {
    try {
      // Extract username from the email
      String username = user.email!.split('@')[0];

      // Encode email to be a valid Firestore document ID
      String Email = user.email!;

      // Check if the document exists
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(Email).get();

      if (!doc.exists) {
        // Create the Firestore document
        await _firestore.collection('users').doc(Email).set({
          'username': username,
          'email': user.email,
          'createdOn': DateTime.now(),
          'age': null,
          'gender': null,
          'race': null,
        });
        showToast(message: 'User profile created successfully.');
      }
    } catch (e) {
      showToast(message: 'Failed to create user profile: $e');
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }
}
