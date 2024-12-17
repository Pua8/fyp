import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripHistoryPage extends StatefulWidget {
  final String? tripName;
  final DateTime? dateTime;
  final int drowsinessCount;

  const TripHistoryPage(
      {super.key,
      required this.tripName,
      required this.dateTime,
      required this.drowsinessCount});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  // Upload Trip History to Firestore
  Future<void> uploadTripHistory() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      Fluttertoast.showToast(msg: "User not logged in!");
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final tripHistoryRef =
        firestore.collection('users').doc(userEmail).collection('tripHistory');

    try {
      await tripHistoryRef.add({
        'tripName': widget.tripName ?? 'No Destination Provided',
        'dateTime': widget.dateTime?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'drowsinessCount': widget.drowsinessCount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fluttertoast.showToast(msg: "Trip history uploaded successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to upload trip history: $e");
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
              // Logo at the top
              Image.asset(
                'lib/Features/User_Auth/Presentation/images/logo.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 16),
              // Dialog-like container for trip details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Trip Summary',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date & Time
                    Column(
                      children: [
                        const Text(
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.dateTime != null
                              ? DateFormat('yyyy MMMM dd HH:mm:ss')
                                  .format(widget.dateTime!)
                              : 'No Date Provided',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, thickness: 1),
                    // Destination
                    Column(
                      children: [
                        const Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Use widget.tripName here
                        Text(
                          widget.tripName ?? "No Destination Provided",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, thickness: 1),
                    // Drowsiness Detected
                    Column(
                      children: [
                        const Text(
                          'Drowsiness Detected',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.drowsinessCount.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Upload trip history
                        await uploadTripHistory();

                        // Show a toast message
                        Fluttertoast.showToast(
                            msg: "Thank you and have a nice day!");

                        // Navigate to the HomePage
                        Future.delayed(const Duration(milliseconds: 500), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                          );
                        });
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
