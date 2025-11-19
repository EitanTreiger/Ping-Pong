import 'package:flutter/material.dart';
import 'data_storage.dart';
import 'dart:async';
import 'stats_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    setState(() {
      getVideoAmount();
    });
    Timer(const Duration(milliseconds: 1500), () => setState(() {
      getVideoAmount();
    }));
  }

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
      /* onTap: () {
        Fluttertoast.showToast(msg: "Container tapped!");
      }, */
      child: ElevatedButton(
        child: Text('Game ${widget.index + 1}'),
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
