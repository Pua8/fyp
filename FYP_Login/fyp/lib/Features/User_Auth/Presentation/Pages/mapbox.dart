import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapboxPage extends StatefulWidget {
  @override
  _MapboxPageState createState() => _MapboxPageState();
}

class _MapboxPageState extends State<MapboxPage> {
  late MapboxMapController mapController;
  Position? currentPosition;
  String? selectedDestination;
  List<Map<String, dynamic>> destinationList = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

        // Parse the search results
        final List<Map<String, dynamic>> results = (data['features'] as List)
            .map((feature) {
              double lat = feature['geometry']['coordinates'][1];
              double lng = feature['geometry']['coordinates'][0];

              double distance = 0.0;
              if (currentPosition != null) {
                // Calculate distance between user's location and destination
                distance = Geolocator.distanceBetween(
                    currentPosition!.latitude,
                    currentPosition!.longitude,
                    lat,
                    lng);
              }

              return {
                'name': feature['place_name'],
                'distance': distance / 1000, // Convert to km
                'latitude': lat,
                'longitude': lng,
              };
            })
            .toList();

        // Sort by distance (ascending)
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

  void _startTrip() {
    if (selectedDestination != null) {
      // Navigate to selected destination using Mapbox Directions API
      print('Starting trip to $selectedDestination');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mapbox Page',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // Ensure the background contrasts the text
      ),
      body: currentPosition == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: MapboxMap(
                    accessToken:
                        "pk.eyJ1IjoicHVhLXphYyIsImEiOiJjbTQ0YjI5YjAwaWhlMmtzZmkzOTEwNmMyIn0.XsV8HXy-GZabhruNLRCa5w",
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      zoom: 14.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for a destination',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
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
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Distance: ${destination['distance'].toStringAsFixed(2)} km',
                          style: TextStyle(color: Colors.white70),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Start Trip'),
                ),
              ],
            ),
      backgroundColor: Colors.black, // Make the background black
    );
  }
}
