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

class StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Stats')),
      body: Column(
        children: [
          Container(
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
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: LinePainter(_animation.value),
                  child: Container(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final double position;

  LinePainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5.0;

    final startX = size.width * position;
    final startY = size.height / 2;
    final endX = size.width * position;
    final endY = size.height / 2 + 20;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
