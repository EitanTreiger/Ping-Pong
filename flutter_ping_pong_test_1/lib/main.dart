import 'package:flutter/material.dart';
import 'package:flutter_ping_pong_test_1/game_view.dart';
import 'package:flutter_ping_pong_test_1/record_module.dart';
import 'package:flutter_ping_pong_test_1/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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
    VideoRecorderScreen(),
    HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
     return OrientationBuilder(
      builder: (context, orientation) {
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
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Home Page Content'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Dark Mode'),
              Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      //debugShowCheckedModeBanner: false,
      title: 'Ping Pong',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: themeProvider.themeMode,
      home: const MyBottomNavBarScreen(),
    );
  }
}


Future<void> requestCameraPermission() async {
  var status = await Permission.camera.status;

  if (status.isGranted) {
    //Fluttertoast.showToast(msg: 'Already permission granted');
  } else if (status.isDenied) {
    var result = await Permission.camera.request();

    if (result.isGranted) {
      //Fluttertoast.showToast(msg: 'Permission now granted');
    } else {
      Fluttertoast.showToast(msg: 'Camera Permission Denied');
    }
  } else if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(msg: 'Camera Permission Denied');
    openAppSettings();
  }
}
