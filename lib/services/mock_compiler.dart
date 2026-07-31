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

import 'checkers/do_while_checker.dart';
import 'checkers/break_continue_checker.dart';
import 'checkers/goto_checker.dart';
import 'checkers/array_checker.dart';
import 'checkers/variable_declaration_checker.dart';
import 'checkers/loop_checker.dart';
import 'checkers/if_checker.dart';
import 'checkers/switch_checker.dart';
import 'checkers/while_checker.dart';
import 'checkers/expression_checker.dart';
import 'source_sanitizer.dart';

class MockCompiler {
  const MockCompiler();

  CompilerResult compile(String code) {
    final String source = code;

    if (source.trim().isEmpty) {
  return CompilerResult.failure(
    error: 'No code found.',
    explanation: 'কোনো কোড লেখা হয়নি।',
  );
}

    final String sanitizedSource =
    SourceSanitizer.sanitize(source);

final String codeWithoutComments =
    sanitizedSource;

    // --------------------------------------------------
    // Phase 1: Existing stable compiler pipeline
    // --------------------------------------------------

    final CompilerResult doWhileResult =
        DoWhileChecker().check(codeWithoutComments);

    if (!doWhileResult.isSuccess) {
      return doWhileResult;
    }

    final CompilerResult breakContinueResult =
        BreakContinueChecker().check(
      codeWithoutComments,
    );

    if (!breakContinueResult.isSuccess) {
      return breakContinueResult;
    }

    final CompilerResult gotoResult =
        GotoChecker().check(codeWithoutComments);

    if (!gotoResult.isSuccess) {
      return gotoResult;
    }

    final CompilerResult arrayResult =
        ArrayChecker().check(codeWithoutComments);

    if (!arrayResult.isSuccess) {
      return arrayResult;
    }

    // --------------------------------------------------
    // Phase 5: Statement and declaration checkers
    // --------------------------------------------------

    final int? semicolonErrorLine =
        _findMissingSemicolon(codeWithoutComments);

    if (semicolonErrorLine != null) {
      return CompilerResult.failure(
        error: "expected ';'",
        explanation: '',
        errorLine: semicolonErrorLine,
      );
    }

    final VariableCheckResult variableResult =
        VariableDeclarationChecker.check(
      codeWithoutComments,
    );

    if (!variableResult.isValid) {
      return CompilerResult.failure(
        error: variableResult.error,
        explanation: variableResult.explanation,
        errorLine: variableResult.line,
      );
    }

    final CompilerResult loopResult =
        LoopChecker().check(codeWithoutComments);

    if (!loopResult.isSuccess) {
      return loopResult;
    }

    final CompilerResult ifResult =
        IfChecker().check(codeWithoutComments);

    if (!ifResult.isSuccess) {
      return ifResult;
    }

    final CompilerResult switchResult =
        SwitchChecker().check(codeWithoutComments);

    if (!switchResult.isSuccess) {
      return switchResult;
    }

    final CompilerResult whileResult =
        WhileChecker().check(codeWithoutComments);

    if (!whileResult.isSuccess) {
      return whileResult;
    }

    final CompilerResult expressionResult =
        ExpressionChecker().check(codeWithoutComments);

    if (!expressionResult.isSuccess) {
      return expressionResult;
    }


    // --------------------------------------------------
    // Phase 6: Newly integrated checker pipeline
    //
    // পুরোনো checker-গুলোর error precedence ঠিক রাখার জন্য
    // এই checker-গুলো stable pipeline-এর পরে চালানো হচ্ছে।
    // --------------------------------------------------

    final CompilerResult headerResult =
        HeaderChecker().check(codeWithoutComments);

    if (!headerResult.isSuccess) {
      return headerResult;
    }

    final CompilerResult quoteResult =
        QuoteChecker().check(codeWithoutComments);

    if (!quoteResult.isSuccess) {
      return quoteResult;
    }

    final CompilerResult parenthesisResult =
        ParenthesisChecker().check(codeWithoutComments);

    if (!parenthesisResult.isSuccess) {
      return parenthesisResult;
    }

    final CompilerResult braceResult =
        BraceChecker().check(codeWithoutComments);

    if (!braceResult.isSuccess) {
      return braceResult;
    }

    final CompilerResult functionResult =
        FunctionChecker().check(codeWithoutComments);

    if (!functionResult.isSuccess) {
      return functionResult;
    }

    final CompilerResult? identifierResult =
        IdentifierChecker.check(codeWithoutComments);

    if (identifierResult != null &&
        !identifierResult.isSuccess) {
      return identifierResult;
    }

    final CompilerResult inputOutputResult =
        InputOutputChecker().check(codeWithoutComments);

    if (!inputOutputResult.isSuccess) {
      return inputOutputResult;
    }

    final CompilerResult formatSpecifierResult =
        FormatSpecifierChecker().check(
      codeWithoutComments,
    );

    if (!formatSpecifierResult.isSuccess) {
      return formatSpecifierResult;
    }

    final CompilerResult stringResult =
        StringChecker.check(codeWithoutComments);

    if (!stringResult.isSuccess) {
      return stringResult;
    }

    final CompilerResult pointerResult =
        PointerChecker.check(codeWithoutComments);

    if (!pointerResult.isSuccess) {
      return pointerResult;
    }

    // পুরোনো brace fallback check আপাতত রাখা হয়েছে।
    if (!_hasBalancedBraces(codeWithoutComments)) {
      return CompilerResult.failure(
        error: "expected '}'",
        explanation: '',
      );
    }

    final String output =
        _extractPrintfOutput(codeWithoutComments);

    return CompilerResult.success(
      output: output,
    );
  }

