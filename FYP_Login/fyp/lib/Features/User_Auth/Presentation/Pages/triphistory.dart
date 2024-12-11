import 'package:flutter/material.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

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
                        const Text(
                          '2024-12-11 14:30',
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
                        const Text(
                          'Kuala Lumpur City Center',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, thickness: 1),
                    // Distance
                    Column(
                      children: [
                        const Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '25 km',
                          style: TextStyle(
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
                        const Text(
                          '3 times',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
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
