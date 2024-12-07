import 'package:flutter/material.dart';
import 'package:fyp/Features/User_Auth/Presentation/Pages/home_page.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.asset(
              'lib/Features/User_Auth/Presentation/images/logo.png',
              width: 100,
              height: 150,
            ),
            // Introduction Section
            SectionTitle(title: "Introduction"),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Welcome to the Drowsiness Detection System! This system is designed to help monitor your level of alertness while driving or performing other tasks that require attention. It uses camera input to detect signs of drowsiness and provides notifications to help you stay safe on the road.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const Divider(),

            // How to Use Section
            SectionTitle(title: "How to Use the System"),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "1. Make sure the system is properly set up on your device.\n\n"
                "2. Ensure the camera or sensor is placed in an optimal position to monitor your facial features or eye movement.\n\n"
                "3. Follow the on-screen prompts to begin the drowsiness detection.\n\n"
                "4. The system will monitor your facial features and alert you if any signs of drowsiness are detected.\n\n"
                "5. In case of an alert, take immediate action such as pulling over and resting before continuing your task.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const Divider(),

            // Disclaimer Section
            SectionTitle(title: "Disclaimer"),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "1. This system is designed to assist in detecting drowsiness, but it is not a replacement for professional judgment or caution. The system is not infallible and may produce false positives or false negatives.\n\n"
                "2. The system should not be relied upon solely to determine if you are fit to continue driving or performing tasks. Always prioritize your own alertness and well-being.\n\n"
                "3. The developers are not responsible for any accidents or incidents that occur due to improper use or over-reliance on the system.\n\n"
                "4. This system is only effective when used correctly and within the recommended usage guidelines.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const Divider(),

            // Navigation Button to Next Page
            const SizedBox(height: 20),
            Center(
              // Centering the button
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Let\'s Go!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}
