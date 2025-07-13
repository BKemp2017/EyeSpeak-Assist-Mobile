import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'blink_detector.dart'; // 👈 Make sure this is imported

class PhrasesScreen extends StatefulWidget {
  final FlutterTts tts;
  const PhrasesScreen({required this.tts, super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen> {
  List<String> _phrases = [];
  int _index = 0;
  bool _cooldown = false;
  Timer? _timer;
  BlinkDetector? _detector;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
    _detector = BlinkDetector(onBlink: _onBlink); // 👈 Blink detector just for this screen
  }

  void _loadPhrases() async {
    final data = await rootBundle.loadString('assets/phrases.json');
    final json = jsonDecode(data);
    setState(() => _phrases = List<String>.from(json['phrases'] ?? []));

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _index = (_index + 1) % _phrases.length;
      });
    });
  }

  void _onBlink() async {
    if (_cooldown || _phrases.isEmpty) return;
    _cooldown = true;

    final selected = _phrases[_index];
    final confirm = await _showConfirmationDialog(selected);
    if (confirm) {
      await widget.tts.speak(selected);
      Navigator.pop(context); // back to keyboard
    }

    await Future.delayed(const Duration(seconds: 1));
    _cooldown = false;
  }

  Future<bool> _showConfirmationDialog(String phrase) async {
    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Select '$phrase'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NO"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detector?.dispose(); // 👈 Clean up camera stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phrases.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Select a Phrase:", style: TextStyle(fontSize: 26, color: Colors.cyanAccent)),
              const SizedBox(height: 20),
              Text(
                _phrases[_index],
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text("(Blink to Select)", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
