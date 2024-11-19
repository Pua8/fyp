import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/widgets/text_box.dart';
import 'package:intl/intl.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<UserProfile> {
  // Get current user
  final currentUser = FirebaseAuth.instance.currentUser!;
  // all users
  final userCollection = FirebaseFirestore.instance.collection("users");

  //edit field
  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          //cancel button
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              )),
          //save button
          TextButton(
              onPressed: () => Navigator.of(context).pop(newValue),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white),
              )),
        ],
      ),
    );

    //Update firestore
    if (newValue.trim().length > 0) {
      //only update when there is something in the text field
      await userCollection.doc(currentUser.email).update({field: newValue});
    }
  }

  Future<void> editAge(String field) async {
    int? newAge; // Use an integer to store the new age
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number, // Restrict input to numbers
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter your age (18 or above)",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            int? enteredAge = int.tryParse(value); // Convert input to integer
            if (enteredAge != null && enteredAge >= 18) {
              newAge = enteredAge; // Only accept valid ages (18 or above)
            } else {
              newAge = null; // Reset to null if input is invalid
            }
          },
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Save button
          TextButton(
            onPressed: () {
              if (newAge != null) {
                Navigator.of(context).pop(newAge.toString());
              } else {
                // Optionally show an error message
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Please enter a valid age (18 or above)."),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // Update Firestore
    if (newAge != null) {
      await userCollection.doc(currentUser.email).update({field: newAge});
    }
  }

  // Function to edit gender using radio buttons
  Future<void> editGender(String field) async {
    String? newValue;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Male Radio Button
            RadioListTile<String>(
              title: const Text(
                "Male",
                style: TextStyle(color: Colors.white),
              ),
              value: "Male",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.white, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),

            // Female Radio Button
            RadioListTile<String>(
              title: const Text(
                "Female",
                style: TextStyle(color: Colors.white),
              ),
              value: "Female",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.white, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),

            // Others Radio Button
            RadioListTile<String>(
              title: const Text(
                "Others",
                style: TextStyle(color: Colors.white),
              ),
              value: "Others",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.white, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),
          ],
        ),
        actions: [
          // Cancel button
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              )),
          // Save button
          TextButton(
              onPressed: () {
                if (newValue != null) {
                  Navigator.of(context).pop(newValue);
                }
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white),
              )),
        ],
      ),
    );

    // Update Firestore if a valid selection is made
    if (newValue != null) {
      await userCollection.doc(currentUser.email).update({field: newValue});
    }
  }

  // Function to edit race using radio buttons
  Future<void> editRace(String field) async {
    String? newValue;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Malay Radio Button
            RadioListTile<String>(
              title: const Text(
                "Malay",
                style: TextStyle(color: Colors.white),
              ),
              value: "Malay",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.red, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),

            // Chinese Radio Button
            RadioListTile<String>(
              title: const Text(
                "Chinese",
                style: TextStyle(color: Colors.white),
              ),
              value: "Chinese",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.red, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),

            // Indian Radio Button
            RadioListTile<String>(
              title: const Text(
                "Indian",
                style: TextStyle(color: Colors.white),
              ),
              value: "Indian",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.red, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),

            // Others Radio Button
            RadioListTile<String>(
              title: const Text(
                "Others",
                style: TextStyle(color: Colors.white),
              ),
              value: "Others",
              groupValue: newValue,
              onChanged: (String? value) {
                newValue = value;
                setState(() {});
              },
              activeColor: Colors.red, // Active color for radio button
              tileColor:
                  Colors.grey[900], // Background color for the radio tile
            ),
          ],
        ),
        actions: [
          // Cancel button
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              )),
          // Save button
          TextButton(
              onPressed: () {
                if (newValue != null) {
                  Navigator.of(context).pop(newValue);
                }
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white),
              )),
        ],
      ),
    );

    // Update Firestore if a valid selection is made
    if (newValue != null) {
      await userCollection.doc(currentUser.email).update({field: newValue});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "Profile Page",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};

            //print("Fetching data for email: ${currentUser.email}");

            String createdOnFormatted = userData['createdOn'] is Timestamp
                ? DateFormat('yyyy-MM-dd') // Format: Year-Month-Day
                    .format((userData['createdOn'] as Timestamp).toDate())
                : 'N/A';

            return ListView(
              children: [
                const SizedBox(height: 50),

                // Profile pic
                const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 72,
                ),

                // User email
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: const Text(
                    'My Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // Username
                MyTextBox(
                  text: userData['username'] ?? 'N/A',
                  sectionName: "Username",
                  onPressed: () => editField('username'),
                ),

                // Date Created
                TextBoxDate(
                  text: createdOnFormatted,
                  sectionName: "Date Created",
                ),

                //Age
                MyTextBox(
                  text: userData['age'] != null
                      ? userData['age'].toString()
                      : 'N/A',
                  sectionName: "Age",
                  onPressed: () => editAge('age'),
                ),

                //Gender
                MyTextBox(
                  text: userData['gender'] ?? 'N/A',
                  sectionName: "Gender",
                  onPressed: () => editGender('gender'),
                ),

                //Race
                MyTextBox(
                  text: userData['race'] ?? 'N/A',
                  sectionName: "Race",
                  onPressed: () => editRace('race'),
                ),

                // Logout Button
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      // Navigate to the login screen or welcome page
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey[900], // Background grey (900)
                      side: const BorderSide(
                        color: Colors.red, // Red border
                        width: 2, // Border thickness
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red, // Font color red
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
