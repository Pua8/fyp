import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:typed_data';
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
  final String _apiUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<Map<String, dynamic>?> _sendImageToBackend(
      Uint8List imageBytes) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_apiUrl/detect_drowsiness'))
            ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
                filename: 'frame.jpg'));

      debugPrint('Sending request to $_apiUrl...');
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

  Future<void> startImageStreamWeb(
      Function(html.VideoElement videoElement) onAvailable) async {
    assert(kIsWeb, 'startImageStreamWeb is only available on the web.');

    // Create a video element for the webcam feed
    final html.VideoElement videoElement = html.VideoElement();

    try {
      // Access the user's camera
      final mediaStream = await html.window.navigator.mediaDevices
          ?.getUserMedia({'video': true});

      if (mediaStream != null) {
        videoElement.srcObject = mediaStream;
        videoElement.autoplay = true;
        videoElement.muted = true; // Mute to prevent audio issues
        videoElement.play();

        // Wait for video to load metadata and start playing
        videoElement.onLoadedMetadata.listen((event) {
          debugPrint(
              'Video metadata loaded: ${videoElement.videoWidth}x${videoElement.videoHeight}');
          onAvailable(videoElement);
        });

        videoElement.onPlay.listen((event) {
          debugPrint('Video is now playing');
        });
      } else {
        throw Exception('Unable to access the camera.');
      }
    } catch (e) {
      throw Exception('Error accessing the camera: ${e.toString()}');
    }
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
      _startDetectionWeb();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Future<Map<String, dynamic>?> _sendImageToBackend(
  //     Uint8List imageBytes) async {
  //   // Replace with your actual API call
  //   // Example:
  //   final response = await http.post(
  //     Uri.parse('https://your-backend-endpoint.com/detect'),
  //     headers: {'Content-Type': 'application/octet-stream'},
  //     body: imageBytes,
  //   );
  //   if (response.statusCode == 200) {
  //     return json.decode(response.body);
  //   }
  //   return null;
  // }

  Future<Uint8List> _convertBlobToUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>(); // Ensure dart:async is imported
    reader.readAsArrayBuffer(blob);
    reader.onLoadEnd.listen((_) {
      completer.complete(Uint8List.fromList(reader.result as List<int>));
    });
    return completer.future;
  }

  static int HAVE_ENOUGH_DATA = 4; // Add this at the top of your file

  Future<void> _startDetectionWeb() async {
    await startImageStreamWeb((html.VideoElement videoElement) async {
      final html.CanvasElement canvas = html.CanvasElement();

      // Set canvas dimensions after video metadata is loaded
      canvas.width = videoElement.videoWidth;
      canvas.height = videoElement.videoHeight;
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;

      // Periodically process frames using Timer.periodic
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (_isDetecting ||
            videoElement.videoWidth == 0 ||
            videoElement.videoHeight == 0) {
          debugPrint('Video not ready or dimensions are zero. Skipping frame.');
          return;
        }

        _isDetecting = true;
        try {
          // Draw the current video frame to the canvas
          ctx.drawImage(videoElement, 0, 0);

          // Get the image data as a JPEG
          final blob = await canvas.toBlob('image/jpeg');

          if (blob != null) {
            final imageBytes = await _convertBlobToUint8List(blob);

            // Send the image to the backend for analysis
            final result = await _sendImageToBackend(imageBytes);

            // Display results
            if (result != null) {
              if (result['mouth_open'] == true) debugPrint('Mouth open!');
              if (result['eyes_closed'] == true) debugPrint('Eyes closed!');
              if (result['alert_triggered'] == true) {
                debugPrint('Drowsiness detected!');
              }
            }
          } else {
            debugPrint('Failed to convert canvas to Blob.');
          }
        } catch (e) {
          debugPrint('Error: $e');
        } finally {
          _isDetecting = false;
        }
      });
    });
  }

  // void _startDetectionWeb() async {
  //   // Ensure we are running on the web
  //   if (!kIsWeb) {
  //     debugPrint('This function is only available on the web.');
  //     return;
  //   }

  //   Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
  //     // Convert YUV420 CameraImage to JPEG format
  //     final List<int> bytes = [];

  //     for (final Plane plane in image.planes) {
  //       bytes.addAll(plane.bytes);
  //     }

  //     return Uint8List.fromList(bytes);
  //   }

  //   void _startDetection() {
  //     _cameraController!.startImageStream((CameraImage image) async {
  //       if (_isDetecting) return;
  //       _isDetecting = true;

  //       try {
  //         // Convert CameraImage to a format suitable for API request
  //         final imageBytes = await _convertCameraImageToJpeg(image);

  //         // Send the image to the backend for drowsiness detection
  //         final result = await _sendImageToBackend(imageBytes);

  //         // Display result in debug console or UI
  //         if (result != null) {
  //           if (result['mouth_open'] == true) {
  //             debugPrint('Mouth open!');
  //           }
  //           if (result['eyes_closed'] == true) {
  //             debugPrint('Eyes closed!');
  //           }
  //           if (result['alert_triggered'] == true) {
  //             debugPrint('Drowsiness detected!');
  //           }
  //         }
  //       } catch (e) {
  //         debugPrint('Error: $e');
  //       } finally {
  //         _isDetecting = false;
  //       }
  //     });
  //   }

  //   @override
  //   void dispose() {
  //     _cameraController?.dispose();
  //     super.dispose();
  //   }
  // }

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
