import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/compiler_result.dart';
import '../models/saved_program.dart';
import '../services/bangla_error_service.dart';
import '../services/mock_compiler.dart';
import '../services/program_storage_service.dart';
import 'my_programs_page.dart';
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

  final FocusNode _editorFocusNode = FocusNode();

  final DraggableScrollableController _curtainController =
      DraggableScrollableController();

  final MockCompiler _compiler = const MockCompiler();

  final BanglaErrorService _banglaErrorService = const BanglaErrorService();

  final ProgramStorageService _programStorageService =
      const ProgramStorageService();

  CompilerResult? _result;

  String _banglaExplanation = 'কোড লিখে Run বাটনে ক্লিক করুন।';

  bool _isRunning = false;

  int _lineCount = 1;

  bool _curtainActivated = false;

  SavedProgram? _currentProgram;

  Timer? _autoSaveTimer;

  bool _isApplyingCode = false;

  bool _storageReady = false;

  bool _isSampleMode = false;

  bool _editorHasFocus = false;

  double _curtainExtent = 0.055;

  static const double _wideLayoutBreakpoint = 900;

  static const double _curtainExpandedThreshold = 0.2;

  @override
  void initState() {
    super.initState();

    _updateLineCount();
    _codeController.addListener(_handleCodeChanged);
    _editorFocusNode.addListener(_handleEditorFocusChanged);
    _curtainController.addListener(_handleCurtainExtentChanged);
    unawaited(_initializeProgramStorage());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _codeController.removeListener(_handleCodeChanged);
    _codeController.dispose();
    _inputController.dispose();
    _editorScrollController.dispose();
    _inputFocusNode.dispose();
    _editorFocusNode.removeListener(_handleEditorFocusChanged);
    _editorFocusNode.dispose();
    _curtainController.removeListener(_handleCurtainExtentChanged);
    _curtainController.dispose();

    super.dispose();
  }

  void _handleCurtainExtentChanged() {
    if (!mounted || !_curtainController.isAttached) {
      return;
    }

    final double size = _curtainController.size;
    final bool wasExpanded = _curtainExtent > _curtainExpandedThreshold;
    final bool isExpanded = size > _curtainExpandedThreshold;

    if (wasExpanded == isExpanded) {
      _curtainExtent = size;
      return;
    }

    setState(() {
      _curtainExtent = size;
    });
  }

  void _handleEditorFocusChanged() {
    if (!mounted || _editorHasFocus == _editorFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _editorHasFocus = _editorFocusNode.hasFocus;
    });

    if (_editorHasFocus) {
      _closeCurtain();
    }
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

    if (_isApplyingCode ||
        !_storageReady ||
        _isSampleMode ||
        _currentProgram == null) {
      return;
    }

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 700),
      _autoSaveCurrentProgram,
    );
  }

  Future<void> _initializeProgramStorage() async {
    final SavedProgram? currentProgram =
        await _programStorageService.loadCurrentProgram();

    if (!mounted) {
      return;
    }

    if (currentProgram != null) {
      _applySavedProgram(currentProgram);
    }

    setState(() {
      _storageReady = true;
    });
  }

  Future<void> _autoSaveCurrentProgram() async {
    final SavedProgram? program = _currentProgram;

    if (program == null || _isSampleMode) {
      return;
    }

    final SavedProgram updated = await _programStorageService.saveProgram(
      program,
      sourceCode: _codeController.text,
    );

    if (!mounted || _currentProgram?.id != updated.id) {
      return;
    }

    setState(() {
      _currentProgram = updated;
    });
  }

  Future<void> _flushAutoSave() async {
    _autoSaveTimer?.cancel();

    if (_currentProgram == null || _isSampleMode) {
      return;
    }

    await _autoSaveCurrentProgram();
  }

  void _applySavedProgram(SavedProgram program) {
    _autoSaveTimer?.cancel();
    _isApplyingCode = true;

    _codeController.text = program.sourceCode;
    _codeController.selection = TextSelection.collapsed(
      offset: _codeController.text.length,
    );

    _inputController.clear();
    _inputValues.clear();

    setState(() {
      _currentProgram = program;
      _isSampleMode = false;
      _result = null;
      _banglaExplanation = '${program.displayName} খোলা হয়েছে।';
    });

    _isApplyingCode = false;
    unawaited(
      _programStorageService.setCurrentProgram(program),
    );
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

      if (_curtainActivated) {
        Future<void>.microtask(_compileAndShowResult);
      }
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
          return 'ঋণাত্মক নয় এমন পূর্ণসংখ্যা লিখে Enter চাপুন।';
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
          return '%s-এর জন্য স্পেস ছাড়া একটি শব্দ লিখুন।';
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
    await _flushAutoSave();

    setState(() {
      _inputController.clear();
      _inputValues.clear();
      _result = null;
      _banglaExplanation = 'নতুন Input দিন, Run সম্পন্ন হলে ফলাফল দেখাবে।';
    });

    final int requiredCount = _requiredInputCount();
    final bool needsInput = _inputValues.length < requiredCount;

    setState(() {
      _curtainActivated = true;
    });

    _openCurtain();

    if (needsInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
        }
      });
      return;
    }

    await _compileAndShowResult();
  }

  Future<void> _compileAndShowResult() async {
    if (_isRunning) {
      return;
    }

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
      _curtainActivated = true;
    });

    _openCurtain();
  }

  void _openCurtain() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_curtainController.isAttached) {
        return;
      }

      _curtainController.animateTo(
        0.84,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _closeCurtain() {
    if (!_curtainController.isAttached) {
      return;
    }

    _curtainController.animateTo(
      0.055,
      duration: const Duration(milliseconds: 820),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _newProgram() async {
    await _flushAutoSave();

    if (!mounted) {
      return;
    }

    try {
      final SavedProgram program = await _programStorageService.createProgram();

      if (!mounted) {
        return;
      }

      _applySavedProgram(program);
    } on ProgramStorageLimitException {
      _showInputMessage(
        'Maximum 100 programs reached. '
        'নতুন Program তৈরি করতে আগে My Programs থেকে '
        'একটি Program Delete করুন।',
      );
    }
  }

  Future<void> _loadSampleProgram() async {
    await _flushAutoSave();

    if (!mounted) {
      return;
    }

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

    _autoSaveTimer?.cancel();
    _isApplyingCode = true;

    _codeController.text = selectedCode;
    _codeController.selection = TextSelection.collapsed(
      offset: _codeController.text.length,
    );

    _inputController.clear();
    _inputValues.clear();

    setState(() {
      _currentProgram = null;
      _isSampleMode = true;
      _result = null;
      _banglaExplanation = 'Sample Program লোড হয়েছে। '
          'কোড পরিবর্তন করে Run করতে পারবেন।';
    });

    _isApplyingCode = false;
  }

  Future<void> _openMyPrograms() async {
    await _flushAutoSave();

    if (!mounted) {
      return;
    }

    final SavedProgram? selectedProgram =
        await Navigator.of(context).push<SavedProgram>(
      MaterialPageRoute<SavedProgram>(
        builder: (BuildContext context) {
          return const MyProgramsPage();
        },
      ),
    );

    if (!mounted || selectedProgram == null) {
      return;
    }

    _applySavedProgram(selectedProgram);
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

  void _insertSymbol(String symbol) {
    final String currentText = _codeController.text;
    final TextSelection selection = _codeController.selection;

    final int start = selection.isValid
        ? selection.start.clamp(0, currentText.length)
        : currentText.length;

    final int end = selection.isValid
        ? selection.end.clamp(0, currentText.length)
        : currentText.length;

    final String updatedText = currentText.replaceRange(
      start,
      end,
      symbol,
    );

    _codeController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: start + symbol.length,
      ),
    );

    _editorFocusNode.requestFocus();
  }

  Widget _buildSymbolAccessoryBar() {
    const List<String> symbols = <String>[
      ';',
      '{',
      '}',
      '(',
      ')',
      '[',
      ']',
      '"',
      "'",
      '#',
      '<',
      '>',
      '=',
      '+',
      '-',
      '*',
      '/',
      '%',
      '&',
      '|',
      '!',
      ':',
      ',',
    ];

    return SizedBox(
      height: 40,
      child: Container(
        // কীবোর্ডের থিমের সাথে মানানসই সলিড নিউট্রাল ব্যাকগ্রাউন্ড কালার
        color: const Color(0xFFE5E7EB),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          itemCount: symbols.length,
          separatorBuilder: (
            BuildContext context,
            int index,
          ) {
            return const SizedBox(width: 5);
          },
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final String symbol = symbols[index];

            return OutlinedButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(36, 32),
                maximumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                foregroundColor: Colors.black,
                overlayColor: Colors.transparent,
                side: BorderSide(color: Colors.grey.shade300),
                textStyle: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _insertSymbol(symbol);
              },
              child: Text(symbol),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    
    // শুধুমাত্র Code Editor-এ ফোকাস থাকা অবস্থায় এবং কিবোর্ড ওপেন থাকলে Symbol Bar দেখাবে
    final bool showSymbolBar = keyboardOpen && _editorHasFocus;

    final bool wideScreen =
        MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;
    final bool showFloatingRunButton = !wideScreen && keyboardOpen;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student C Studio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            Text(
              'Write → Run → Learn',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Output',
            onPressed: _clearOutput,
            icon: const Icon(
              Icons.cleaning_services_outlined,
              size: 21,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool isWide = constraints.maxWidth >= _wideLayoutBreakpoint;

            if (isWide) {
              return _buildWideLayout();
            }

            return _buildNarrowLayout(
              keyboardOpen: keyboardOpen,
              showSymbolBar: showSymbolBar,
              availableHeight: constraints.maxHeight,
            );
          },
        ),
      ),
      floatingActionButton:
          showFloatingRunButton ? _buildFloatingRunButton() : null,
      bottomNavigationBar: _buildStatusBar(),
    );
  }

  Widget _buildFloatingRunButton() {
    return FloatingActionButton(
      heroTag: 'runProgramFab',
      tooltip: _isRunning ? 'Running...' : 'Run',
      onPressed: _isRunning ? null : _runProgram,
      child: _isRunning
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.play_arrow),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildEditorSection(showActionButtons: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: _buildInputSection(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _buildOutputSection(),
                ),
                const SizedBox(height: 14),
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

  Widget _buildNarrowLayout({
    required bool keyboardOpen,
    required bool showSymbolBar,
    required double availableHeight,
  }) {
    const double collapsedPeekHeight = 34;
    const double symbolBarHeight = 40.0;

    final double minChildSize =
        (collapsedPeekHeight / availableHeight).clamp(0.035, 0.12);

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            10,
            10,
            keyboardOpen ? (showSymbolBar ? 50 : 10) : 46,
          ),
          child: _buildEditorSection(showActionButtons: !keyboardOpen),
        ),
        
        // Symbol Bar দৃশ্যমান থাকলে কার্টিনকে Symbol Bar-এর ঠিক উপরে তুলে দেওয়া
        Positioned.fill(
          bottom: showSymbolBar ? symbolBarHeight : 0,
          child: DraggableScrollableSheet(
            controller: _curtainController,
            initialChildSize: minChildSize,
            minChildSize: minChildSize,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: <double>[minChildSize, 0.84, 0.92],
            builder: (
              BuildContext context,
              ScrollController scrollController,
            ) {
              return _buildCurtain(
                scrollController,
                keyboardOpen: keyboardOpen,
              );
            },
          ),
        ),

        // Symbol Bar শুধুমাত্র তখনই রেন্ডার হবে যখন Code Editor ফোকাসড থাকবে
        if (showSymbolBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: symbolBarHeight,
            child: _buildSymbolAccessoryBar(),
          ),
      ],
    );
  }

  Widget _buildCurtain(
    ScrollController scrollController, {
    required bool keyboardOpen,
  }) {
    final bool curtainExpanded = _curtainExtent > _curtainExpandedThreshold;

    return Material(
      elevation: 14,
      color: const Color(0xFFF4F6F8),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              child: const SizedBox(
                height: 26,
                child: Center(
                  child: _CurtainHandle(),
                ),
              ),
            ),
          ),
          Expanded(
            child: curtainExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      8,
                      0,
                      8,
                      8,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: keyboardOpen ? 5 : 2,
                          child: _buildInputSection(),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: keyboardOpen ? 2 : 5,
                          child: _buildOutputSection(),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: keyboardOpen ? 2 : 2,
                          child: _buildBanglaExplanationSection(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection({required bool showActionButtons}) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader(
            icon: Icons.description_outlined,
            title: _isSampleMode
                ? 'Sample Program'
                : _currentProgram?.displayName ?? 'Program.c',
            trailing: '${_codeController.text.length} chars',
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
                      focusNode: _editorFocusNode,
                      onTap: _closeCurtain,
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
                        contentPadding: const EdgeInsets.all(14),
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
          if (showActionButtons) ...[
            const Divider(height: 1),
            _buildEditorButtons(),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildLineNumberPanel() {
    return Container(
      width: 48,
      color: const Color(0xFF252526),
      padding: const EdgeInsets.only(
        top: 14,
        right: 8,
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
    final ButtonStyle compactButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 32),
      maximumSize: const Size(double.infinity, 32),
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 2,
      ),
      textStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final ButtonStyle runButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 30),
      maximumSize: const Size(double.infinity, 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 2,
      ),
      textStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        6,
        8,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: compactButtonStyle,
                  onPressed: _storageReady ? _newProgram : null,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('New Program'),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  style: compactButtonStyle,
                  onPressed: _loadSampleProgram,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Sample Program'),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  style: compactButtonStyle,
                  onPressed: _storageReady ? _openMyPrograms : null,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('My Programs'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            style: runButtonStyle,
            onPressed: _isRunning ? null : _runProgram,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.play_arrow,
                    size: 20,
                  ),
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
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_inputValues.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
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
                      ),
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 46,
                    ),
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
                                ? 'সব ইনপুট নেওয়া সম্পন্ন'
                                : _inputHintFor(
                                    nextInputType!,
                                    enteredCount + 1,
                                  ),
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
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
              padding: const EdgeInsets.all(14),
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
              padding: const EdgeInsets.all(14),
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
        horizontal: 12,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
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
      height: 28,
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 13,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            'Lines: $_lineCount',
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'C Language',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Jahirul Islam',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurtainHandle extends StatelessWidget {
  const _CurtainHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade400,
        borderRadius: BorderRadius.circular(99),
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