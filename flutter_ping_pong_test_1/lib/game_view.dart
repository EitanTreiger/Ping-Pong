import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String length = "Empty";

  void _test() {
    setState(() {
      length = "Test";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: 25,
          itemBuilder: (c, i) => MyItem(i),
        ),
      )
    );
  }
}

InkWell MyItem(int i) {
  return InkWell(
    onTap: () {
    // Perform actions when the container is tapped
      Fluttertoast.showToast(msg: "Container tapped!");
    },
    child: Container(
      height: 75,
      color: const Color.fromARGB(255, 255, 250, 250),
      child: Center(child: Text('Entry $i')),
      //onTap: eventview()
    ),
  );
}