import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fyp/Features/User_Auth/Presentation/Pages/facial_detection.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

  @override
  State<MapboxPage> createState() => _MapboxPageState();
}

class _MapboxPageState extends State<MapboxPage> {
  late FlutterTts flutterTts;
  late MapboxMapController mapController;
  Position? currentPosition;
  Timer? _timer;
  String? selectedDestination;
  List<Map<String, dynamic>> destinationList = [];
  List<LatLng> routeCoordinates = [];
  List<String> directionsSteps = [];
  int _currentSimulatedIndex = 0;
  int currentStepIndex = 0;
  String? currentInstruction = '';
  bool isNavigating = false;
  bool hasArrived = false;
  DateTime? estimatedArrivalTime;
  String? etaText = '';
  String? arrivalText = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    flutterTts = FlutterTts();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer
    flutterTts.stop(); // Stop ongoing TTS operations
    super.dispose(); // Dispose of the TTS instance
  }

  // void _updateETA(Position currentPosition, double destLat, double destLng) {
  //   final distanceRemaining = Geolocator.distanceBetween(
  //     currentPosition.latitude,
  //     currentPosition.longitude,
  //     destLat,
  //     destLng,
  //   );

  //   final speedInMetersPerSecond = currentPosition.speed; // speed in m/s
  //   if (speedInMetersPerSecond > 0) {
  //     final remainingTimeInSeconds = distanceRemaining / speedInMetersPerSecond;
  //     final duration = Duration(seconds: remainingTimeInSeconds.toInt());

  //     setState(() {
  //       estimatedArrivalTime = DateTime.now().add(duration);
  //       etaText = 'ETA: ${duration.inMinutes} min';
  //       arrivalText =
  //           'Arrival: ${DateFormat('hh:mm a').format(estimatedArrivalTime!)}';
  //     });
  //   }
  // }

  void _simulateDriving() {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_currentSimulatedIndex < routeCoordinates.length) {
        setState(() {
          currentPosition = Position(
            latitude: routeCoordinates[_currentSimulatedIndex].latitude,
            longitude: routeCoordinates[_currentSimulatedIndex].longitude,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 5.0,
            headingAccuracy: 5.0,
          );
        });

        // Calculate remaining distance from current position to destination
        double remainingDistance = 0.0;
        if (currentPosition != null) {
          remainingDistance = Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            routeCoordinates.last.latitude,
            routeCoordinates.last.longitude,
          );
        }

        // // Estimate remaining time (assuming average speed of 5 m/s)
        // double remainingTimeInSeconds = remainingDistance / 5;
        // Duration remainingDuration =
        //     Duration(seconds: remainingTimeInSeconds.toInt());

        // // Update ETA
        // DateTime now = DateTime.now();
        // DateTime newEstimatedArrivalTime = now.add(remainingDuration);

        // setState(() {
        //   etaText = 'ETA: ${remainingDuration.inMinutes} min';
        //   arrivalText =
        //       'Arrival: ${DateFormat('hh:mm a').format(newEstimatedArrivalTime)}';
        // });

        // Move to the next step if the user is close enough to the current step
        final stepLocation = LatLng(
          routeCoordinates[_currentSimulatedIndex].latitude,
          routeCoordinates[_currentSimulatedIndex].longitude,
        );

        final distanceToNextStep = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          stepLocation.latitude,
          stepLocation.longitude,
        );

        if (distanceToNextStep < 50) {
          _updateStep();
        }

        // Update the camera position to simulate navigation
        if (currentPosition != null) {
          mapController.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                    currentPosition!.latitude, currentPosition!.longitude),
                zoom: 16.5,
                tilt: 45.0,
                bearing: 0.0,
              ),
            ),
          );
        }

        _currentSimulatedIndex++;
      } else if (!hasArrived) {
        // If destination is reached, announce arrival
        setState(() {
          currentInstruction = "You have arrived at your destination.";
        });
        _speakInstruction(currentInstruction!); // Final TTS instruction
        _timer?.cancel();
      }
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;

    if (currentPosition != null) {
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(currentPosition!.latitude, currentPosition!.longitude),
            zoom: 16.5,
            tilt: 45.0,
            bearing: 0.0,
          ),
        ),
      );
    } else {
      // Default camera position if location is unavailable
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(0.0, 0.0),
            zoom: 16.5,
            tilt: 45.0,
            bearing: 0.0,
          ),
        ),
      );
    }
  }

  Future<void> _searchDestination(String query) async {
    if (query.isEmpty) return;

    final accessToken =
        "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w";
    final apiUrl =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> results =
            (data['features'] as List).map((feature) {
          double lat = feature['geometry']['coordinates'][1];
          double lng = feature['geometry']['coordinates'][0];

          double distance = 0.0;
          if (currentPosition != null) {
            distance = Geolocator.distanceBetween(currentPosition!.latitude,
                currentPosition!.longitude, lat, lng);
          }

          return {
            'name': feature['place_name'],
            'distance': distance / 1000, // in km
            'latitude': lat,
            'longitude': lng,
          };
        }).toList();

        results.sort((a, b) => a['distance'].compareTo(b['distance']));

        setState(() {
          destinationList = results;
        });
      } else {
        print('Error fetching search results: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _speakInstruction(String instruction) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.5);
    await flutterTts.setSpeechRate(2.5);
    await flutterTts.speak(instruction);
  }

  void _startTurnByTurnNavigation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when the user moves 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        currentPosition = position;
      });

      // If the destination is set, update the ETA
      if (selectedDestination != null) {
        final destination = destinationList.firstWhere(
          (element) => element['name'] == selectedDestination,
          orElse: () => throw Exception('Destination not found'),
        );
        // _updateETA(position, destination['latitude'], destination['longitude']);
      }

      // Handle step updates
      if (directionsSteps.isNotEmpty) {
        final currentStep = directionsSteps[currentStepIndex];
        final stepLocation = LatLng(
          routeCoordinates[currentStepIndex].latitude,
          routeCoordinates[currentStepIndex].longitude,
        );

        final distanceToNextStep = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          stepLocation.latitude,
          stepLocation.longitude,
        );

        if (distanceToNextStep < 50) {
          _updateStep();
        }
      }

      // Update camera position
      if (currentPosition != null) {
        mapController.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  position.latitude, position.longitude), // Set user's location
              zoom: 16.5,
              tilt: 45.0,
              bearing: 0.0,
            ),
          ),
        );
      }
    });
  }

  void _updateStep() {
    if (currentStepIndex < directionsSteps.length - 1) {
      if (mounted) {
        setState(() {
          currentStepIndex++;
          currentInstruction = directionsSteps[currentStepIndex];
        });
      }
      _speakInstruction(currentInstruction!); // Trigger TTS
    } else {
      if (mounted) {
        setState(() {
          currentInstruction = "You have arrived at your destination.";
        });
      }
      _speakInstruction(currentInstruction!); // Final TTS instruction
      _timer?.cancel(); // Cancel any ongoing timers
    }
  }

  Future<void> _getDirections(double destLat, double destLng) async {
    if (currentPosition == null) {
      print('Error: Current position is null');
      return;
    }

    final accessToken =
        "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w";
    final directionsApiUrl =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${currentPosition!.longitude},${currentPosition!.latitude};$destLng,$destLat?geometries=geojson&steps=true&access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(directionsApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes'][0]['geometry']['coordinates'];
        final steps = data['routes'][0]['legs'][0]['steps'];

        setState(() {
          directionsSteps = steps.map<String>((step) {
            var instruction = step['maneuver']['instruction'];
            return instruction != null ? instruction.toString() : '';
          }).toList();
          currentInstruction =
              directionsSteps.isNotEmpty ? directionsSteps[0] : '';
        });

        routeCoordinates =
            route.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();

        // Start simulated movement once directions are fetched
        _simulateDriving();

        // Get the duration (travel time) and distance from the API response
        final durationInSeconds = data['routes'][0]['duration']; // in seconds
        final distanceInMeters = data['routes'][0]['distance']; // in meters

        // Calculate ETA and Arrival Time using duration and distance from Mapbox
        final duration = Duration(seconds: durationInSeconds.toInt());
        DateTime now = DateTime.now();
        estimatedArrivalTime = now.add(duration);
        arrivalText =
            'Arrival: ${DateFormat('hh:mm a').format(estimatedArrivalTime!)}';
      } else {
        print('Error fetching directions: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _startTrip() {
    if (selectedDestination == null || currentPosition == null) {
      print('Error: Selected destination or current position is null');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Trip'),
          content: Text(
            'Heading to $selectedDestination',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cancel the trip
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Proceed with starting the trip
                Navigator.of(context).pop(); // Close the dialog

                try {
                  final destination = destinationList.firstWhere(
                    (element) => element['name'] == selectedDestination,
                    orElse: () {
                      throw Exception(
                          'Selected destination not found in the list.');
                    },
                  );

                  _getDirections(
                          destination['latitude'], destination['longitude'])
                      .then((_) {
                    if (directionsSteps.isEmpty || routeCoordinates.isEmpty) {
                      print('Error: No directions or route data available.');
                      return;
                    }
                    setState(() {
                      isNavigating = true;
                    });
                    _startTurnByTurnNavigation();
                  });
                } catch (e) {
                  print('Error: $e');
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Yes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _nextStep() {
    if (currentStepIndex < directionsSteps.length - 1) {
      setState(() {
        currentStepIndex++;
        currentInstruction = directionsSteps[currentStepIndex];
      });
    }
  }

  // Function to handle exit navigation
  void _exitNavigation() async {
    _timer?.cancel();
    await flutterTts.stop(); // Stop any ongoing TTS
    setState(() {
      isNavigating = false;
      selectedDestination = null; // Reset destination
      directionsSteps.clear(); // Clear the directions
      routeCoordinates.clear(); // Clear the route coordinates
      currentStepIndex = 0; // Reset step index
      currentInstruction = ''; // Reset instruction
      etaText = ''; // Reset ETA
      arrivalText = ''; // Reset arrival time
    });
  }

  @override
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
      ),
      body: isNavigating
          ? Stack(
              children: [
                MapboxMap(
                  accessToken:
                      "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w",
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(currentPosition?.latitude ?? 0.0,
                        currentPosition?.longitude ?? 0.0),
                    zoom: 16.5,
                    tilt: 45.0,
                    bearing: 0.0,
                  ),
                  myLocationEnabled: true,
                  myLocationTrackingMode: MyLocationTrackingMode
                      .TrackingCompass, // User heading view
                  tiltGesturesEnabled:
                      true, // Allow tilting for better navigation experience
                  compassEnabled: true, // Show the compass
                  // myLocationRenderMode: kIsWeb
                  //     ? MyLocationRenderMode.NORMAL // Default for web
                  //     : MyLocationRenderMode.COMPASS, // Adjust for mobile
                ),
                // myLocationTrackingMode: MyLocationTrackingMode.None,
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Heading to $selectedDestination',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            currentInstruction ?? 'Fetching directions...',
                            style: const TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            arrivalText ?? 'Arrival: Calculating...',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _exitNavigation,
                            child: Text('Exit Navigation'),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: MapboxMap(
                    accessToken:
                        "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w",
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentPosition?.latitude ?? 0.0,
                          currentPosition?.longitude ?? 0.0),
                      zoom: 16.5,
                      tilt: 45.0,
                      bearing: 0.0,
                    ),
                    myLocationEnabled: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for a destination',
                      hintStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    onSubmitted: _searchDestination,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: destinationList.length,
                    itemBuilder: (context, index) {
                      final destination = destinationList[index];
                      return ListTile(
                        title: Text(
                          destination['name'],
                          style: TextStyle(
                              color: Colors
                                  .white), // Title text color set to white
                        ),
                        subtitle: Text(
                          'Distance: ${destination['distance'].toStringAsFixed(2)} km',
                          style: TextStyle(
                              color: Colors
                                  .white), // Subtitle text color set to white
                        ),
                        onTap: () {
                          setState(() {
                            selectedDestination = destination['name'];
                          });
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDestination != null) {
                      _startTrip();
                    }

                    // Start facial detection in the background
                    Future.microtask(() {
                      RealTimeFacialDetection realTimeFacialDetection =
                          RealTimeFacialDetection();
                      realTimeFacialDetection.createState().initializeCamera();
                    });
                  },
                  child: Text('Start Trip'),
                ),
              ],
            ),
    );
  }
}