  // --------------------------------------------------
  // main() Function à¦†à¦›à§‡ à¦•à¦¿ à¦¨à¦¾ à¦ªà¦°à§€à¦•à§à¦·à¦¾
  // --------------------------------------------------
// TODO(v0.3 Cleanup):
// Unused helper (Analyzer warning).
// Candidate for removal after regression verification.
/*
  bool _hasMainFunction(String code) {
    final RegExp mainPattern = RegExp(
      r'\b(?:int|void)\s+main\s*\(',
    );

    return mainPattern.hasMatch(code);
  }
*/
  // --------------------------------------------------
  // Semicolon à¦ªà¦°à§€à¦•à§à¦·à¦¾
  //
  // à¦¬à§à¦²à¦•-à¦Ÿà¦¾à¦‡à¦ª à¦Ÿà§à¦°à§à¦¯à¦¾à¦• à¦•à¦°à¦¾à¦° à¦œà¦¨à§à¦¯ à¦à¦•à¦Ÿà¦¿ stack à¦¬à§à¦¯à¦¬à¦¹à¦¾à¦° à¦•à¦°à¦¾ à¦¹à§Ÿà§‡à¦›à§‡:
  //   'struct' -> struct/union à¦¬à§à¦²à¦• -> } à¦à¦° à¦ªà¦° ; à¦²à¦¾à¦—à¦¬à§‡
  //   'enum'   -> enum à¦¬à§à¦²à¦• -> } à¦à¦° à¦ªà¦° ; à¦²à¦¾à¦—à¦¬à§‡
  //   'other'  -> function/if/for/while/do/else à¦¬à§à¦²à¦•
  // --------------------------------------------------

  int? _findMissingSemicolon(String code) {
    final List<String> lines = code.split('\n');
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
            braceTypeStack.isNotEmpty
                ? braceTypeStack.removeLast()
                : null;

        final bool needsSemicolon =
            poppedType == 'struct' ||
            poppedType == 'enum';

        if (needsSemicolon && !line.endsWith(';')) {
          return index + 1;
        }

        continue;
      }

      if (_isLabel(line) ||
          _isCaseOrDefaultLabel(line)) {
        if (line.endsWith('{')) {
          braceTypeStack.add('other');
        }

        continue;
      }

      final String? structHeaderType =
          _matchStructOrEnumHeader(line);

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
          braceTypeStack.isNotEmpty
              ? braceTypeStack.last
              : null;

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

