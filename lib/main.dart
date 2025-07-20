import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'phrases_screen.dart';
import 'blink_detector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EyeSpeakApp());
}

class EyeSpeakApp extends StatelessWidget {
  const EyeSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyeSpeak Assist Mobile',
      theme: ThemeData.dark(),
      home: const KeyboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> with WidgetsBindingObserver {
  bool _cooldown = false;
  final List<List<String>> _layout = [
    ['PHRASES'],
    'QWERTYUIOP'.split(''),
    'ASDFGHJKL'.split(''),
    'ZXCVBNM./-'.split(''),
  ];
  final List<int> _rowCycle = [0, 1, 0, 2, 0, 3];
  int _cycleIndex = 0;
  int _col = 0;
  String _text = '';
  late Timer _timer;
  late FlutterTts _tts;
  BlinkDetector? _detector;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tts = FlutterTts();
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.5);
    _startBlinkAndCycle();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _startBlinkAndCycle() {
    print("[Blink] Starting blink detector and timer");
    _detector?.dispose();
    _detector = BlinkDetector(onBlink: _onBlink);
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _col++;
        final currentRow = _rowCycle[_cycleIndex];
        if (_col >= _layout[currentRow].length) {
          _col = 0;
          _cycleIndex = (_cycleIndex + 1) % _rowCycle.length;
        }
      });
    });
  }

  void _disposeDetectorAndTimer() {
    print("[Blink] Disposing detector and timer");
    _timer.cancel();
    _detector?.dispose();
    _detector = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeDetectorAndTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("[Lifecycle] App state changed: $state");
    if (state == AppLifecycleState.paused) {
      _disposeDetectorAndTimer();
    } else if (state == AppLifecycleState.resumed) {
      _startBlinkAndCycle();
    }
  }

  void _onBlink() async {
    if (_cooldown) return;
    _cooldown = true;
    final row = _rowCycle[_cycleIndex];

    if (row == 0) {
      print("[Blink] PHRASES screen opened");
      _disposeDetectorAndTimer();

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PhrasesScreen(tts: _tts)),
      );

      print("[Blink] Returned from phrases screen");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startBlinkAndCycle();
      });
    } else {
      final selected = _layout[row][_col];
      print("[Blink] Selected: $selected");
      setState(() {
        if (selected == '-') {
          _tts.stop();
          _tts.speak(_text);
          _text = '';
        } else if (selected == '.') {
          _text += ' ';
        } else if (selected == '/') {
          if (_text.isNotEmpty) {
            _text = _text.substring(0, _text.length - 1);
          }
        } else {
          _text += selected;
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _cooldown = false;
    print("[Blink] Cooldown reset");
  }

  Widget _buildKey(String char, bool highlight) {
    return Container(
      margin: const EdgeInsets.all(4),
      width: char == "PHRASES" ? 150 : 50,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight ? Colors.green : Colors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        char,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _text,
                        style: const TextStyle(fontSize: 32, color: Colors.yellow),
                      ),
                    ),
                    for (int r = 0; r < _layout.length; r++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (int c = 0; c < _layout[r].length; c++)
                              _buildKey(_layout[r][c], _rowCycle[_cycleIndex] == r && c == _col),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
