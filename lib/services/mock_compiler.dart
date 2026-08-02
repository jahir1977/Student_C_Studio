import '../models/compiler_result.dart';
import 'checkers/header_checker.dart';

import 'checkers/quote_checker.dart';
import 'checkers/parenthesis_checker.dart';
import 'checkers/brace_checker.dart';
import 'checkers/function_checker.dart';
import 'checkers/identifier_checker.dart';
import 'checkers/input_output_checker.dart';
import 'checkers/format_specifier_checker.dart';
import 'checkers/string_checker.dart';
import 'checkers/pointer_checker.dart';


import 'checkers/variable_declaration_checker.dart';
import 'checkers/loop_checker.dart';
import 'checkers/if_checker.dart';
import 'checkers/switch_checker.dart';
import 'checkers/while_checker.dart';
import 'checkers/expression_checker.dart';
import '../models/compiler_context.dart';
import 'compiler_context_builder.dart';
import 'checkers/default_checker_registry.dart';

typedef CompilerContextFactory = CompilerContext Function(
  String source,
);

class MockCompiler {
  final CompilerContextFactory _contextBuilder;

  const MockCompiler({
    CompilerContextFactory contextBuilder = CompilerContextBuilder.build,
  }) : _contextBuilder = contextBuilder;

  CompilerResult compile(String code) {
    final String source = code;

    if (source.trim().isEmpty) {
      return CompilerResult.failure(
        error: 'No code found.',
        explanation: 'কোনো কোড লেখা হয়নি।',
      );
    }

    final CompilerContext context = _contextBuilder(source);

    // Private output extraction still consumes sanitized source.
    final String codeWithoutComments = context.sanitizedSource;

    // ==================================================
    // CompilerContext Pipeline
    //
    // Raw source -> CompilerContextBuilder
    // -> one shared CompilerContext
    // -> all context-aware checkers
    // ==================================================

    // --------------------------------------------------
    // Phase 1: Existing stable compiler pipeline
    // --------------------------------------------------
  final CompilerResult? earlyCheckerResult =
    _runRegistryCheckers(context);

  if (earlyCheckerResult != null) {
    return earlyCheckerResult;
}
    // --------------------------------------------------
    // Phase 5: Statement and declaration checkers
    // --------------------------------------------------

    final int? semicolonErrorLine =
        _findMissingSemicolon(context.sanitizedLines);

    if (semicolonErrorLine != null) {
      return CompilerResult.failure(
        error: "expected ';'",
        explanation: '',
        errorLine: semicolonErrorLine,
      );
    }

    final VariableCheckResult variableResult =
        VariableDeclarationChecker.checkContext(
      context,
    );

    if (!variableResult.isValid) {
      return CompilerResult.failure(
        error: variableResult.error,
        explanation: variableResult.explanation,
        errorLine: variableResult.line,
      );
    }

    final CompilerResult loopResult = LoopChecker().checkContext(context);

    if (!loopResult.isSuccess) {
      return loopResult;
    }

    final CompilerResult ifResult = IfChecker().checkContext(context);

    if (!ifResult.isSuccess) {
      return ifResult;
    }

    final CompilerResult switchResult = SwitchChecker().checkContext(context);

    if (!switchResult.isSuccess) {
      return switchResult;
    }

    final CompilerResult whileResult = WhileChecker().checkContext(context);

    if (!whileResult.isSuccess) {
      return whileResult;
    }

    final CompilerResult expressionResult =
        ExpressionChecker().checkContext(context);

    if (!expressionResult.isSuccess) {
      return expressionResult;
    }

    // --------------------------------------------------
    // Phase 6: Newly integrated checker pipeline
    //
    // পুরোনো checker-গুলোর error precedence ঠিক রাখার জন্য
    // এই checker-গুলো stable pipeline-এর পরে চালানো হচ্ছে।
    // --------------------------------------------------

    final CompilerResult headerResult = HeaderChecker().checkContext(context);

    if (!headerResult.isSuccess) {
      return headerResult;
    }

    final CompilerResult quoteResult = QuoteChecker().checkContext(context);

    if (!quoteResult.isSuccess) {
      return quoteResult;
    }

    final CompilerResult parenthesisResult =
        ParenthesisChecker().checkContext(context);

    if (!parenthesisResult.isSuccess) {
      return parenthesisResult;
    }

    final CompilerResult braceResult = BraceChecker().checkContext(context);

    if (!braceResult.isSuccess) {
      return braceResult;
    }

    final CompilerResult functionResult =
        FunctionChecker().checkContext(context);

    if (!functionResult.isSuccess) {
      return functionResult;
    }

    final CompilerResult? identifierResult =
        IdentifierChecker.checkContext(context);

    if (identifierResult != null && !identifierResult.isSuccess) {
      return identifierResult;
    }

    final CompilerResult inputOutputResult =
        InputOutputChecker().checkContext(context);

    if (!inputOutputResult.isSuccess) {
      return inputOutputResult;
    }

    final CompilerResult formatSpecifierResult =
        FormatSpecifierChecker().checkContext(
      context,
    );

    if (!formatSpecifierResult.isSuccess) {
      return formatSpecifierResult;
    }

    final CompilerResult stringResult = StringChecker.checkContext(context);

    if (!stringResult.isSuccess) {
      return stringResult;
    }

    final CompilerResult pointerResult = PointerChecker.checkContext(context);

    if (!pointerResult.isSuccess) {
      return pointerResult;
    }

    final String output = _extractPrintfOutput(codeWithoutComments);

    return CompilerResult.success(
      output: output,
    );
  }

