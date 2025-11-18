import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'data_storage.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: getVideoAmount(),
          itemBuilder: (c, i) => GameNavigationItem(index: i),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => getVideoAmount()),
        child: Icon(Icons.refresh),
      ),
    );
  }
}

/*
InkWell myItem(int i) {
  return InkWell(
    onTap: () {
      Fluttertoast.showToast(msg: "Container tapped!");
    },
    child: Container(
      height: 75,
      color: const Color.fromARGB(255, 255, 250, 250),
      child: Text('Entry $i')
    ),
  );
}
*/

class GameNavigationItem extends StatefulWidget {
  final int index;

  const GameNavigationItem({super.key, required this.index});

  @override
  GameNavigationItemState createState() => GameNavigationItemState();
}

class GameNavigationItemState extends State<GameNavigationItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Fluttertoast.showToast(msg: "Container tapped!");
      },
      child: ElevatedButton(
          child: Text('Game ${widget.index}'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => StatisticsPage(index: widget.index),
              ),
            );
          },
        ),
  );
  }
}

class StatisticsPage extends StatefulWidget {
  final int index;

  const StatisticsPage({super.key, required this.index});

  @override
  StatisticsPageState createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: const Text('Game Stats')),
      body: Container(
                padding: EdgeInsets.all(20.0),
                child: Table(
                  border: TableBorder.all(color: Colors.black),
                  children: [
                    TableRow(children: [
                      Text('STAT'),
                      Text('Player 1'),
                      Text('Player 2'),
                    ]),
                    TableRow(children: [
                      Text('Fastest Shot'),
                      Text('Cell 2'),
                      Text('Cell 3'),
                    ]),
                    TableRow(children: [
                      Text('Average Shot Speed'),
                      Text('Cell 5'),
                      Text('Cell 6'),
                    ])
                  ],
                ),
       ),
     );
  }
}
