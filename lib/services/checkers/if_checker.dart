import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class IfChecker implements CompilerChecker {
  CompilerResult check(String code) {
    final List<String> lines = code.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final String trimmedLine = lines[lineIndex].trim();

      if (trimmedLine.isEmpty) {
        continue;
      }

      final _IfType? ifType = _detectIfType(trimmedLine);

      if (ifType == null) {
        continue;
      }

      final int errorLine = lineIndex + 1;

      final int keywordEndIndex = ifType == _IfType.elseIf
          ? _findElseIfKeywordEnd(trimmedLine)
          : _findIfKeywordEnd(trimmedLine);

      final String textAfterKeyword =
          trimmedLine.substring(keywordEndIndex).trimLeft();

      if (!textAfterKeyword.startsWith('(')) {
        return CompilerResult.failure(
          error: ifType == _IfType.elseIf
              ? 'Missing opening parenthesis in else-if statement.'
              : 'Missing opening parenthesis in if statement.',
          explanation: ifType == _IfType.elseIf
              ? 'else if-এর condition শুরু করার আগে "(" দিতে হবে।'
              : 'if-এর condition শুরু করার আগে "(" দিতে হবে।',
          errorLine: errorLine,
        );
      }

      final int openingParenthesisIndex =
          trimmedLine.indexOf('(', keywordEndIndex);

      final _ConditionExtractionResult extractionResult = _extractCondition(
        lines: lines,
        startLineIndex: lineIndex,
        firstLine: trimmedLine,
        openingParenthesisIndex: openingParenthesisIndex,
      );

      if (!extractionResult.isComplete) {
        return CompilerResult.failure(
          error: ifType == _IfType.elseIf
              ? 'Missing closing parenthesis in else-if statement.'
              : 'Missing closing parenthesis in if statement.',
          explanation: ifType == _IfType.elseIf
              ? 'else if-এর condition শেষ করার পরে ")" দিতে হবে।'
              : 'if-এর condition শেষ করার পরে ")" দিতে হবে।',
          errorLine: errorLine,
        );
      }

      final String condition = extractionResult.condition.trim();

      if (condition.isEmpty) {
        return CompilerResult.failure(
          error: ifType == _IfType.elseIf
              ? 'Else-if condition cannot be empty.'
              : 'If condition cannot be empty.',
          explanation: ifType == _IfType.elseIf
              ? 'else if-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।'
              : 'if-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
          errorLine: errorLine,
        );
      }

      if (!_isValidCondition(condition)) {
        return CompilerResult.failure(
          error: ifType == _IfType.elseIf
              ? 'Invalid else-if condition.'
              : 'Invalid if condition.',
          explanation: ifType == _IfType.elseIf
              ? 'else if-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।'
              : 'if-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
          errorLine: errorLine,
        );
      }

      lineIndex = extractionResult.closingLineIndex;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All if statements are valid.',
    );
  }

  _IfType? _detectIfType(String line) {
    if (RegExp(r'^else\s+if\b').hasMatch(line)) {
      return _IfType.elseIf;
    }

    if (RegExp(r'^if\b').hasMatch(line)) {
      return _IfType.ifStatement;
    }

    return null;
  }

  int _findIfKeywordEnd(String line) {
    final RegExpMatch? match = RegExp(r'^if\b').firstMatch(line);

    return match?.end ?? 0;
  }

  int _findElseIfKeywordEnd(String line) {
    final RegExpMatch? match = RegExp(r'^else\s+if\b').firstMatch(line);

    return match?.end ?? 0;
  }

  _ConditionExtractionResult _extractCondition({
    required List<String> lines,
    required int startLineIndex,
    required String firstLine,
    required int openingParenthesisIndex,
  }) {
    final StringBuffer condition = StringBuffer();

    int depth = 1;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool inBlockComment = false;
    bool escaped = false;

    for (int lineIndex = startLineIndex;
        lineIndex < lines.length;
        lineIndex++) {
      final String currentLine =
          lineIndex == startLineIndex ? firstLine : lines[lineIndex];

      final int startCharacterIndex =
          lineIndex == startLineIndex ? openingParenthesisIndex + 1 : 0;

      bool inLineComment = false;

      for (int characterIndex = startCharacterIndex;
          characterIndex < currentLine.length;
          characterIndex++) {
        final String character = currentLine[characterIndex];

        final String nextCharacter = characterIndex + 1 < currentLine.length
            ? currentLine[characterIndex + 1]
            : '';

        if (inLineComment) {
          break;
        }

        if (inBlockComment) {
          if (character == '*' && nextCharacter == '/') {
            inBlockComment = false;
            characterIndex++;
          }

          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '/' && nextCharacter == '/') {
            inLineComment = true;
            break;
          }

          if (character == '/' && nextCharacter == '*') {
            inBlockComment = true;
            characterIndex++;
            continue;
          }
        }

        if (escaped) {
          condition.write(character);
          escaped = false;
          continue;
        }

        if ((inDoubleQuote || inSingleQuote) && character == r'\') {
          condition.write(character);
          escaped = true;
          continue;
        }

        if (!inSingleQuote && character == '"') {
          inDoubleQuote = !inDoubleQuote;
          condition.write(character);
          continue;
        }

        if (!inDoubleQuote && character == "'") {
          inSingleQuote = !inSingleQuote;
          condition.write(character);
          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '(') {
            depth++;
            condition.write(character);
            continue;
          }

          if (character == ')') {
            depth--;

            if (depth == 0) {
              return _ConditionExtractionResult(
                isComplete: true,
                condition: condition.toString(),
                closingLineIndex: lineIndex,
              );
            }

            condition.write(character);
            continue;
          }
        }

        condition.write(character);
      }

      if (lineIndex < lines.length - 1) {
        condition.write('\n');
      }
    }

    return _ConditionExtractionResult(
      isComplete: false,
      condition: condition.toString(),
      closingLineIndex: startLineIndex,
    );
  }

  bool _isValidCondition(String condition) {
    final String value = condition.trim();

    if (value.isEmpty) {
      return false;
    }

    if (!_hasBalancedNestedParentheses(value)) {
      return false;
    }

    if (_startsWithInvalidOperator(value)) {
      return false;
    }

    if (_endsWithOperator(value)) {
      return false;
    }

    if (_containsInvalidConsecutiveOperators(value)) {
      return false;
    }

    if (_containsEmptyParenthesis(value)) {
      return false;
    }

    return true;
  }

  bool _startsWithInvalidOperator(String condition) {
    return RegExp(
      r'^(?:'
      r'\*|/|%|'
      r'<|>|<=|>=|==|!=|'
      r'&&|\|\||'
      r'=|\+=|-=|\*=|/=|%='
      r')',
    ).hasMatch(condition);
  }

  bool _endsWithOperator(String condition) {
    return RegExp(
      r'(?:'
      r'\+|-|\*|/|%|'
      r'<|>|<=|>=|==|!=|'
      r'&&|\|\||'
      r'=|\+=|-=|\*=|/=|%='
      r')\s*$',
    ).hasMatch(condition);
  }

  bool _containsEmptyParenthesis(String condition) {
    return RegExp(r'\(\s*\)').hasMatch(condition);
  }

  bool _hasBalancedNestedParentheses(String condition) {
    int depth = 0;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < condition.length; index++) {
      final String character = condition[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!inSingleQuote && character == '"') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (!inDoubleQuote && character == "'") {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (inDoubleQuote || inSingleQuote) {
        continue;
      }

      if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;

        if (depth < 0) {
          return false;
        }
      }
    }

    return depth == 0;
  }

  bool _containsInvalidConsecutiveOperators(String condition) {
    final String compact = condition.replaceAll(RegExp(r'\s+'), '');

    const Set<String> validOperators = <String>{
      '++',
      '--',
      '<=',
      '>=',
      '==',
      '!=',
      '&&',
      '||',
      '+=',
      '-=',
      '*=',
      '/=',
      '%=',
    };

    const String operatorCharacters = '+-*/%<>=!&|';

    for (int index = 0; index < compact.length - 1; index++) {
      final String first = compact[index];
      final String second = compact[index + 1];

      if (!operatorCharacters.contains(first) ||
          !operatorCharacters.contains(second)) {
        continue;
      }

      final String pair = '$first$second';

      if (validOperators.contains(pair)) {
        continue;
      }

      return true;
    }

    return false;
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

enum _IfType {
  ifStatement,
  elseIf,
}

class _ConditionExtractionResult {
  final bool isComplete;
  final String condition;
  final int closingLineIndex;

  const _ConditionExtractionResult({
    required this.isComplete,
    required this.condition,
    required this.closingLineIndex,
  });
}
