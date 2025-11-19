import 'package:flutter/material.dart';
import 'package:flutter_ping_pong_test_1/game_view.dart';
import 'package:flutter_ping_pong_test_1/record_module.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'data_storage.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
//import 'package:flutter/services.dart';
//import 'package:share_plus/share_plus.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  loadSavedFiles();
  runApp(const MyApp());
}

class MyBottomNavBarScreen extends StatefulWidget {
  const MyBottomNavBarScreen({super.key});

  @override
  State<MyBottomNavBarScreen> createState() => _MyBottomNavBarScreenState();
}

class _MyBottomNavBarScreenState extends State<MyBottomNavBarScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    //HomePage(),
    //GyroscopeExample(),
    //TestAPIPage(),
    VideoRecorderScreen(),
    //TakePictureScreen(camera: cameras.first),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
     return OrientationBuilder(
      builder: (context, orientation) {
        // Check the current orientation
        final bool isPortrait = orientation == Orientation.portrait;
        
        return Scaffold(
          appBar: isPortrait ? AppBar(
            title: const Text('Ping Pong Pros'),
          ) : null,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                if (index == 1) {
                  requestCameraPermission();
                }
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.table_restaurant),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera),
                label: 'Record',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Game History',
              ),
            ],
          ),
        );
      });
  }
  /*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ping Pong Pros'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 1) {
              requestCameraPermission();
            }
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Game History',
          ),
        ],
      ),
    );
  }
  */
}

/*
class TestAPIPage extends StatefulWidget {
  @override
  _TestAPIState createState() => _TestAPIState();
}

class _TestAPIState extends State<TestAPIPage> {
  static const platform = MethodChannel('lidar_channel');
  String _lidarStatus = 'LiDAR not started';
  bool _isRecording = false;

  Future<void> _startLidar() async {
    try {
      final bool started = await platform.invokeMethod('startLidar');
      if (started) {
        setState(() {
          _lidarStatus = 'Recording...';
          _isRecording = true;
        });
      } else {
        setState(() {
          _lidarStatus = 'Failed to start LiDAR. Is it available?';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _lidarStatus = "Failed to start LiDAR: '${e.message}'.";
      });
    }
  }

  Future<void> _stopLidar() async {
    try {
      final String? path = await platform.invokeMethod('stopLidar');
      setState(() {
        _lidarStatus = 'LiDAR not started';
        _isRecording = false;
      });
      if (path != null) {
        final xfile = XFile(path);
        await Share.shareXFiles([xfile], text: 'My LiDAR Video');
      } else {
        // Handle error or null path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get video path.')),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        _lidarStatus = "Failed to stop LiDAR: '${e.message}'.";
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_lidarStatus),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isRecording ? _stopLidar : _startLidar,
                child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

/*
class GyroscopeExample extends StatefulWidget {
  @override
  _GyroscopeExampleState createState() => _GyroscopeExampleState();
}

class _GyroscopeExampleState extends State<GyroscopeExample> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RotationSensor.orientationStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          //print(data.quaternion);
          //print(data.rotationMatrix);
          //print(data.eulerAngles);
          return Text("${data.quaternion}");
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
*/

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Page Content'));
  }
}

/*
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  String length = "Empty";

  void _test() {
    setState(() {
      //final firstCamera = cameras.first;
      length = "Test";
      length = cameras.length.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'This is a:',
            ),
            Text(
              length,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _test,
        child: Text("Record"),
      ), 
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Page Content'));
  }
}
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping Pong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
      ),
      home: const MyBottomNavBarScreen(),
    );
  }
}


Future<void> requestCameraPermission() async {
  var status = await Permission.camera.status;

  if (status.isGranted) {
    Fluttertoast.showToast(msg: 'Already permission granted');
  } else if (status.isDenied) {
    // Permission denied, request it
    var result = await Permission.camera.request();

    if (result.isGranted) {
      Fluttertoast.showToast(msg: 'Permission now granted');
      // Proceed with camera access
    } else {
      Fluttertoast.showToast(msg: 'Permission Denied');
      // Handle denied permission (e.g., show a message, disable camera features)
    }
  } else if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(msg: 'Permission permanently denied');
    // Permission permanently denied, guide user to app settings
    openAppSettings(); // Opens app settings for manual permission granting
  }
}