  // --------------------------------------------------
  // Preprocessor directive-à¦à¦° à¦¶à§‡à¦·à§‡ à¦à§à¦² semicolon à¦ªà¦°à§€à¦•à§à¦·à¦¾
  // --------------------------------------------------
/*
  int? _findInvalidPreprocessorDirective(
    String code,
  ) {
    final List<String> lines = code.split('\n');

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index].trim();

      if (!_isPreprocessorLine(line)) {
        continue;
      }

      if (line.endsWith(';')) {
        return index + 1;
      }
    }

    return null;
  }
  */
  // --------------------------------------------------
  // Function header-à¦à¦° à¦ªà¦° à¦à§à¦² semicolon à¦ªà¦°à§€à¦•à§à¦·à¦¾
  // --------------------------------------------------
/*
  int? _findSemicolonBeforeFunctionBody(
    String code,
  ) {
    final List<String> lines = code.split('\n');

    final RegExp headerLikeWithSemicolon = RegExp(
      r'^(?:'
      r'(?:struct|union|enum)\s+[A-Za-z_]\w*'
      r'|(?:void|char|short|int|long|float|double|signed|unsigned)'
      r'(?:\s+(?:char|short|int|long|float|double|signed|unsigned))*'
      r')'
      r'\s+\**\s*[A-Za-z_]\w*\s*\([^;{}]*\)\s*;\s*$',
    );

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index].trim();

      if (line.isEmpty ||
          _isPreprocessorLine(line)) {
        continue;
      }

      if (!headerLikeWithSemicolon.hasMatch(line)) {
        continue;
      }

      final String? nextLine =
          _nextMeaningfulLine(lines, index);

      if (nextLine == '{') {
        return index + 1;
      }
    }

    return null;
  }
  */
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

    return casePattern.hasMatch(line) ||
        defaultPattern.hasMatch(line);
  }

  // --------------------------------------------------
  // struct / union / enum à¦¬à§à¦²à¦• à¦¹à§‡à¦¡à¦¾à¦° à¦ªà¦°à§€à¦•à§à¦·à¦¾
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
  // Function Header à¦ªà¦°à§€à¦•à§à¦·à¦¾
  // --------------------------------------------------

  bool _isFunctionDefinitionHeader(
    List<String> lines,
    int currentIndex,
  ) {
    final String line =
        lines[currentIndex].trim();

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

    final String? nextLine =
        _nextMeaningfulLine(
      lines,
      currentIndex,
    );

    return nextLine == '{';
  }

  String? _nextMeaningfulLine(
    List<String> lines,
    int currentIndex,
  ) {
    for (
      int index = currentIndex + 1;
      index < lines.length;
      index++
    ) {
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
    for (
      int index = currentIndex - 1;
      index >= 0;
      index--
    ) {
      final String line = lines[index].trim();

      if (line.isNotEmpty) {
        return line;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // Condition à¦ªà¦°à§€à¦•à§à¦·à¦¾
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
  // Loop à¦ªà¦°à§€à¦•à§à¦·à¦¾
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
    final String line =
        lines[currentIndex].trim();

    final RegExp whilePattern = RegExp(
      r'^while\s*\(.*\)\s*;?\s*$',
    );

    if (!whilePattern.hasMatch(line)) {
      return false;
    }

    final String? previousLine =
        _previousMeaningfulLine(
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
    for (
      int index = currentIndex - 1;
      index >= 0;
      index--
    ) {
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
  // Multiline Statement à¦ªà¦°à§€à¦•à§à¦·à¦¾
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
  // Brace à¦ªà¦°à§€à¦•à§à¦·à¦¾
  // --------------------------------------------------

  bool _hasBalancedBraces(String code) {
    int balance = 0;

    bool insideString = false;
    bool insideCharacter = false;
    bool escaped = false;

    for (int index = 0; index < code.length; index++) {
      final String character = code[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (character == r'\') {
        escaped = true;
        continue;
      }

      if (character == '"' && !insideCharacter) {
        insideString = !insideString;
        continue;
      }

      if (character == "'" && !insideString) {
        insideCharacter = !insideCharacter;
        continue;
      }

      if (insideString || insideCharacter) {
        continue;
      }

      if (character == '{') {
        balance++;
      } else if (character == '}') {
        balance--;

        if (balance < 0) {
          return false;
        }
      }
    }

    return balance == 0;
  }

  // --------------------------------------------------
  // printf() à¦¥à§‡à¦•à§‡ Output à¦¬à§‡à¦° à¦•à¦°à¦¾
  // --------------------------------------------------

  String _extractPrintfOutput(String code) {
    final RegExp printfPattern = RegExp(
      r'printf\s*\(\s*"((?:\\.|[^"\\])*)"\s*\)\s*;',
      multiLine: true,
    );

    final Iterable<RegExpMatch> matches =
        printfPattern.allMatches(code);

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
  }