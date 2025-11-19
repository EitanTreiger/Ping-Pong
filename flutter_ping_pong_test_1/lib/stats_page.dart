import 'package:flutter/material.dart';
import 'data_storage.dart';
import 'dart:io';
import 'dart:convert';

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

class StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String jsonstr = "";
  late final List decodedJson;
  bool _isControllerInit = false;

  @override
  void initState() {
    super.initState();
    FileSystemEntity gameStatsFile = getAnalysisbyIndex(widget.index);
    doasyncstuff(gameStatsFile);
  }

  void doasyncstuff(FileSystemEntity gameStats) async {
    jsonstr = await readJsonFile(gameStats.path);
    decodedJson = jsonDecode(jsonstr);
    double n = decodedJson[decodedJson.length - 1]["frame_number"] / 30;
    print(decodedJson);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (n * 1000).round()),
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    print("Duration: ${(n * 1000).round()} ms");
    setState(() {
      _isControllerInit = true;
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInit || _controller == null) {
      return Center(child: CircularProgressIndicator());
    }
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
                  painter: BallAnimPainter(_animation.value, decodedJson, 
                    decodedJson.map((bounceData) => (bounceData["frame_number"] as int)).toList(), 
                    decodedJson[decodedJson.length - 1]["frame_number"]),
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

class BallAnimPainter extends CustomPainter {
  final double position;
  final List decodedJson;
  final List<int> bounceFrames;
  final int finalFrame;

  BallAnimPainter(this.position, this.decodedJson, this.bounceFrames, this.finalFrame);

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
    final tableTop = 40.0;

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

    List<int> xy = findBallXY(finalFrame * position, decodedJson, bounceFrames);
    print(xy);

    final X = tableWidth/tableWidthRatio * xy[0] + tableLeft;
    final Y = tableHeight/tableHeightRatio * xy[1] + tableTop;

    print("$X, $Y");
    print("${size.width}, ${size.height}");

    canvas.drawCircle(Offset(X, Y), 5, ballPaint);
    print("circle printed");
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

List<int> findBallXY(double timestamp, decodedJson, bounceFrames) {
  int afterFrame = 0;
  //print(timestamp);
  for (int i = 0; i < bounceFrames.length; i++) {
    if (bounceFrames[i] >= timestamp) {
      afterFrame = i;
      break;
    }
  }

  if (afterFrame == 0) {
    return [0, 0];
  }

  int prevFrame = afterFrame - 1;
  int prevFrameTime = bounceFrames[prevFrame];
  int frameAfterTime = bounceFrames[afterFrame];

  Map<String, dynamic> prevFrameMap = decodedJson[prevFrame];
  List posPrevFrame = prevFrameMap["pos"]; // For some reason, this does not run even when prior lines run. To look into
  Map<String, dynamic> afterFrameMap = decodedJson[afterFrame];
  List posAfterFrame = afterFrameMap["pos"];
  //print("Down ere");

  double interpTime = timestamp - prevFrameTime;
  int frameTimeDiff = (frameAfterTime - prevFrameTime).abs();
  int x = lerp(posPrevFrame[0], posAfterFrame[0], interpTime/frameTimeDiff).round();
  int y = lerp(posPrevFrame[1], posAfterFrame[1], interpTime/frameTimeDiff).round();
  return [x, y];
}

double lerp(int a, int b, double t) {
  return a + (b - a) * t;
}

Future<String> readJsonFile(String filePath) async {
  final file = File(filePath);
  return await file.readAsString();
}
