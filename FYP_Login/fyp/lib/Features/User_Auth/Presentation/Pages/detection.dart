import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart'; // For working with LatLng
import 'package:geolocator/geolocator.dart'; // For getting location services

const String openRouteServiceApiKey =
    '5b3ce3597851110001cf62483b9c123314fc4b6fb68d9a9916852467'; // Your OpenRouteService token

class DetectionPage extends StatefulWidget {
  const DetectionPage({Key? key}) : super(key: key);

  @override
  _DetectionPageState createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  late Position _currentPosition;
  bool _locationLoaded = false;
  late MapController _mapController;
  LatLng? _destination;
  List<LatLng> _route = [];

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

    print("Location service enabled: $serviceEnabled");
    print("Location permission status: $permission");

    if (!serviceEnabled || permission == LocationPermission.deniedForever) {
      print("Location service is not enabled or permission is denied forever.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _locationLoaded = true;
    });
    print(
        "Current position: ${_currentPosition.latitude}, ${_currentPosition.longitude}");
  }

  // Geocoding API call to get coordinates of the destination
// Geocoding API call to get coordinates of the destination
  Future<LatLng?> _searchDestination(String query) async {
    // Using a CORS proxy to bypass cross-origin issues in the browser
    final url = Uri.parse(
        'https://cors-anywhere.herokuapp.com/https://api.openrouteservice.org/geocode/search?api_key=$openRouteServiceApiKey&text=$query');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          final coordinates =
              data['features'][0]['geometry']['coordinates'] as List<dynamic>;
          final lat = coordinates[1] as double;
          final lng = coordinates[0] as double;
          print('Destination found: $lat, $lng'); // Debugging
          return LatLng(lat, lng);
        } else {
          print('No results found for the query.');
        }
      } else {
        print('Failed to fetch geocoding data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making HTTP request: $e');
    }
    return null;
  }

  // Directions API call to get the route between current location and destination
  // Future<void> _calculateRoute(LatLng start, LatLng end) async {
  //   final url =
  //       Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');

  //   print("Calculating route from $start to $end");

  //   final headers = {
  //     'Authorization': 'Bearer $openRouteServiceApiKey',
  //     'Content-Type': 'application/json',
  //   };

  //   final body = jsonEncode({
  //     "coordinates": [
  //       [start.longitude, start.latitude],
  //       [end.longitude, end.latitude],
  //     ],
  //   });

  //   try {
  //     final response = await http.post(url, headers: headers, body: body);
  //     print("Route calculation response status: ${response.statusCode}");

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print("Route calculation response: $data");

  //       final geometry = data['features'][0]['geometry']['coordinates'] as List;
  //       final route = geometry
  //           .map((coord) => LatLng(coord[1] as double, coord[0] as double))
  //           .toList();

  //       print('Route calculated: $route');
  //       setState(() {
  //         _route = route;
  //       });
  //     } else {
  //       print('Failed to fetch route data: ${response.statusCode}');
  //       print('Error: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error making HTTP request: $e');
  //   }
  // }

  // Handle search for destination
  void _onSearchDestination(String destination) async {
    print('Searching for destination: $destination'); // Debugging
    final destCoordinates = await _searchDestination(destination);
    if (destCoordinates != null) {
      setState(() {
        _destination = destCoordinates; // Update _destination
        _mapController.move(_destination!, 14.0); // Move map to destination
        print("Destination set: $_destination"); // Debugging output
      });
    } else {
      print('No coordinates found for $destination');
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
                  center: LatLng(
                      _currentPosition.latitude, _currentPosition.longitude),
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
                        point: LatLng(_currentPosition.latitude,
                            _currentPosition.longitude),
                        builder: (context) =>
                            const Icon(Icons.location_on, color: Colors.blue),
                      ),
                      if (_destination != null)
                        Marker(
                          point: _destination!,
                          builder: (context) =>
                              const Icon(Icons.location_on, color: Colors.red),
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
          ],
        ],
      ),
    );
  }
}
