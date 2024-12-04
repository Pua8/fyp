import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:camera/camera.dart'; // For mobile platforms
import 'package:camera_web/camera_web.dart'; // For web platform

class RealTimeFacialDetection extends StatefulWidget {
  const RealTimeFacialDetection({super.key});

  @override
  _RealTimeFacialDetectionState createState() =>
      _RealTimeFacialDetectionState();
}

class _RealTimeFacialDetectionState extends State<RealTimeFacialDetection> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  final String _apiUrl = 'https://localhost:8000';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available!');
        return;
      }
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      _startDetection();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startDetection() {
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        // Convert CameraImage to a format suitable for API request
        final imageBytes = await _convertCameraImageToJpeg(image);

        // Send the image to the backend for drowsiness detection
        final result = await _sendImageToBackend(imageBytes);

        // Display result in debug console or UI
        if (result != null) {
          if (result['mouth_open'] == true) {
            debugPrint('Mouth open!');
          }
          if (result['eyes_closed'] == true) {
            debugPrint('Eyes closed!');
          }
          if (result['alert_triggered'] == true) {
            debugPrint('Drowsiness detected!');
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
    // Convert YUV420 CameraImage to JPEG format
    final List<int> bytes = [];

    for (final Plane plane in image.planes) {
      bytes.addAll(plane.bytes);
    }

    return Uint8List.fromList(bytes);
  }

  Future<Map<String, dynamic>?> _sendImageToBackend(
      Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
            filename: 'frame.jpg'));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData);
      } else {
        debugPrint('Failed to send request: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error sending request: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Drowsiness Detection'),
      ),
      body: Column(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          SizedBox(height: 20),
          Text('Detecting Drowsiness...', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
