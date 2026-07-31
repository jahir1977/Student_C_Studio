import 'package:flutter/material.dart';

import 'pages/editor_page.dart';

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
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const EditorPage(),
    );
  }
}