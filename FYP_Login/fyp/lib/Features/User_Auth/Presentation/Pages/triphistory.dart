import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/home_page.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/mapbox.dart';
import 'package:intl/intl.dart';

class TripHistoryPage extends StatefulWidget {
  final String? tripName;
  final double distance;
  final DateTime? dateTime;
  final int drowsinessCount;

  const TripHistoryPage(
      {super.key,
      required this.tripName,
      required this.distance,
      required this.dateTime,
      required this.drowsinessCount});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
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
