import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class EditPhrasesScreen extends StatefulWidget {
  const EditPhrasesScreen({super.key});

  @override
  State<EditPhrasesScreen> createState() => _EditPhrasesScreenState();
}

class _EditPhrasesScreenState extends State<EditPhrasesScreen> {
  List<String> _phrases = [];
  final TextEditingController _controller = TextEditingController();

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/phrases.json';
    final file = File(path);

    if (!await file.exists()) {
      // Copy from assets on first use
      final data = await rootBundle.loadString('assets/phrases.json');
      await file.writeAsString(data);
    }
    return path;
  }

  Future<void> _loadPhrases() async {
    final path = await _getFilePath();
    final data = await File(path).readAsString();
    final jsonResult = json.decode(data);
    setState(() {
      _phrases = List<String>.from(jsonResult['phrases']);
    });
  }

  Future<void> _savePhrases() async {
    final path = await _getFilePath();
    final file = File(path);
    await file.writeAsString(json.encode({"phrases": _phrases}));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phrases saved successfully.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Phrases")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _phrases.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_phrases[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _phrases.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new phrase',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final newPhrase = _controller.text.trim();
                    if (newPhrase.isNotEmpty) {
                      setState(() {
                        _phrases.add(newPhrase);
                        _controller.clear();
                      });
                    }
                  },
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhrase = _controller.text.trim();
              if (newPhrase.isNotEmpty && !_phrases.contains(newPhrase)) {
                setState(() {
                  _phrases.add(newPhrase);
                  _controller.clear();
                });
              }
              await _savePhrases();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}