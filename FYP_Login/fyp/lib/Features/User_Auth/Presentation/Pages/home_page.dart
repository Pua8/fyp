import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/mapbox.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/user_profile.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/facial_detection.dart';
import 'package:fyp/Features/User_Auth/Presentation/Widgets/carousel.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/user_guide.dart';

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
      body: Column(
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
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                  MaterialPageRoute(builder: (context) => const MapboxPage()),
                );

                // // Start facial detection in the background
                // Future.microtask(() {
                //   RealTimeFacialDetection realTimeFacialDetection =
                //       RealTimeFacialDetection();
                //   realTimeFacialDetection.createState().initializeCamera();
                // });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(width: 10),
                  const Text(
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
          SizedBox(height: 200),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
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
    );
  }
}
