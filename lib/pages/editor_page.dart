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

  final TextEditingController _inputController = TextEditingController();

  final List<String> _inputValues = <String>[];

  final ScrollController _editorScrollController = ScrollController();

  final FocusNode _inputFocusNode = FocusNode();

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
    _codeController.addListener(_handleCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_handleCodeChanged);
    _codeController.dispose();
    _inputController.dispose();
    _editorScrollController.dispose();
    _inputFocusNode.dispose();

    super.dispose();
  }

  void _handleCodeChanged() {
    _updateLineCount();

    final int requiredCount = _requiredInputCount();

    if (_inputValues.length > requiredCount) {
      setState(() {
        _inputValues.removeRange(
          requiredCount,
          _inputValues.length,
        );
      });
    }
  }

  void _updateLineCount() {
    final int newLineCount = '\n'.allMatches(_codeController.text).length + 1;

    if (newLineCount != _lineCount && mounted) {
      setState(() {
        _lineCount = newLineCount;
      });
    }
  }

  List<_ScanfInputType> _requiredInputTypes() {
    final RegExp scanfPattern = RegExp(
      r'scanf\s*\(\s*"((?:\\.|[^"\\])*)"',
      multiLine: true,
    );

    final List<_ScanfInputType> inputTypes = <_ScanfInputType>[];

    for (final RegExpMatch match
        in scanfPattern.allMatches(_codeController.text)) {
      final String format = match.group(1) ?? '';

      int index = 0;

      while (index < format.length) {
        if (format[index] != '%') {
          index++;
          continue;
        }

        if (index + 1 < format.length && format[index + 1] == '%') {
          index += 2;
          continue;
        }

        int specifierIndex = index + 1;

        while (specifierIndex < format.length &&
            RegExp(r'[-+ #0-9.*]').hasMatch(
              format[specifierIndex],
            )) {
          specifierIndex++;
        }

        if (specifierIndex >= format.length) {
          break;
        }

        if (format.startsWith('lf', specifierIndex)) {
          inputTypes.add(_ScanfInputType.doubleValue);
          index = specifierIndex + 2;
          continue;
        }

        final String specifier = format[specifierIndex];

        switch (specifier) {
          case 'd':
          case 'i':
            inputTypes.add(_ScanfInputType.integer);
            break;
          case 'u':
            inputTypes.add(_ScanfInputType.unsignedInteger);
            break;
          case 'f':
            inputTypes.add(_ScanfInputType.floatValue);
            break;
          case 'c':
            inputTypes.add(_ScanfInputType.character);
            break;
          case 's':
            inputTypes.add(_ScanfInputType.stringValue);
            break;
        }

        index = specifierIndex + 1;
      }
    }

    return inputTypes;
  }

  int _requiredInputCount() {
    return _requiredInputTypes().length;
  }

  void _submitInputValue(String value) {
    final List<_ScanfInputType> requiredTypes = _requiredInputTypes();

    if (_inputValues.length >= requiredTypes.length) {
      return;
    }

    final _ScanfInputType expectedType = requiredTypes[_inputValues.length];

    final String normalizedValue = value.trim();

    final String? validationError = _validateInputValue(
      normalizedValue,
      expectedType,
    );

    if (validationError != null) {
      _showInputMessage(validationError);
      return;
    }

    setState(() {
      _inputValues.add(normalizedValue);
      _inputController.clear();
    });

    if (_inputValues.length >= requiredTypes.length) {
      _inputFocusNode.unfocus();
    } else {
      _inputFocusNode.requestFocus();
    }
  }

  String? _validateInputValue(
    String value,
    _ScanfInputType expectedType,
  ) {
    switch (expectedType) {
      case _ScanfInputType.integer:
        if (!RegExp(r'^[-+]?\d+$').hasMatch(value)) {
          return 'পূর্ণসংখ্যা লিখে Enter চাপুন।';
        }
        return null;

      case _ScanfInputType.unsignedInteger:
        if (!RegExp(r'^\+?\d+$').hasMatch(value)) {
          return 'ঋণাত্মক নয় এমন পূর্ণসংখ্যা লিখে Enter চাপুন।';
        }
        return null;

      case _ScanfInputType.floatValue:
      case _ScanfInputType.doubleValue:
        if (!RegExp(
          r'^[-+]?(?:\d+(?:\.\d*)?|\.\d+)$',
        ).hasMatch(value)) {
          return 'দশমিক বা পূর্ণসংখ্যা লিখে Enter চাপুন।';
        }
        return null;

      case _ScanfInputType.character:
        if (value.runes.length != 1) {
          return 'একটি মাত্র অক্ষর লিখে Enter চাপুন।';
        }
        return null;

      case _ScanfInputType.stringValue:
        if (value.isEmpty) {
          return 'একটি শব্দ লিখে Enter চাপুন।';
        }

        if (RegExp(r'\s').hasMatch(value)) {
          return '%s-এর জন্য স্পেস ছাড়া একটি শব্দ লিখুন।';
        }

        return null;
    }
  }

  TextInputType _keyboardTypeFor(
    _ScanfInputType? inputType,
  ) {
    switch (inputType) {
      case _ScanfInputType.integer:
        return const TextInputType.numberWithOptions(
          signed: true,
          decimal: false,
        );

      case _ScanfInputType.unsignedInteger:
        return const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        );

      case _ScanfInputType.floatValue:
      case _ScanfInputType.doubleValue:
        return const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        );

      case _ScanfInputType.character:
      case _ScanfInputType.stringValue:
      case null:
        return TextInputType.text;
    }
  }

  String _inputHintFor(
    _ScanfInputType inputType,
    int inputNumber,
  ) {
    final String typeLabel;

    switch (inputType) {
      case _ScanfInputType.integer:
        typeLabel = 'পূর্ণসংখ্যা';
        break;
      case _ScanfInputType.unsignedInteger:
        typeLabel = 'ধনাত্মক পূর্ণসংখ্যা';
        break;
      case _ScanfInputType.floatValue:
        typeLabel = 'float সংখ্যা';
        break;
      case _ScanfInputType.doubleValue:
        typeLabel = 'double সংখ্যা';
        break;
      case _ScanfInputType.character:
        typeLabel = 'একটি অক্ষর';
        break;
      case _ScanfInputType.stringValue:
        typeLabel = 'একটি শব্দ';
        break;
    }

    return '$inputNumber নম্বর $typeLabel লিখে Enter চাপুন';
  }

  String _formatLabelFor(_ScanfInputType inputType) {
    switch (inputType) {
      case _ScanfInputType.integer:
        return '%d';
      case _ScanfInputType.unsignedInteger:
        return '%u';
      case _ScanfInputType.floatValue:
        return '%f';
      case _ScanfInputType.doubleValue:
        return '%lf';
      case _ScanfInputType.character:
        return '%c';
      case _ScanfInputType.stringValue:
        return '%s';
    }
  }

  void _removeLastInputValue() {
    if (_inputValues.isEmpty) {
      return;
    }

    setState(() {
      _inputValues.removeLast();
    });

    _inputFocusNode.requestFocus();
  }

  void _showInputMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
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

    final CompilerResult result = _compiler.compile(
      _codeController.text,
      input: _inputValues.join('\n'),
    );

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
      _inputController.clear();
      _inputValues.clear();
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

      _inputController.clear();
      _inputValues.clear();
      _result = null;
      _banglaExplanation = 'Sample Program লোড হয়েছে। '
          'কোড পরিবর্তন করে Run করতে পারবেন।';
    });
  }

  void _clearOutput() {
    setState(() {
      _result = null;
      _banglaExplanation = 'Output পরিষ্কার করা হয়েছে।';
    });
  }

  void _clearInput() {
    setState(() {
      _inputController.clear();
      _inputValues.clear();
    });

    if (_requiredInputCount() > 0) {
      _inputFocusNode.requestFocus();
    }
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
            icon: const Icon(
              Icons.cleaning_services_outlined,
            ),
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
                SizedBox(
                  height: 165,
                  child: _buildInputSection(),
                ),
                const SizedBox(height: 16),
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
            height: 165,
            child: _buildInputSection(),
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
      margin: EdgeInsets.zero,
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
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        height: 1.6,
                        color: const Color(0xFFD4D4D4),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'এখানে C Program লিখুন...',
                        hintStyle: GoogleFonts.robotoMono(
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
                  style: GoogleFonts.robotoMono(
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
            icon: const Icon(
              Icons.note_add_outlined,
            ),
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

  Widget _buildInputSection() {
    final List<_ScanfInputType> requiredTypes = _requiredInputTypes();

    final int requiredCount = requiredTypes.length;
    final int enteredCount = _inputValues.length;
    final bool inputComplete =
        requiredCount > 0 && enteredCount >= requiredCount;
    final bool inputEnabled = requiredCount > 0 && !inputComplete;

    final _ScanfInputType? nextInputType =
        inputEnabled ? requiredTypes[enteredCount] : null;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(
            icon: Icons.keyboard_outlined,
            iconColor: Colors.teal,
            title: 'Program Input (stdin)',
            trailing: '$enteredCount / $requiredCount',
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_inputValues.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: List<Widget>.generate(
                          _inputValues.length,
                          (int index) {
                            return Chip(
                              label: Text(
                                '${index + 1} '
                                '(${_formatLabelFor(requiredTypes[index])}): '
                                '${_inputValues[index]}',
                                style: GoogleFonts.robotoMono(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      enabled: inputEnabled,
                      readOnly: !inputEnabled,
                      maxLines: 1,
                      keyboardType: _keyboardTypeFor(
                        nextInputType,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _submitInputValue,
                      cursorColor: Theme.of(context).colorScheme.primary,
                      mouseCursor: inputEnabled
                          ? SystemMouseCursors.text
                          : SystemMouseCursors.basic,
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        height: 1.4,
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            inputEnabled ? Colors.white : Colors.grey.shade200,
                        isDense: true,
                        hintText: requiredCount == 0
                            ? 'Program-এ scanf() নেই'
                            : inputComplete
                                ? 'সব ইনপুট নেওয়া সম্পন্ন'
                                : _inputHintFor(
                                    nextInputType!,
                                    enteredCount + 1,
                                  ),
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: inputComplete
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_inputValues.isNotEmpty)
                              IconButton(
                                tooltip: 'Remove Last Value',
                                onPressed: _removeLastInputValue,
                                icon: const Icon(Icons.undo),
                              ),
                            IconButton(
                              tooltip: 'Clear Input',
                              onPressed: _clearInput,
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
      margin: EdgeInsets.zero,
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
                  style: GoogleFonts.robotoMono(
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
      margin: EdgeInsets.zero,
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

enum _ScanfInputType {
  integer,
  unsignedInteger,
  floatValue,
  doubleValue,
  character,
  stringValue,
}
