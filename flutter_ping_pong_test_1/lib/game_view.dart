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
          itemBuilder: (c, i) => FirstRoute(index: i),
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
      child: Text('Entry $i')
    ),
      //onTap: eventview()
  );
}

class FirstRoute extends StatefulWidget {
  final int index;

  const FirstRoute({super.key, required this.index});

  @override
  FirstRouteState createState() => FirstRouteState();
}

class FirstRouteState extends State<FirstRoute> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
      // Perform actions when the container is tapped
        Fluttertoast.showToast(msg: "Container tapped!");
      },
      child: ElevatedButton(
          child: Text('${widget.index}'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => SecondRoute(index: widget.index),
              ),
            );
          },
        ),
        /*
      child: Container(
        height: 75,
        color: const Color.fromARGB(255, 255, 250, 250),
        child: Text('Entry $i')
      ),
      */
      //onTap: eventview()
  );
  }
}

class SecondRoute extends StatefulWidget {
  final int index;

  const SecondRoute({super.key, required this.index});

  @override
  SecondRouteState createState() => SecondRouteState();
}

class SecondRouteState extends State<SecondRoute> {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: const Text('Game Stats')),
       body: Center(
         child: Text("Test ${widget.index}"),
         // child: ElevatedButton(
         //   onPressed: () {
         //     Navigator.pop(context);
         //   },
         //   child: const Text('Go back!'),
         // ),
       ),
     );
  }
}


// class SecondRoute extends StatelessWidget {
//   const SecondRoute({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Second Route')),
//       body: Center(
//         child: Text("Test"),
//         // child: ElevatedButton(
//         //   onPressed: () {
//         //     Navigator.pop(context);
//         //   },
//         //   child: const Text('Go back!'),
//         // ),
//       ),
//     );
//   }
// }