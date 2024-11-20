import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart'; // For working with LatLng
import 'package:geolocator/geolocator.dart'; // For getting location services
import 'package:flutter_map/flutter_map.dart';

const String openRouteServiceApiKey =
    '5b3ce3597851110001cf62483b9c123314fc4b6fb68d9a9916852467'; // OpenRouteService token

class DetectionPage extends StatefulWidget {
  const DetectionPage({Key? key}) : super(key: key);

  @override
  _DetectionPageState createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  late Position _currentPosition;
  bool _locationLoaded = false;
  List<Map<String, dynamic>> _destinationResults =
      []; // List of destinations with their coordinates and distance
  late LatLng _currentLatLng;
  late MapController _mapController;
  List<LatLng> _route = [];
  List<String> _directions = []; // Store turn-by-turn directions
  int _currentDirectionIndex = 0; // Track the current direction

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.deniedForever) {
      return; // Handle the error
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _locationLoaded = true;
      _currentLatLng = LatLng(
          position.latitude, position.longitude); // Set the current location
    });
  }

  // Geocoding API call to get related destinations
  Future<List<Map<String, dynamic>>> _searchDestinations(String query) async {
    final url = Uri.parse(
        'https://cors-anywhere.herokuapp.com/https://api.openrouteservice.org/geocode/search?api_key=$openRouteServiceApiKey&text=$query');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> destinations = [];

        for (var feature in data['features']) {
          final coordinates =
              feature['geometry']['coordinates'] as List<dynamic>;
          final lat = coordinates[1] as double;
          final lng = coordinates[0] as double;

          // Calculate distance from current location
          final destinationLatLng = LatLng(lat, lng);
          final distance =
              _calculateDistance(_currentLatLng, destinationLatLng);

          destinations.add({
            'name': feature['properties']['label'],
            'latLng': destinationLatLng,
            'distance': distance,
          });
        }

        // Sort destinations by distance
        destinations.sort((a, b) => a['distance'].compareTo(b['distance']));
        return destinations;
      } else {
        print('Failed to fetch geocoding data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making HTTP request: $e');
    }
    return [];
  }

  // Calculate the distance between two LatLng points in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    var distanceInMeters = const Distance().as(LengthUnit.Meter, start, end);
    return distanceInMeters / 1000; // Convert meters to kilometers
  }

  // Get directions and turn-by-turn navigation
  Future<void> _getDirections(LatLng destination) async {
    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$openRouteServiceApiKey');

    final body = jsonEncode({
      "coordinates": [
        [_currentLatLng.longitude, _currentLatLng.latitude],
        [destination.longitude, destination.latitude]
      ]
    });

    try {
      final response = await http
          .post(url, body: body, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Log the full response for debugging

        // Check if the response contains valid features and segments
        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry =
              data['features'][0]['geometry']['coordinates'] as List;
          final route = geometry
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          // Ensure that steps exist in the response before accessing them
          if (data['features'][0]['properties']['segments'] != null &&
              data['features'][0]['properties']['segments'].isNotEmpty) {
            final instructions = data['features'][0]['properties']['segments']
                [0]['steps'] as List;
            final directions = instructions
                .map((step) => step['instruction'] as String)
                .toList();

            setState(() {
              _route = route;
              _directions = directions;
            });
          } else {
            print('No segments or steps found in the response');
          }
        } else {
          print('No valid features found in the response');
        }
      } else {
        print('Failed to fetch route data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making HTTP request: $e');
    }
  }

  // Handle search for destination
  void _onSearchDestination(String destination) async {
    final destinations = await _searchDestinations(destination);
    setState(() {
      _destinationResults = destinations;
    });
  }

  // Show next direction
  void _showNextDirection() {
    if (_currentDirectionIndex < _directions.length) {
      setState(() {
        _currentDirectionIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Page'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          if (!_locationLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Destination',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: _onSearchDestination,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentLatLng,
                  zoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLatLng,
                        builder: (context) =>
                            const Icon(Icons.location_on, color: Colors.blue),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_directions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Next Direction:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text(
                _directions[_currentDirectionIndex],
                style: const TextStyle(color: Colors.white),
              ),
              ElevatedButton(
                onPressed: _showNextDirection,
                child: const Text('Next'),
              ),
            ],
            if (_destinationResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Nearby Destinations:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _destinationResults.length,
                  itemBuilder: (context, index) {
                    final destination = _destinationResults[index];
                    return ListTile(
                      title: Text(
                        destination['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${destination['distance'].toStringAsFixed(2)} km away',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _mapController.move(destination['latLng'], 14.0);
                          _getDirections(destination['latLng']);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
