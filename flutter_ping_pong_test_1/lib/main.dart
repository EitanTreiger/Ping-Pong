import 'package:flutter/material.dart';
import 'package:flutter_ping_pong_test_1/game_view.dart';
import 'package:flutter_ping_pong_test_1/record_module.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import 'camera_module.dart';
//import 'game_view.dart';
//import 'package:path_provider/path_provider.dart';
//import 'camera_module.dart';
import 'data_storage.dart';


int a = 5;
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
    const HomePage(),
    VideoRecorderScreen(),
    //TakePictureScreen(camera: cameras.first),
    HistoryPage(),
  ];

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
            icon: Icon(Icons.home),
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
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Page Content'));
  }
}


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
