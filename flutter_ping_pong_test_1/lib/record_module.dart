import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:share_plus/share_plus.dart';

class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  @override
  VideoRecorderScreenState createState() => VideoRecorderScreenState();
}

class VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  List<List<double>> coordlist = [];
  bool editing = false;
  List<Widget> _stackChildren = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted && await Permission.storage.request().isGranted && await Permission.sensors.request().isGranted) {

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.max, fps: 240);
        await _controller!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _startVideoRecording() async {
    editing = false;

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

  void _onTapDown(TapDownDetails details) {
    if (!editing) {
      return;
    }

    var x = details.localPosition.dx;
    var y = details.localPosition.dy;
    print("Tap down $x, $y.");

    if (coordlist.length < 4) {

      coordlist.add([x, y]);
      addStackElt(x, y);
    }

    print(coordlist);

    editing = false;
    return;
  }

  void addStackElt(double x , double y) {
    setState(() {
      _stackChildren.add(
        Positioned(
          left: x, // X-coordinate
          top: y, // Y-coordinate
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }

  void removePoints() {
    setState(() {
      _stackChildren = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTapDown: (TapDownDetails details) => _onTapDown(details),
              child: Stack(
                children: <Widget>[
                  CameraPreview(_controller!),
                  ..._stackChildren,
                  /*
                  Positioned(
                    left: 10, // X-coordinate
                    top: 10, // Y-coordinate
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FloatingActionButton(
                    onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                    child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                  ),

                  const SizedBox(width: 32),

                  FloatingActionButton(
                    onPressed: () {
                      print('Second button pressed');
                      if (_isRecording) {
                        editing = false;
                        return;
                      }

                      if (coordlist.length >= 4) {
                        editing = false;
                        return;
                      }

                      editing = true;
                    },
                    
                    child: const Icon(Icons.edit),
                  ),

                  const SizedBox(width: 32),

                  FloatingActionButton(
                    onPressed: () {
                      editing = false;
                      coordlist = [];
                      removePoints();
                    },
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
class PointCamStack extends StatefulWidget {
  final CameraPreview camprev;

  const PointCamStack({super.key, required this.camprev});

  @override
  PointCamStackState createState() => PointCamStackState();
}
*/

/*
class PointCamStackState extends State<PointCamStack> {
  List<Widget> _stackChildren = [];

  void addStackElt(double x , double y) {
    setState(() {
      _stackChildren.add(
        Positioned(
          left: x, // X-coordinate
          top: y, // Y-coordinate
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }

  void removePoints() {
    setState(() {
      _stackChildren = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.camprev,
        ..._stackChildren,
      ],
    );
  }
}
*/