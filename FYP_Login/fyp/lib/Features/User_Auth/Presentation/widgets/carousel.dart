import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CarouselWidget extends StatefulWidget {
  const CarouselWidget({Key? key}) : super(key: key);

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;

  // List of tips for drowsy driving
  final List<String> tips = [
    "Take regular breaks during long drives to stay alert.",
    "Avoid driving between midnight and 6 a.m., \nwhen your body is naturally drowsy.",
    "Drink a cup of coffee or tea if you feel sleepy, \nbut remember it’s a temporary solution.",
    "Pull over and take a quick nap if you're feeling drowsy; \neven 20 minutes can help.",
  ];

  // List of background images for the carousel
  final List<String> imageUrls = [
    'lib/Features/User_Auth/Presentation/images/carousel_image1.jpg',
    'lib/Features/User_Auth/Presentation/images/carousel_image2.jpg',
    'lib/Features/User_Auth/Presentation/images/carousel_image3.jpg', 
    'lib/Features/User_Auth/Presentation/images/carousel_image4.jpg',
  ];

  // Starts auto-scroll with the ability to pause when user interacts
  void _startAutoScroll() {
    _stopAutoScroll(); // Ensure no duplicate timers
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && _pageController.page != null) {
        if (_pageController.page?.toInt() == tips.length - 1) {
          _pageController.jumpToPage(0); // Jump to the first tip
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // Stops the auto-scroll
  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _stopAutoScroll(), // Stop scrolling when user interacts
          onTapUp: (_) => _startAutoScroll(),  // Resume scrolling after interaction
          onHorizontalDragStart: (_) => _stopAutoScroll(), // Stop on drag start
          onHorizontalDragEnd: (_) => _startAutoScroll(),  // Resume on drag end
          child: SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: tips.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image with blur effect
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Image.network(
                          imageUrls[index], // Use the URL of the image
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay the text (tips) on top of the background
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            tips[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _pageController,
          count: tips.length,
          effect: WormEffect(
            dotHeight: 5,
            dotWidth: 10,
            dotColor: Colors.grey.shade400,
            activeDotColor: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }
}
