import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'blink_detector.dart';
import 'screens/edit_phrases_screen.dart';

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
    _detector = BlinkDetector(onBlink: _onBlink);
  }

  Future<void> _loadPhrases() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/phrases.json');

    if (!(await file.exists())) {
      final assetData = await rootBundle.loadString('assets/phrases.json');
      await file.writeAsString(assetData);
    }

    final data = await file.readAsString();
    final json = jsonDecode(data);
    final loaded = List<String>.from(json['phrases'] ?? []);

    setState(() {
      _phrases = loaded;
      _index = 0;
    });

    _timer?.cancel();
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
      Navigator.pop(context);
    }

    await Future.delayed(const Duration(seconds: 1));
    _cooldown = false;
  }

  Future<bool> _showConfirmationDialog(String phrase) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlinkConfirmDialog(phrase: phrase),
      ),
    );
  }

  void _navigateToEditor() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditPhrasesScreen()),
    );
    if (updated == true) {
     await _loadPhrases();

     _detector?.dispose();
     _detector = BlinkDetector(onBlink: _onBlink);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detector?.dispose();
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
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _navigateToEditor,
                child: const Text("Edit Phrases"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 👁️ Blink-Based Confirm Dialog
class BlinkConfirmDialog extends StatefulWidget {
  final String phrase;
  const BlinkConfirmDialog({required this.phrase, super.key});

  @override
  State<BlinkConfirmDialog> createState() => _BlinkConfirmDialogState();
}

class _BlinkConfirmDialogState extends State<BlinkConfirmDialog> {
  int _index = 0; // 0 = YES, 1 = NO
  Timer? _timer;
  BlinkDetector? _detector;
  bool _cooldown = false;

  final List<String> _options = ['YES', 'NO'];

  @override
  void initState() {
    super.initState();

    _detector = BlinkDetector(onBlink: _onBlink);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _index = (_index + 1) % _options.length;
      });
    });
  }

  void _onBlink() async {
    if (_cooldown) return;
    _cooldown = true;

    final result = _index == 0; // YES = true
    Navigator.pop(context, result);

    await Future.delayed(const Duration(seconds: 1));
    _cooldown = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Select '${widget.phrase}'?",
                style: const TextStyle(fontSize: 26, color: Colors.cyanAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_options.length, (i) {
                  final selected = i == _index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? Colors.yellow : Colors.white24,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: selected ? Colors.white10 : Colors.transparent,
                    ),
                    child: Text(
                      _options[i],
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text("(Blink to Confirm)", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}