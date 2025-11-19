import 'package:flutter/material.dart';
//import 'data_storage.dart';

class StatisticsPage extends StatefulWidget {
  final int index;

  const StatisticsPage({super.key, required this.index});

  @override
  StatisticsPageState createState() => StatisticsPageState();
}

/*
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
      appBar: AppBar(
        title: Text('Game ${widget.index + 1} Stats'),
      ),
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
*/

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
      appBar: AppBar(
        title: Text('Game ${widget.index + 1} Stats'),
      ),
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
    const tableWidthRatio = 2740;
    const tableHeightRatio = 1525;
    const tableAspectRatio = tableWidthRatio / tableHeightRatio;

    double tableWidth;
    double tableHeight;

    if (size.width / size.height > tableAspectRatio) {
      tableHeight = size.height;
      tableWidth = tableHeight * tableAspectRatio;
    } else {
      tableWidth = size.width - 20;
      tableHeight = tableWidth / tableAspectRatio;
    }

    final tableLeft = (size.width - tableWidth) / 2;
    final tableTop = (size.height - tableHeight) / 2;

    final tablePaint = Paint()..color = const Color.fromARGB(255, 45, 65, 80);//const Color.fromARGB(255, 87, 103, 113);
    final tableRect = Rect.fromLTWH(tableLeft, tableTop, tableWidth, tableHeight);
    canvas.drawRect(tableRect, tablePaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0;

    canvas.drawRect(tableRect, linePaint..style = PaintingStyle.stroke);

    final centerLineStart = Offset(tableLeft + tableWidth / 2, tableTop);
    final centerLineEnd = Offset(tableLeft + tableWidth / 2, tableTop + tableHeight);
    canvas.drawLine(centerLineStart, centerLineEnd, linePaint);

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    final netStart = Offset(tableLeft, tableTop + tableHeight / 2);
    final netEnd = Offset(tableLeft + tableWidth, tableTop + tableHeight / 2);
    canvas.drawLine(netStart, netEnd, netPaint);
    
    final ballPaint = Paint()
      ..color = Color.fromARGB(255, 225, 120, 35)
      ..strokeWidth = 5.0;

    final X = tableWidth * position + tableLeft;
    final Y = size.height / 2;

    canvas.drawCircle(Offset(X, Y), 5, ballPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
