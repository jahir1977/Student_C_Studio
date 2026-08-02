import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/compiler_result.dart';
import '../services/bangla_error_service.dart';
import '../services/mock_compiler.dart';
import 'sample_program_page.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const String _sampleCode = '''#include<stdio.h>

int main()
{
    printf("Hello, Student C Studio");
    return 0;
}''';

  final TextEditingController _codeController = TextEditingController(
    text: _sampleCode,
  );

  final ScrollController _editorScrollController = ScrollController();

  final MockCompiler _compiler = const MockCompiler();

  final BanglaErrorService _banglaErrorService = const BanglaErrorService();

  CompilerResult? _result;

  String _banglaExplanation = 'কোড লিখে Run বাটনে ক্লিক করুন।';

  bool _isRunning = false;

  int _lineCount = 1;

  @override
  void initState() {
    super.initState();

    _updateLineCount();

    _codeController.addListener(_updateLineCount);
  }

  @override
  void dispose() {
    _codeController.removeListener(_updateLineCount);
    _codeController.dispose();
    _editorScrollController.dispose();

    super.dispose();
  }

  void _updateLineCount() {
    final int newLineCount = '\n'.allMatches(_codeController.text).length + 1;

    if (newLineCount != _lineCount && mounted) {
      setState(() {
        _lineCount = newLineCount;
      });
    }
  }

  Future<void> _runProgram() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isRunning = true;
      _result = null;
      _banglaExplanation = 'Program পরীক্ষা করা হচ্ছে...';
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    final CompilerResult result = _compiler.compile(_codeController.text);

    final String explanation = result.banglaExplanation.trim().isNotEmpty
        ? result.banglaExplanation
        : _banglaErrorService.explain(result.error);

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result;
      _banglaExplanation = explanation;
      _isRunning = false;
    });
  }

  void _newProgram() {
    setState(() {
      _codeController.clear();
      _result = null;
      _banglaExplanation = 'নতুন Program লেখা শুরু করুন।';
    });
  }

  Future<void> _loadSampleProgram() async {
    final String? selectedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) {
          return const SampleProgramPage();
        },
      ),
    );

    if (!mounted || selectedCode == null) {
      return;
    }

    setState(() {
      _codeController.text = selectedCode;

      _codeController.selection = TextSelection.collapsed(
        offset: _codeController.text.length,
      );

      _result = null;
      _banglaExplanation =
          'Sample Program লোড হয়েছে। কোড পরিবর্তন করে Run করতে পারবেন।';
    });
  }

  void _clearOutput() {
    setState(() {
      _result = null;
      _banglaExplanation = 'Output পরিষ্কার করা হয়েছে।';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student C Studio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Write → Run → Learn',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
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
            tooltip: 'Load Sample',
            onPressed: _loadSampleProgram,
            icon: const Icon(Icons.code),
          ),
          IconButton(
            tooltip: 'Clear Output',
            onPressed: _clearOutput,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool wideScreen = constraints.maxWidth >= 900;

            if (wideScreen) {
              return _buildWideLayout();
            }

            return _buildNarrowLayout();
          },
        ),
      ),
      bottomNavigationBar: _buildStatusBar(),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildEditorSection(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _buildOutputSection(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildBanglaExplanationSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 430,
            child: _buildEditorSection(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildOutputSection(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildBanglaExplanationSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(
            icon: Icons.description_outlined,
            title: 'Program.c',
            trailing: '${_codeController.text.length} characters',
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLineNumberPanel(),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFF404040),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      scrollController: _editorScrollController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: Colors.white,
                      style: GoogleFonts.firaCode(
                        fontSize: 16,
                        height: 1.6,
                        color: const Color(0xFFD4D4D4),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'এখানে C Program লিখুন...',
                        hintStyle: GoogleFonts.firaCode(
                          color: Colors.white38,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildEditorButtons(),
        ],
      ),
    );
  }

  Widget _buildLineNumberPanel() {
    return Container(
      width: 52,
      color: const Color(0xFF252526),
      padding: const EdgeInsets.only(
        top: 16,
        right: 10,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(
            _lineCount,
            (int index) {
              return SizedBox(
                height: 25.6,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white38,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEditorButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _newProgram,
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('New Program'),
          ),
          OutlinedButton.icon(
            onPressed: _loadSampleProgram,
            icon: const Icon(Icons.code),
            label: const Text('Sample Program'),
          ),
          FilledButton.icon(
            onPressed: _isRunning ? null : _runProgram,
            icon: _isRunning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunning ? 'Running...' : 'Run',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection() {
    final CompilerResult? result = _result;

    final bool hasResult = result != null;

    final bool isSuccess = result?.isSuccess ?? true;

    final String title = !hasResult
        ? 'Output / Error'
        : isSuccess
            ? 'Program Output'
            : 'Compiler Error';

    final String content = !hasResult
        ? 'Run করার পর Output অথবা Error এখানে দেখা যাবে।'
        : result.displayText;

    final IconData icon = !hasResult
        ? Icons.terminal
        : isSuccess
            ? Icons.check_circle
            : Icons.error;

    final Color iconColor = !hasResult
        ? Colors.blueGrey
        : isSuccess
            ? Colors.green
            : Colors.red;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(
            icon: icon,
            iconColor: iconColor,
            title: title,
            trailing: hasResult
                ? isSuccess
                    ? 'Success'
                    : 'Failed'
                : 'Ready',
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF111827),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: GoogleFonts.firaCode(
                    fontSize: 15,
                    height: 1.6,
                    color: hasResult
                        ? isSuccess
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFCA5A5)
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanglaExplanationSection() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(
            icon: Icons.school_outlined,
            iconColor: Colors.deepPurple,
            title: 'বাংলা ব্যাখ্যা',
            trailing: 'Learn',
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple.shade50,
              child: SingleChildScrollView(
                child: SelectableText(
                  _banglaExplanation,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF312E81),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader({
    required IconData icon,
    required String title,
    String? trailing,
    Color? iconColor,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final CompilerResult? result = _result;

    String statusText = 'Ready';
    IconData statusIcon = Icons.circle;
    Color statusColor = Colors.blueGrey;

    if (_isRunning) {
      statusText = 'Running';
      statusIcon = Icons.sync;
      statusColor = Colors.orange;
    } else if (result != null && result.isSuccess) {
      statusText = 'Success';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (result != null && !result.isSuccess) {
      statusText = 'Error';
      statusIcon = Icons.error;
      statusColor = Colors.red;
    }

    return Container(
      height: 34,
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 7),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            'Lines: $_lineCount',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'C Language',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'UTF-8',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
