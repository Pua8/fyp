import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/user_profile.dart';
import 'package:fyp/Features/User_Auth/Presentation/Widgets/carousel.dart'; // Import the CarouselWidget

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Navigate to the Profile Page
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
            Navigator.pop(context); // Navigate back to the previous screen
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
        ],
      ),
    );
  }
}
