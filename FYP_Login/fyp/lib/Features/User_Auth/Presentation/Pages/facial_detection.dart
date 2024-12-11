import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'globals.dart';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
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
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  final String _apiUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<Map<String, dynamic>?> _sendImageToBackend(
      Uint8List imageBytes) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_apiUrl/detect_drowsiness'))
            ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
                filename: 'frame.jpg'));

      // debugPrint('Sending request to $_apiUrl...');
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

  Future<void> initializeCamera() async {
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
      startDetectionWeb();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<Uint8List> _convertBlobToUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>(); // Ensure dart:async is imported
    reader.readAsArrayBuffer(blob);
    reader.onLoadEnd.listen((_) {
      completer.complete(Uint8List.fromList(reader.result as List<int>));
    });
    return completer.future;
  }

  static int HAVE_ENOUGH_DATA = 4;

  Future<void> _playAlarm() async {
    if (!_isAlarmPlaying) {
      _isAlarmPlaying = true;
      try {
        if (kIsWeb) {
          // Use html.AudioElement for web
          final audio = html.AudioElement()
            ..src = 'lib/Features/User_Auth/Presentation/sound/AlertSound.wav'
            ..autoplay = true;
          audio.play();
        } else {
          // Use AssetSource for mobile
          await _audioPlayer.play(AssetSource(
              'lib/Features/User_Auth/Presentation/sound/AlertSound.wav'));
        }
      } catch (e) {
        debugPrint('Error playing alarm: $e');
      }
    }
  }

  Future<void> _stopAlarm() async {
    if (_isAlarmPlaying) {
      _isAlarmPlaying = false;
      if (kIsWeb) {
        // Use JavaScript to stop all audio elements
        final script = html.document.querySelector('audio');
        script?.remove(); // Remove audio element to stop playback
      } else {
        await _audioPlayer.stop();
      }
    }
  }

  Future<void> startDetectionWeb() async {
    await startImageStreamWeb((html.VideoElement videoElement) async {
      final html.CanvasElement canvas = html.CanvasElement();

      canvas.width = videoElement.videoWidth;
      canvas.height = videoElement.videoHeight;
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;

      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (_isDetecting ||
            videoElement.videoWidth == 0 ||
            videoElement.videoHeight == 0) {
          return;
        }

        _isDetecting = true;
        try {
          ctx.drawImage(videoElement, 0, 0);

          final blob = await canvas.toBlob('image/jpeg');

          if (blob != null) {
            final imageBytes = await _convertBlobToUint8List(blob);

            final result = await _sendImageToBackend(imageBytes);

            if (result != null) {
              // if (result['mouth_open'] == true &&
              //     result['eyes_closed'] == false) {
              //   debugPrint('Mouth open!');
              // } else if (result['eyes_closed'] == true &&
              //     result['mouth_open'] == false) {
              //   debugPrint('Eyes closed!');
              // } else if (result['mouth_open'] == true &&
              //     result['eyes_closed'] == true) {
              //   debugPrint('Both mouth open and eyes closed detected!');
              // }
              if (result['alert_triggered'] == true) {
                debugPrint('Drowsiness detected!');
                _playAlarm();
                drowsinessCounter++;
              } else {
                _stopAlarm();
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
