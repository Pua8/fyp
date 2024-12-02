import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  String? selectedDestination;
  List<Map<String, dynamic>> destinationList = [];
  List<LatLng> routeCoordinates = [];
  List<String> directionsSteps = [];
  int currentStepIndex = 0;
  String? currentInstruction = '';
  bool isNavigating = false;

  DateTime? estimatedArrivalTime;
  String? etaText = '';
  String? arrivalText = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    flutterTts = FlutterTts();
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
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(1.0); 
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
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    });
  }

  void _updateStep() {
    if (currentStepIndex < directionsSteps.length - 1) {
      setState(() {
        currentStepIndex++;
        currentInstruction = directionsSteps[currentStepIndex];
      });
      _speakInstruction(currentInstruction!); // Trigger TTS
    } else {
      setState(() {
        currentInstruction = "You have arrived at your destination.";
      });
      _speakInstruction(currentInstruction!); // Final TTS instruction
    }
  }

  Future<void> _getDirections(double destLat, double destLng) async {
    if (currentPosition == null) return;

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

        mapController.addLine(
          LineOptions(
            geometry: routeCoordinates,
            lineColor: "red",
            lineWidth: 15.0,
          ),
        );

        // Get the duration (travel time) and distance from the API response
        final durationInSeconds = data['routes'][0]['duration']; // in seconds
        final distanceInMeters = data['routes'][0]['distance']; // in meters

        // Calculate ETA and Arrival Time using duration and distance from Mapbox
        final duration = Duration(seconds: durationInSeconds.toInt());
        DateTime now = DateTime.now();
        estimatedArrivalTime = now.add(duration);
        etaText = 'ETA: ${duration.inMinutes} min';
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
    if (selectedDestination != null && currentPosition != null) {
      final destination = destinationList
          .firstWhere((element) => element['name'] == selectedDestination);

      _getDirections(destination['latitude'], destination['longitude']);
      setState(() {
        isNavigating = true;
      });
      _startTurnByTurnNavigation();
    } else {
      print('Error: Current position or destination is null');
      // Optionally, show a dialog or snackbar to inform the user.
    }
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
        title: Text('Mapbox Navigation'),
        backgroundColor: Colors.black,
      ),
      body: isNavigating
          ? Stack(
              children: [
                MapboxMap(
                  accessToken:
                      "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w",
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        currentPosition!.latitude, currentPosition!.longitude),
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentInstruction ?? 'No instructions available',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                etaText ?? 'ETA: Calculating...',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              Icon(Icons.navigation, color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                etaText ?? 'ETA: Calculating...',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                arrivalText ?? 'Arrival: Calculating...',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _exitNavigation,
                            child: Text('Exit Navigation'),
                          ),
                          // ElevatedButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       isNavigating = false;
                          //     });
                          //   },
                          //   child: Text('Exit Navigation'),
                          // ),
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
                      zoom: 14.0,
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
                  onPressed: selectedDestination != null ? _startTrip : null,
                  child: Text('Start Trip'),
                ),
              ],
            ),
    );
  }
}
