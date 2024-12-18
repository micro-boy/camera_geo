import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const PhotoGeolocationApp());
}

class PhotoGeolocationApp extends StatelessWidget {
  const PhotoGeolocationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PhotoGeolocationScreen(),
    );
  }
}

class PhotoGeolocationScreen extends StatefulWidget {
  const PhotoGeolocationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PhotoGeolocationScreenState createState() => _PhotoGeolocationScreenState();
}

class _PhotoGeolocationScreenState extends State<PhotoGeolocationScreen> {
  CameraController? _cameraController;
  Position? _currentPosition;
  XFile? _photo;
  String? _location;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(cameras.first, ResolutionPreset.high);
    await _cameraController?.initialize();
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _location = 'Lat: ${position.latitude}, Long: ${position.longitude}';
    });
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final photo = await _cameraController!.takePicture();
      setState(() {
        _photo = photo;
      });
    } catch (e) {
      print('Error taking photo: $e');
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
        title: const Text('Photo with Geolocation'),
      ),
      body: Column(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _takePhoto,
            child: const Text('Take Photo'),
          ),
          if (_photo != null) ...[
            Image.file(File(_photo!.path), height: 200),
            const SizedBox(height: 10),
          ],
          if (_location != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Location: $_location', style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
