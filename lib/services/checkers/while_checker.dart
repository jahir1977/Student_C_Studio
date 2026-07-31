import '../../models/compiler_result.dart';

class WhileChecker {
  CompilerResult check(String code) {
    final List<String> lines = code.split('\n');

    bool inBlockComment = false;

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final _CleanLineResult cleanResult = _cleanLine(
        lines[lineIndex],
        inBlockComment,
      );

      inBlockComment = cleanResult.inBlockComment;

      final String line = cleanResult.text.trim();

      if (line.isEmpty) {
        continue;
      }

      if (!RegExp(r'^while\b').hasMatch(line)) {
        continue;
      }

      final int lineNumber = lineIndex + 1;
      final RegExpMatch whileMatch =
          RegExp(r'^while\b').firstMatch(line)!;

      final String afterWhile =
          line.substring(whileMatch.end).trimLeft();

      if (!afterWhile.startsWith('(')) {
        return CompilerResult.failure(
          error: 'Missing opening parenthesis in while statement.',
          explanation:
              'while-এর condition শুরু করার আগে "(" দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      final int openingParenthesisIndex =
          line.indexOf('(', whileMatch.end);

      final _ConditionResult conditionResult = _extractCondition(
        lines: lines,
        startLineIndex: lineIndex,
        cleanedFirstLine: line,
        openingParenthesisIndex: openingParenthesisIndex,
      );

      if (!conditionResult.isComplete) {
        return CompilerResult.failure(
          error: 'Missing closing parenthesis in while statement.',
          explanation:
              'while-এর condition শেষ করার পরে ")" দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      final String condition = conditionResult.condition.trim();

      if (condition.isEmpty) {
        return CompilerResult.failure(
          error: 'While condition cannot be empty.',
          explanation:
              'while-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (!_isValidCondition(condition)) {
        return CompilerResult.failure(
          error: 'Invalid while condition.',
          explanation:
              'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
          errorLine: lineNumber,
        );
      }

      lineIndex = conditionResult.closingLineIndex;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All while statements are valid.',
    );
  }

  _ConditionResult _extractCondition({
    required List<String> lines,
    required int startLineIndex,
    required String cleanedFirstLine,
    required int openingParenthesisIndex,
  }) {
    final StringBuffer condition = StringBuffer();

    int depth = 1;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool inBlockComment = false;
    bool escaped = false;

    for (
      int lineIndex = startLineIndex;
      lineIndex < lines.length;
      lineIndex++
    ) {
      final String currentLine =
          lineIndex == startLineIndex
              ? cleanedFirstLine
              : lines[lineIndex];

      final int startCharacterIndex =
          lineIndex == startLineIndex
              ? openingParenthesisIndex + 1
              : 0;

      bool inLineComment = false;

      for (
        int characterIndex = startCharacterIndex;
        characterIndex < currentLine.length;
        characterIndex++
      ) {
        final String character = currentLine[characterIndex];

        final String nextCharacter =
            characterIndex + 1 < currentLine.length
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

        if ((inDoubleQuote || inSingleQuote) &&
            character == r'\') {
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
              return _ConditionResult(
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

    return _ConditionResult(
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

    if (_containsEmptyParenthesis(value)) {
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

    return true;
  }

  bool _containsEmptyParenthesis(String condition) {
    return RegExp(r'\(\s*\)').hasMatch(condition);
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

      if ((inDoubleQuote || inSingleQuote) &&
          character == r'\') {
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
    final String compact =
        condition.replaceAll(RegExp(r'\s+'), '');

    const Set<String> validOperatorPairs = <String>{
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

      if (validOperatorPairs.contains(pair)) {
        continue;
      }

      return true;
    }

    return false;
  }

  _CleanLineResult _cleanLine(
    String line,
    bool initialBlockCommentState,
  ) {
    final StringBuffer cleaned = StringBuffer();

    bool inBlockComment = initialBlockCommentState;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < line.length; index++) {
      final String character = line[index];

      final String nextCharacter =
          index + 1 < line.length ? line[index + 1] : '';

      if (inBlockComment) {
        if (character == '*' && nextCharacter == '/') {
          inBlockComment = false;
          index++;
        }

        continue;
      }

      if (escaped) {
        if (inDoubleQuote || inSingleQuote) {
          cleaned.write(' ');
        } else {
          cleaned.write(character);
        }

        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) &&
          character == r'\') {
        cleaned.write(' ');
        escaped = true;
        continue;
      }

      if (!inDoubleQuote && !inSingleQuote) {
        if (character == '/' && nextCharacter == '/') {
          break;
        }

        if (character == '/' && nextCharacter == '*') {
          inBlockComment = true;
          index++;
          continue;
        }
      }

      if (!inSingleQuote && character == '"') {
        inDoubleQuote = !inDoubleQuote;
        cleaned.write(' ');
        continue;
      }

      if (!inDoubleQuote && character == "'") {
        inSingleQuote = !inSingleQuote;
        cleaned.write(' ');
        continue;
      }

      if (inDoubleQuote || inSingleQuote) {
        cleaned.write(' ');
        continue;
      }

      cleaned.write(character);
    }

    return _CleanLineResult(
      text: cleaned.toString(),
      inBlockComment: inBlockComment,
    );
  }
}

class _ConditionResult {
  final bool isComplete;
  final String condition;
  final int closingLineIndex;

  const _ConditionResult({
    required this.isComplete,
    required this.condition,
    required this.closingLineIndex,
  });
}

class _CleanLineResult {
  final String text;
  final bool inBlockComment;

  const _CleanLineResult({
    required this.text,
    required this.inBlockComment,
  });
}