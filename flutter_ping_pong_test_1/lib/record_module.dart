import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:share_plus/share_plus.dart';

class VideoRecorderScreen extends StatefulWidget {
  @override
  _VideoRecorderScreenState createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  //Quaternion quat = Quaternion(0, 0, 0, 0);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted && await Permission.storage.request().isGranted && await Permission.sensors.request().isGranted) {

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.high, fps: 240);
        await _controller!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    //final OrientationEvent event = await RotationSensor.orientationStream.first;
    //quat = event.quaternion;

    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      return;
    }
    final XFile videoFile = await _controller!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });

    await SharePlus.instance.share(
      ShareParams(
      text: 'Great video',
      files: [videoFile],
    ));
    //print('${videoFile.path}');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /*
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      body: Stack(
        children: [
          Center(
            child: CameraPreview(_controller!),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      body: Stack(
        children: [
          Center(
            child: CameraPreview(_controller!),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ),
          ),
        ],
      ),
    );
  }
}