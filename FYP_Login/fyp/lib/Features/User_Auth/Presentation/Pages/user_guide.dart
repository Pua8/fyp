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
            const SizedBox(height: 20),

            // Introduction Section
            SectionTitle(title: "Introduction"),
            const InfoText(
              text:
                  "Welcome to the Drowsiness Detection System! This system helps monitor your alertness while driving or performing tasks requiring attention. Using camera input, it detects signs of drowsiness and provides notifications to ensure your safety on the road.",
            ),
            const Divider(),
            const SizedBox(height: 20),
            // How to Use Section
            SectionTitle(title: "How to Use the System"),
            const InfoList(items: [
              "Place the camera in an optimal position to monitor your facial features.",
              "Follow the on-screen prompts to begin the drowsiness detection.",
              "The system will monitor your facial features and alert you if signs of drowsiness are detected.",
              "If alerted, take immediate action like pulling over and resting before continuing.",
            ]),
            const Divider(),
            const SizedBox(height: 20),

            // Disclaimer Section
            SectionTitle(title: "Disclaimer"),
            const InfoList(items: [
              "This system assists in detecting drowsiness but is not a substitute for professional judgment or caution.",
              "It may produce false positives or false negatives and should not be solely relied upon.",
              "The developers are not responsible for incidents due to improper use or over-reliance on the system.",
              "The system is only effective when used correctly and within the recommended guidelines.",
            ]),
            const Divider(),
            const SizedBox(height: 20),

            // Navigation Button to Next Page
            const SizedBox(height: 20),
            Center(
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
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}

class InfoText extends StatelessWidget {
  final String text;
  const InfoText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }
}

class InfoList extends StatelessWidget {
  final List<String> items;
  const InfoList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                "• $item",
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}
