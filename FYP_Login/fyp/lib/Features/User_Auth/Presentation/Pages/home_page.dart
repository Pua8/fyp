import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/mapbox.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/user_profile.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/user_guide.dart';
import 'package:fyp/Features/User_Auth/Presentation/Widgets/carousel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void ProfilePage(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserProfile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Image.asset(
          'lib/Features/User_Auth/Presentation/images/logo.png',
          height: 50,
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: () => ProfilePage(context),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap the body with SingleChildScrollView
        child: Column(
          children: [
            const SizedBox(height: 25),
            Text(
              "BangunLah wishing you a safe trip!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const CarouselWidget(),
            const SizedBox(height: 25),

            // Trip History Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Trip History",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Trip History Section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.email)
                  .collection('tripHistory')
                  .orderBy('createdAt', descending: true)
                  .limit(3) // Top X latest trips
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No trip history available.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                final trips = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap:
                      true, // Prevent overflow by allowing the ListView to take only necessary space
                  physics:
                      NeverScrollableScrollPhysics(), // Disable scroll on ListView to prevent conflict with outer scroll
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final dateTime = (trip['dateTime'] != null)
                        ? DateTime.parse(trip['dateTime'])
                        : DateTime.now();

                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Center(
                          // Center the title
                          child: Text(
                            trip['tripName'] ?? 'Unknown Destination',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign
                                .center, // Ensure the title text is centered
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Center the column content
                          children: [
                            Text(
                              DateFormat('yyyy MMMM dd HH:mm:ss')
                                  .format(dateTime),
                              style: const TextStyle(color: Colors.white70),
                              textAlign:
                                  TextAlign.center, // Center the date text
                            ),
                            Text(
                              'Drowsiness Count: ${trip['drowsinessCount']}',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign
                                  .center, // Center the drowsiness count text
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 25),

            // Start Driving Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    // Navigate to MapboxPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MapboxPage()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 60,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Start Driving',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // User Guide Link
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserGuidePage()),
                );
              },
              child: Text(
                'User Guide',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
