import 'package:flutter/material.dart';

void main() {
  runApp(const StudentCStudioApp());
}

class StudentCStudioApp extends StatelessWidget {
  const StudentCStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student C Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const String _sampleCode = '''#include <stdio.h>

int main()
{
    printf("Hello, Student C Studio!\\n");
    return 0;
}
''';

  late final TextEditingController _codeController;
  String _consoleText = 'Output এখানে দেখা যাবে।';
  String _banglaHelp = 'Error হলে বাংলা ব্যাখ্যা এখানে দেখা যাবে।';

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: _sampleCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _newProgram() {
    setState(() {
      _codeController.text = '''#include <stdio.h>

int main()
{
    
    return 0;
}
''';
      _consoleText = 'নতুন প্রোগ্রাম তৈরি হয়েছে।';
      _banglaHelp = 'কোড লিখে Run চাপুন।';
    });
  }

  void _loadSample() {
    setState(() {
      _codeController.text = _sampleCode;
      _consoleText = 'Sample Program লোড হয়েছে।';
      _banglaHelp = 'এখন Run চাপুন।';
    });
  }

  void _runProgram() {
    final code = _codeController.text;

    // প্রথম ধাপ: UI flow যাচাই। প্রকৃত offline compiler পরে যুক্ত হবে।
    if (!code.contains('int main')) {
      setState(() {
        _consoleText = "Compiler Error: undefined reference to 'main'";
        _banglaHelp =
            'বাংলা ব্যাখ্যা: C প্রোগ্রাম চালু হওয়ার জন্য int main() ফাংশন প্রয়োজন।';
      });
      return;
    }

    if (code.contains('printf') && !code.contains(';')) {
      setState(() {
        _consoleText = "Compiler Error: expected ';'";
        _banglaHelp =
            'বাংলা ব্যাখ্যা: কোনো স্টেটমেন্টের শেষে সেমিকোলন (;) বাদ পড়েছে।';
      });
      return;
    }

    setState(() {
      _consoleText = 'Hello, Student C Studio!';
      _banglaHelp = 'প্রোগ্রাম সফলভাবে রান হয়েছে।';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student C Studio'),
            Text(
              'Write → Run → Learn',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Program',
            onPressed: _newProgram,
            icon: const Icon(Icons.note_add_outlined),
          ),
          IconButton(
            tooltip: 'Sample Program',
            onPressed: _loadSample,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _codeController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'C Code Editor',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _runProgram,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Run'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  _OutputCard(
                    title: 'Output / Error',
                    icon: Icons.terminal,
                    content: _consoleText,
                  ),
                  const SizedBox(height: 8),
                  _OutputCard(
                    title: 'বাংলা ব্যাখ্যা',
                    icon: Icons.lightbulb_outline,
                    content: _banglaHelp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