  // --------------------------------------------------
  // Semicolon validation
  // --------------------------------------------------

  int? _findMissingSemicolon(List<String> lines) {
    final List<String> braceTypeStack = <String>[];

    String? pendingBlockType;

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index].trim();

      if (line.isEmpty) {
        continue;
      }

      if (_isPreprocessorLine(line)) {
        continue;
      }

      if (_isInlineDoWhileEnding(line)) {
        if (braceTypeStack.isNotEmpty) {
          braceTypeStack.removeLast();
        }

        if (!line.endsWith(';')) {
          return index + 1;
        }

        continue;
      }

      if (_isElseAfterBrace(line)) {
        if (braceTypeStack.isNotEmpty) {
          braceTypeStack.removeLast();
        }

        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        } else {
          pendingBlockType = 'other';
        }

        continue;
      }

      if (line.startsWith('}')) {
        final String? poppedType =
            braceTypeStack.isNotEmpty ? braceTypeStack.removeLast() : null;

        final bool needsSemicolon =
            poppedType == 'struct' || poppedType == 'enum';

        if (needsSemicolon && !line.endsWith(';')) {
          return index + 1;
        }

        continue;
      }

      if (_isLabel(line) || _isCaseOrDefaultLabel(line)) {
        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        }

        continue;
      }

      final String? structHeaderType = _matchStructOrEnumHeader(line);

      if (structHeaderType != null) {
        if (line.endsWith('{')) {
          braceTypeStack.add(structHeaderType);
        } else {
          pendingBlockType = structHeaderType;
        }

        continue;
      }

      if (_isFunctionDefinitionHeader(lines, index)) {
        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        } else {
          pendingBlockType = 'other';
        }

        continue;
      }

      if (_isConditionalHeader(line)) {
        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        } else {
          pendingBlockType = 'other';
        }

        continue;
      }

      if (_isDoWhileEnding(lines, index)) {
        if (!line.endsWith(';')) {
          return index + 1;
        }

        continue;
      }

      if (_isLoopHeader(line)) {
        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        } else {
          pendingBlockType = 'other';
        }

        continue;
      }

      if (line == '{') {
        braceTypeStack.add(
          pendingBlockType ?? 'other',
        );

        pendingBlockType = null;
        continue;
      }

      final String? currentBlock =
          braceTypeStack.isNotEmpty ? braceTypeStack.last : null;

      if (currentBlock == 'enum') {
        continue;
      }

      if (_isContinuedLine(line)) {
        continue;
      }

      if (!line.endsWith(';')) {
        return index + 1;
      }
    }

    return null;
  }

  bool _isPreprocessorLine(String line) {
    return line.startsWith('#');
  }

  bool _isLabel(String line) {
    final RegExp labelPattern = RegExp(
      r'^[A-Za-z_]\w*\s*:$',
    );

    return labelPattern.hasMatch(line);
  }

  bool _isCaseOrDefaultLabel(String line) {
    final RegExp casePattern = RegExp(
      r'^case\s+.+:\s*\{?\s*$',
    );

    final RegExp defaultPattern = RegExp(
      r'^default\s*:\s*\{?\s*$',
    );

    return casePattern.hasMatch(line) || defaultPattern.hasMatch(line);
  }

  // --------------------------------------------------
  // struct / union / enum header detection
  // --------------------------------------------------

  String? _matchStructOrEnumHeader(
    String line,
  ) {
    final RegExp enumPattern = RegExp(
      r'^(?:typedef\s+)?enum(?:\s+[A-Za-z_]\w*)?\s*\{?\s*$',
    );

    final RegExp structOrUnionPattern = RegExp(
      r'^(?:typedef\s+)?(?:struct|union)(?:\s+[A-Za-z_]\w*)?\s*\{?\s*$',
    );

    if (enumPattern.hasMatch(line)) {
      return 'enum';
    }

    if (structOrUnionPattern.hasMatch(line)) {
      return 'struct';
    }

    return null;
  }

  // --------------------------------------------------
  // Function header detection
  // --------------------------------------------------

  bool _isFunctionDefinitionHeader(
    List<String> lines,
    int currentIndex,
  ) {
    final String line = lines[currentIndex].trim();

    final RegExp functionPattern = RegExp(
      r'^(?:'
      r'(?:struct|union|enum)\s+[A-Za-z_]\w*'
      r'|(?:void|char|short|int|long|float|double|signed|unsigned)'
      r'(?:\s+(?:char|short|int|long|float|double|signed|unsigned))*'
      r')'
      r'\s+\**\s*[A-Za-z_]\w*'
      r'\s*\([^;]*\)\s*\{?\s*$',
    );

    if (!functionPattern.hasMatch(line)) {
      return false;
    }

    if (line.endsWith('{')) {
      return true;
    }

    final String? nextLine = _nextMeaningfulLine(
      lines,
      currentIndex,
    );

    return nextLine == '{';
  }

  String? _nextMeaningfulLine(
    List<String> lines,
    int currentIndex,
  ) {
    for (int index = currentIndex + 1; index < lines.length; index++) {
      final String line = lines[index].trim();

      if (line.isNotEmpty) {
        return line;
      }
    }

    return null;
  }

  String? _previousMeaningfulLine(
    List<String> lines,
    int currentIndex,
  ) {
    for (int index = currentIndex - 1; index >= 0; index--) {
      final String line = lines[index].trim();

      if (line.isNotEmpty) {
        return line;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // Conditional header detection
  // --------------------------------------------------

  bool _isConditionalHeader(String line) {
    final RegExp ifPattern = RegExp(
      r'^if\s*\(.*\)\s*\{?\s*$',
    );

    final RegExp elseIfPattern = RegExp(
      r'^else\s+if\s*\(.*\)\s*\{?\s*$',
    );

    final RegExp elsePattern = RegExp(
      r'^else\s*\{?\s*$',
    );

    final RegExp switchPattern = RegExp(
      r'^switch\s*\(.*\)\s*\{?\s*$',
    );

    return ifPattern.hasMatch(line) ||
        elseIfPattern.hasMatch(line) ||
        elsePattern.hasMatch(line) ||
        switchPattern.hasMatch(line);
  }

  bool _isElseAfterBrace(String line) {
    final RegExp elseAfterBracePattern = RegExp(
      r'^\}\s*else(\s+if\s*\(.*\))?\s*\{?\s*$',
    );

    return elseAfterBracePattern.hasMatch(line);
  }

  // --------------------------------------------------
  // Loop header detection
  // --------------------------------------------------

  bool _isLoopHeader(String line) {
    final RegExp forPattern = RegExp(
      r'^for\s*\(.*\)\s*\{?\s*$',
    );

    final RegExp whilePattern = RegExp(
      r'^while\s*\(.*\)\s*\{?\s*$',
    );

    final RegExp doPattern = RegExp(
      r'^do\s*\{?\s*$',
    );

    return forPattern.hasMatch(line) ||
        whilePattern.hasMatch(line) ||
        doPattern.hasMatch(line);
  }

  bool _isInlineDoWhileEnding(String line) {
    final RegExp inlineDoWhilePattern = RegExp(
      r'^\}\s*while\s*\(.*\)\s*;?\s*$',
    );

    return inlineDoWhilePattern.hasMatch(line);
  }

  bool _isDoWhileEnding(
    List<String> lines,
    int currentIndex,
  ) {
    final String line = lines[currentIndex].trim();

    final RegExp whilePattern = RegExp(
      r'^while\s*\(.*\)\s*;?\s*$',
    );

    if (!whilePattern.hasMatch(line)) {
      return false;
    }

    final String? previousLine = _previousMeaningfulLine(
      lines,
      currentIndex,
    );

    if (previousLine != '}') {
      return false;
    }

    return _hasPreviousDoKeyword(
      lines,
      currentIndex,
    );
  }

  bool _hasPreviousDoKeyword(
    List<String> lines,
    int currentIndex,
  ) {
    for (int index = currentIndex - 1; index >= 0; index--) {
      final String line = lines[index].trim();

      if (RegExp(r'^do\s*\{?\s*$').hasMatch(line)) {
        return true;
      }

      if (RegExp(r'^while\s*\(').hasMatch(line)) {
        return false;
      }

      if (RegExp(r'^for\s*\(').hasMatch(line)) {
        return false;
      }
    }

    return false;
  }

  // --------------------------------------------------
  // Multiline statement detection
  // --------------------------------------------------

  bool _isContinuedLine(String line) {
    return line.endsWith(',') ||
        line.endsWith('(') ||
        line.endsWith('[') ||
        line.endsWith('=') ||
        line.endsWith('+') ||
        line.endsWith('-') ||
        line.endsWith('*') ||
        line.endsWith('/') ||
        line.endsWith('&&') ||
        line.endsWith('||');
  }

  // --------------------------------------------------
  // Extract output from printf()
  // --------------------------------------------------

  String _extractPrintfOutput(String code) {
    final RegExp printfPattern = RegExp(
      r'printf\s*\(\s*"((?:\\.|[^"\\])*)"\s*\)\s*;',
      multiLine: true,
    );

    final Iterable<RegExpMatch> matches = printfPattern.allMatches(code);

    if (matches.isEmpty) {
      return 'Program executed successfully.';
    }

    final StringBuffer output = StringBuffer();

    for (final RegExpMatch match in matches) {
      final String text = match.group(1) ?? '';

      output.write(
        _convertEscapeSequences(text),
      );
    }

    return output.toString();
  }

  String _convertEscapeSequences(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\', '\\');
  }

  CompilerResult? _runRegistryCheckers(
    CompilerContext context,
  ) {
    for (final checker in defaultCheckerRegistry.checkers) {
      final result = checker.checkContext(context);

      if (!result.isSuccess) {
        return result;
      }
    }

    return null;
  }
}
