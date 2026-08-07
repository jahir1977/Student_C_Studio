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

  // সোর্স কোডে scanf() লেখা যতবার আছে তার হিসাবে নয়, বরং লুপের ভেতরের
  // scanf()-কে বারবার মান নেওয়ার (repeatable) সুযোগ দেওয়া হয়েছে কিনা তার state।
  bool _repeatableInputConfirmed = false;

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

    // Repeatable (loop-এর ভেতরের) শেষ scanf()-এর জন্য ইউজার ন্যূনতম সংখ্যার
    // চেয়ে বেশি মান দিয়ে থাকতে পারে (যেমন: অ্যারে ফিল করার সময়) — সেগুলো
    // কেটে ফেলা যাবে না।
    if (_inputValues.length > requiredCount && !_hasRepeatableTailInput()) {
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
    _repeatableInputConfirmed = false;

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

  // scanf() টেক্সট সোর্স কোডে কতবার লেখা আছে সেটা গুনেই আগে ইনপুট ফিল্ড
  // সংখ্যা ঠিক হতো। কিন্তু for/while/do-while লুপের ভেতরে থাকা একটা scanf()
  // রানটাইমে বহুবার execute হতে পারে (যেমন: অ্যারে ফিল করার সময়)। তাই এখন
  // প্রতিটা লুপকে আগে বিশ্লেষণ করা হয় — যদি লুপের বাউন্ড (যেমন
  // `for (i = 0; i < 5; i++)`) সম্পূর্ণ লিটারেল সংখ্যার উপর নির্ভর করে
  // (কোনো ভ্যারিয়েবল/ইনপুটের উপর না), তাহলে ঠিক কতবার লুপ চলবে তা প্রোগ্রাম
  // না চালিয়েই গণনা করা যায় — সেক্ষেত্রে ঠিক ততগুলো ফিক্সড ইনপুট স্লট
  // বানানো হয়। বাউন্ড যদি runtime-নির্ভর হয় (যেমন আগের একটা scanf() থেকে
  // পাওয়া n), তখন সংখ্যা আগে থেকে জানা সম্ভব না — তাই সেই scanf()-কে
  // repeatable ধরা হয়, আর UI-তে ইউজার নিজে "✓ ইনপুট শেষ" বাটনে চেপে জানাবে।
  List<_ScanfInputSlot> _requiredInputSlots() {
    final String source = _codeController.text;
    final List<_LoopRange> loopRanges = _findLoopRanges(source);

    final RegExp scanfPattern = RegExp(
      r'scanf\s*\(\s*"((?:\\.|[^"\\])*)"',
      multiLine: true,
    );

    final List<_ScanfInputSlot> inputSlots = <_ScanfInputSlot>[];

    for (final RegExpMatch match in scanfPattern.allMatches(source)) {
      final List<_LoopRange> containingRanges = loopRanges
          .where(
            (_LoopRange range) =>
                match.start >= range.start && match.start < range.end,
          )
          .toList();

      // নেস্টেড লুপ হলে (যেমন ২ডি অ্যারে ফিল) প্রতিটা লুপের ইটারেশন সংখ্যা
      // গুণ করে মোট repeat সংখ্যা বের করা হচ্ছে। কোনো একটা লুপের বাউন্ড
      // অজানা হলে পুরো ফলাফলই অজানা (null) হয়ে যাবে।
      int? fixedRepeatCount;

      if (containingRanges.isNotEmpty) {
        fixedRepeatCount = 1;

        for (final _LoopRange range in containingRanges) {
          if (range.iterationCount == null) {
            fixedRepeatCount = null;
            break;
          }

          fixedRepeatCount = fixedRepeatCount! * range.iterationCount!;
        }

        const int maxFixedSlots = 200;

        if (fixedRepeatCount != null && fixedRepeatCount > maxFixedSlots) {
          // অনেক বড় লুপের জন্য শতশত ফিক্সড ফিল্ড বানানো UI-এর জন্য
          // অস্বাভাবিক — তাই সেক্ষেত্রে repeatable মোডেই ফিরে যাওয়া হচ্ছে।
          fixedRepeatCount = null;
        }
      }

      final bool repeatable =
          containingRanges.isNotEmpty && fixedRepeatCount == null;

      final int repeatTimes = fixedRepeatCount ?? 1;

      void addSlot(_ScanfInputType type) {
        for (int repeat = 0; repeat < repeatTimes; repeat++) {
          inputSlots.add(
            _ScanfInputSlot(type: type, repeatable: repeatable),
          );
        }
      }

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
          addSlot(_ScanfInputType.doubleValue);
          index = specifierIndex + 2;
          continue;
        }

        final String specifier = format[specifierIndex];

        switch (specifier) {
          case 'd':
          case 'i':
            addSlot(_ScanfInputType.integer);
            break;
          case 'u':
            addSlot(_ScanfInputType.unsignedInteger);
            break;
          case 'f':
            addSlot(_ScanfInputType.floatValue);
            break;
          case 'c':
            addSlot(_ScanfInputType.character);
            break;
          case 's':
            addSlot(_ScanfInputType.stringValue);
            break;
        }

        index = specifierIndex + 1;
      }
    }

    return inputSlots;
  }

  List<_ScanfInputType> _requiredInputTypes() {
    return _requiredInputSlots()
        .map((_ScanfInputSlot slot) => slot.type)
        .toList();
  }

  int _requiredInputCount() {
    return _requiredInputTypes().length;
  }

  // শেষ scanf() স্লটটা কোনো লুপের ভেতরে থাকলে true — অর্থাৎ ন্যূনতম সংখ্যক
  // মান দেওয়ার পরও ইউজারকে আরও মান (যেমন: অ্যারের বাকি এলিমেন্ট) দেওয়ার
  // সুযোগ রাখা দরকার, এবং কখন শেষ হবে তা ইউজার নিজে জানাবে।
  bool _hasRepeatableTailInput() {
    final List<_ScanfInputSlot> slots = _requiredInputSlots();
    return slots.isNotEmpty && slots.last.repeatable;
  }

  bool _isInputReady() {
    final int requiredCount = _requiredInputCount();

    if (_inputValues.length < requiredCount) {
      return false;
    }

    if (_hasRepeatableTailInput() && !_repeatableInputConfirmed) {
      return false;
    }

    return true;
  }

  void _submitInputValue(String value) {
    final List<_ScanfInputSlot> requiredSlots = _requiredInputSlots();

    if (requiredSlots.isEmpty) {
      return;
    }

    final bool withinFixedSlots = _inputValues.length < requiredSlots.length;
    final bool tailRepeatable = requiredSlots.last.repeatable;

    if (!withinFixedSlots && !tailRepeatable) {
      // নির্দিষ্ট সংখ্যক ইনপুট আগেই দেওয়া শেষ, আর শেষ scanf() কোনো লুপে নেই —
      // তাই আর নতুন মান নেওয়ার দরকার নেই।
      return;
    }

    final _ScanfInputType expectedType = withinFixedSlots
        ? requiredSlots[_inputValues.length].type
        : requiredSlots.last.type;

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

    final bool nowWithinFixedSlots = _inputValues.length < requiredSlots.length;

    if (!nowWithinFixedSlots && !tailRepeatable) {
      // ফিক্সড (loop-বিহীন) সব scanf() পূরণ হয়ে গেছে — আগের মতোই সরাসরি Run।
      _inputFocusNode.unfocus();

      if (_curtainActivated) {
        Future<void>.microtask(_compileAndShowResult);
      }
    } else {
      // হয় এখনো ফিক্সড স্লট বাকি আছে, অথবা শেষ scanf() লুপে আছে — তাই
      // ফিল্ড খোলা রাখা হচ্ছে, ইউজার চাইলে আরও মান দিতে পারবে। Repeatable
      // ক্ষেত্রে "ইনপুট শেষ" বাটন চাপার আগ পর্যন্ত Run হবে না।
      _inputFocusNode.requestFocus();
    }
  }

  void _confirmRepeatableInputAndRun() {
    setState(() {
      _repeatableInputConfirmed = true;
    });

    _inputFocusNode.unfocus();

    if (_curtainActivated) {
      Future<void>.microtask(_compileAndShowResult);
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
      _repeatableInputConfirmed = false;
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
      _repeatableInputConfirmed = false;
      _result = null;
      _banglaExplanation = 'নতুন Input দিন, Run সম্পন্ন হলে ফলাফল দেখাবে।';
    });

    final bool needsInput = !_isInputReady();

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

    final String explanation = result.isSuccess
        ? 'প্রোগ্রাম সফলভাবে Run করেছে।'
        : (result.banglaExplanation.trim().isNotEmpty
            ? result.banglaExplanation
            : _banglaErrorService.explain(result.error));

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
    _repeatableInputConfirmed = false;

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
      _repeatableInputConfirmed = false;
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
    final List<_ScanfInputSlot> requiredSlots = _requiredInputSlots();
    final List<_ScanfInputType> requiredTypes =
        requiredSlots.map((_ScanfInputSlot slot) => slot.type).toList();

    final int requiredCount = requiredTypes.length;
    final int enteredCount = _inputValues.length;
    final bool tailRepeatable = _hasRepeatableTailInput();

    // repeatable (loop-এর ভেতরের) শেষ scanf()-এর ক্ষেত্রে ন্যূনতম সংখ্যা
    // পূরণ হলেও ফিল্ড lock হবে না — ইউজার নিজে "ইনপুট শেষ" বাটনে না চাপা
    // পর্যন্ত আরও মান নেওয়া যাবে।
    final bool inputComplete = requiredCount > 0 &&
        enteredCount >= requiredCount &&
        (!tailRepeatable || _repeatableInputConfirmed);

    final bool inputEnabled = requiredCount > 0 && !inputComplete;

    final bool awaitingRepeatableConfirmation = requiredCount > 0 &&
        enteredCount >= requiredCount &&
        tailRepeatable &&
        !_repeatableInputConfirmed;

    final _ScanfInputType? nextInputType = inputEnabled
        ? (enteredCount < requiredCount
            ? requiredTypes[enteredCount]
            : requiredTypes.last)
        : null;

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
            trailing: tailRepeatable
                ? '$enteredCount / $requiredCount+'
                : '$enteredCount / $requiredCount',
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
                                // repeatable (loop) স্লটের জন্য _inputValues
                                // -এর দৈর্ঘ্য requiredTypes-এর চেয়ে বেশি হতে
                                // পারে — তখন শেষ টাইপটাই বারবার প্রযোজ্য।
                                final _ScanfInputType typeForChip =
                                    index < requiredTypes.length
                                        ? requiredTypes[index]
                                        : requiredTypes.last;

                                return Chip(
                                  label: Text(
                                    '${index + 1} '
                                    '(${_formatLabelFor(typeForChip)}): '
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
                                : awaitingRepeatableConfirmation
                                    ? 'আরও মান দিন, অথবা ✓ বাটনে চেপে Run করুন'
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
                            if (awaitingRepeatableConfirmation)
                              IconButton(
                                tooltip: 'ইনপুট শেষ, Run করুন',
                                onPressed: _confirmRepeatableInputAndRun,
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
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

/// একটা scanf() ফরম্যাট-স্পেসিফায়ার থেকে তৈরি হওয়া ইনপুট স্লট।
/// [repeatable] true মানে এই scanf() কল কোনো for/while/do-while লুপের
/// শরীরের ভেতরে আছে — তাই রানটাইমে একাধিকবার এক্সিকিউট হতে পারে, এবং
/// UI-কে এই টাইপের জন্য একাধিক মান নেওয়ার সুযোগ দিতে হবে।
class _ScanfInputSlot {
  const _ScanfInputSlot({
    required this.type,
    required this.repeatable,
  });

  final _ScanfInputType type;
  final bool repeatable;
}

/// সোর্স কোডে একটা লুপ বডির ক্যারেক্টার রেঞ্জ [start, end)। [iterationCount]
/// জানা থাকলে (শুধুমাত্র for-লুপে, যখন বাউন্ড সম্পূর্ণ লিটারেল সংখ্যার
/// উপর নির্ভর করে) এটা লুপটা ঠিক কতবার চলবে তা বহন করে — অন্যথায় null।
class _LoopRange {
  const _LoopRange(this.start, this.end, {this.iterationCount});

  final int start;
  final int end;
  final int? iterationCount;
}

/// সোর্স কোডে for/while/do-while লুপের বডি (ব্রেস দিয়ে ঘেরা অংশ) খুঁজে বের
/// করে তাদের ক্যারেক্টার রেঞ্জ রিটার্ন করে। শুধুমাত্র brace ({ }) দিয়ে ঘেরা
/// বডি হ্যান্ডেল করা হয় — সিঙ্গেল-স্টেটমেন্ট (ব্রেসবিহীন) লুপ বডি এই
/// হেল্পারের আওতার বাইরে, কারণ শিক্ষার্থীদের প্রোগ্রামে সেটা বিরল এবং
/// UI-এর জন্য শুধু "লুপের ভেতরে scanf() আছে কিনা" বোঝাই যথেষ্ট।
List<_LoopRange> _findLoopRanges(String source) {
  final List<_LoopRange> ranges = <_LoopRange>[];
  final RegExp headerPattern = RegExp(r'\b(for|while|do)\b');

  for (final RegExpMatch header in headerPattern.allMatches(source)) {
    final String keyword = header.group(1)!;

    if (keyword == 'do') {
      int probe = header.end;

      while (probe < source.length && RegExp(r'\s').hasMatch(source[probe])) {
        probe++;
      }

      if (probe >= source.length || source[probe] != '{') {
        continue;
      }

      final int braceEnd = _matchBrace(source, probe);

      if (braceEnd < 0) {
        continue;
      }

      ranges.add(_LoopRange(probe, braceEnd + 1));
      continue;
    }

    // for / while: এরপর সবার আগে যে '(' পাওয়া যাবে সেটাই হেডারের শুরু,
    // যদি মাঝে শুধু হোয়াইটস্পেস থাকে (নাহলে এটা for/while শব্দ থেকে অন্য
    // কোনো আইডেন্টিফায়ারের অংশ, বা মিলবে না)।
    int headerProbe = header.end;

    while (headerProbe < source.length &&
        RegExp(r'\s').hasMatch(source[headerProbe])) {
      headerProbe++;
    }

    if (headerProbe >= source.length || source[headerProbe] != '(') {
      continue;
    }

    final int parenEnd = _matchParen(source, headerProbe);

    if (parenEnd < 0) {
      continue;
    }

    int bodyProbe = parenEnd + 1;

    while (bodyProbe < source.length &&
        RegExp(r'\s').hasMatch(source[bodyProbe])) {
      bodyProbe++;
    }

    if (bodyProbe >= source.length || source[bodyProbe] != '{') {
      continue;
    }

    final int braceEnd = _matchBrace(source, bodyProbe);

    if (braceEnd < 0) {
      continue;
    }

    // for-লুপের ক্ষেত্রে বাউন্ড লিটারেল সংখ্যার উপর নির্ভর করলে ঠিক কতবার
    // চলবে তা এখনই গণনা করা সম্ভব — নাহলে (while, অথবা variable-নির্ভর
    // বাউন্ডের for) iterationCount অজানা (null) থেকে যায়।
    final int? iterationCount = keyword == 'for'
        ? _computeForLoopIterationCount(
            source.substring(headerProbe + 1, parenEnd),
          )
        : null;

    ranges.add(
      _LoopRange(bodyProbe, braceEnd + 1, iterationCount: iterationCount),
    );
  }

  return ranges;
}

/// `for (init; condition; update)` হেডার থেকে (প্যারেনথিসিসের ভেতরের অংশ)
/// ঠিক কতবার লুপ চলবে তা বের করার চেষ্টা করে — একমাত্র তখনই যখন init,
/// condition, update সবগুলোই লিটারেল সংখ্যার উপর নির্ভরশীল (কোনো
/// ভ্যারিয়েবল/scanf() থেকে পাওয়া মানের উপর না)। সম্ভব না হলে null।
int? _computeForLoopIterationCount(String header) {
  final List<String> sections = <String>[];

  int depth = 0;
  int sectionStart = 0;

  for (int index = 0; index < header.length; index++) {
    final String character = header[index];

    if (character == '(') {
      depth++;
    } else if (character == ')') {
      depth--;
    } else if (character == ';' && depth == 0) {
      sections.add(header.substring(sectionStart, index));
      sectionStart = index + 1;
    }
  }

  sections.add(header.substring(sectionStart));

  if (sections.length != 3) {
    return null;
  }

  final String initSection = sections[0].trim();
  final String conditionSection = sections[1].trim();
  final String updateSection = sections[2].trim();

  final RegExpMatch? initMatch = RegExp(
    r'^(?:int\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-+]?\d+)$',
  ).firstMatch(initSection);

  if (initMatch == null) {
    return null;
  }

  final String variable = initMatch.group(1)!;
  int value = int.parse(initMatch.group(2)!);

  final RegExpMatch? conditionMatch = RegExp(
    r'^' + RegExp.escape(variable) + r'\s*(<=|>=|!=|<|>)\s*([-+]?\d+)$',
  ).firstMatch(conditionSection);

  if (conditionMatch == null) {
    return null;
  }

  final String operator = conditionMatch.group(1)!;
  final int bound = int.parse(conditionMatch.group(2)!);

  int? step;

  final RegExpMatch? incrementMatch = RegExp(
    r'^' + RegExp.escape(variable) + r'\s*(\+\+|--)$',
  ).firstMatch(updateSection);

  if (incrementMatch != null) {
    step = incrementMatch.group(1) == '++' ? 1 : -1;
  } else {
    final RegExpMatch? compoundMatch = RegExp(
      r'^' + RegExp.escape(variable) + r'\s*(\+=|-=)\s*(\d+)$',
    ).firstMatch(updateSection);

    if (compoundMatch != null) {
      final int magnitude = int.parse(compoundMatch.group(2)!);
      step = compoundMatch.group(1) == '+=' ? magnitude : -magnitude;
    } else {
      final RegExpMatch? assignmentUpdateMatch = RegExp(
        r'^' +
            RegExp.escape(variable) +
            r'\s*=\s*' +
            RegExp.escape(variable) +
            r'\s*([+\-])\s*(\d+)$',
      ).firstMatch(updateSection);

      if (assignmentUpdateMatch != null) {
        final int magnitude = int.parse(assignmentUpdateMatch.group(2)!);

        step = assignmentUpdateMatch.group(1) == '+' ? magnitude : -magnitude;
      }
    }
  }

  if (step == null || step == 0) {
    return null;
  }

  bool conditionHolds(int current) {
    switch (operator) {
      case '<':
        return current < bound;
      case '<=':
        return current <= bound;
      case '>':
        return current > bound;
      case '>=':
        return current >= bound;
      case '!=':
        return current != bound;
    }

    return false;
  }

  const int maxIterationsToCount = 500;

  int count = 0;

  while (conditionHolds(value)) {
    count++;

    if (count > maxIterationsToCount) {
      return null;
    }

    value += step;
  }

  return count;
}

int _matchParen(String source, int openIndex) {
  int depth = 0;

  for (int index = openIndex; index < source.length; index++) {
    if (source[index] == '(') {
      depth++;
    } else if (source[index] == ')') {
      depth--;

      if (depth == 0) {
        return index;
      }
    }
  }

  return -1;
}

int _matchBrace(String source, int openIndex) {
  int depth = 0;

  for (int index = openIndex; index < source.length; index++) {
    if (source[index] == '{') {
      depth++;
    } else if (source[index] == '}') {
      depth--;

      if (depth == 0) {
        return index;
      }
    }
  }

  return -1;
}
