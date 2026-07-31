import '../../models/compiler_result.dart';

class DoWhileChecker {
  CompilerResult check(String code) {
    final String cleanedCode = _removeCommentsAndStrings(code);
    final RegExp doPattern = RegExp(r'\bdo\b');

    int searchIndex = 0;

    while (searchIndex < cleanedCode.length) {
      final RegExpMatch? relativeMatch =
          doPattern.firstMatch(cleanedCode.substring(searchIndex));

      if (relativeMatch == null) {
        break;
      }

      final int doIndex = searchIndex + relativeMatch.start;
      final int doLine = _lineNumberAt(cleanedCode, doIndex);

      int position = doIndex + 2;
      position = _skipWhitespace(cleanedCode, position);

      if (position >= cleanedCode.length) {
        return _missingWhileResult(doLine);
      }

      /*
       * do ব্লক দুইভাবে লেখা যেতে পারে:
       *
       * do { ... } while (...);
       *
       * অথবা
       *
       * do
       *   statement;
       * while (...);
       */
      if (cleanedCode[position] == '{') {
        final int closingBraceIndex = _findMatchingSymbol(
          text: cleanedCode,
          openingIndex: position,
          openingSymbol: '{',
          closingSymbol: '}',
        );

        if (closingBraceIndex == -1) {
          /*
           * BraceChecker সাধারণত এই ভুল আগে ধরবে।
           * Unit test চলার সময়ও checker যেন crash না করে,
           * তাই নিরাপদে missing while result দেওয়া হচ্ছে।
           */
          return _missingWhileResult(doLine);
        }

        position = closingBraceIndex + 1;
      } else {
        final int statementEnd = cleanedCode.indexOf(';', position);

        if (statementEnd == -1) {
          return _missingWhileResult(doLine);
        }

        position = statementEnd + 1;
      }

      position = _skipWhitespace(cleanedCode, position);

      if (!_hasKeywordAt(cleanedCode, position, 'while')) {
        return _missingWhileResult(doLine);
      }

      final int whileIndex = position;
      final int whileLine = _lineNumberAt(cleanedCode, whileIndex);

      position += 'while'.length;
      position = _skipWhitespace(cleanedCode, position);

      if (position >= cleanedCode.length ||
          cleanedCode[position] != '(') {
        return CompilerResult.failure(
          error: 'Missing opening parenthesis in while statement.',
          explanation:
              'while-এর condition শুরু করার আগে "(" দিতে হবে।',
          errorLine: whileLine,
        );
      }

      final int openingParenthesisIndex = position;

      final int closingParenthesisIndex = _findMatchingSymbol(
        text: cleanedCode,
        openingIndex: openingParenthesisIndex,
        openingSymbol: '(',
        closingSymbol: ')',
      );

      if (closingParenthesisIndex == -1) {
        return CompilerResult.failure(
          error: 'Missing closing parenthesis in while statement.',
          explanation:
              'while-এর condition শেষ করার পরে ")" দিতে হবে।',
          errorLine: whileLine,
        );
      }

      final String condition = cleanedCode
          .substring(
            openingParenthesisIndex + 1,
            closingParenthesisIndex,
          )
          .trim();

      if (condition.isEmpty) {
        return CompilerResult.failure(
          error: 'While condition cannot be empty.',
          explanation:
              'while-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
          errorLine: whileLine,
        );
      }

      if (!_isValidCondition(condition)) {
        return CompilerResult.failure(
          error: 'Invalid while condition.',
          explanation:
              'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
          errorLine: whileLine,
        );
      }

      position = closingParenthesisIndex + 1;
      position = _skipWhitespace(cleanedCode, position);

      if (position >= cleanedCode.length ||
          cleanedCode[position] != ';') {
        return CompilerResult.failure(
          error: 'Missing semicolon after do-while statement.',
          explanation: 'do-while statement শেষে ";" দিতে হবে।',
          errorLine: whileLine,
        );
      }

      searchIndex = position + 1;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All do-while statements are valid.',
    );
  }

  CompilerResult _missingWhileResult(int doLine) {
    return CompilerResult.failure(
      error: 'Missing while statement after do block.',
      explanation: 'do ব্লকের পরে while(condition); লিখতে হবে।',
      errorLine: doLine,
    );
  }

  int _skipWhitespace(String text, int startIndex) {
    int index = startIndex;

    while (index < text.length &&
        RegExp(r'\s').hasMatch(text[index])) {
      index++;
    }

    return index;
  }

  bool _hasKeywordAt(
    String text,
    int index,
    String keyword,
  ) {
    if (index < 0 || index + keyword.length > text.length) {
      return false;
    }

    if (text.substring(index, index + keyword.length) != keyword) {
      return false;
    }

    final String before =
        index > 0 ? text[index - 1] : '';

    final int afterIndex = index + keyword.length;

    final String after =
        afterIndex < text.length ? text[afterIndex] : '';

    final RegExp identifierCharacter = RegExp(r'[A-Za-z0-9_]');

    if (before.isNotEmpty &&
        identifierCharacter.hasMatch(before)) {
      return false;
    }

    if (after.isNotEmpty &&
        identifierCharacter.hasMatch(after)) {
      return false;
    }

    return true;
  }

  int _findMatchingSymbol({
    required String text,
    required int openingIndex,
    required String openingSymbol,
    required String closingSymbol,
  }) {
    int depth = 0;

    for (int index = openingIndex; index < text.length; index++) {
      final String character = text[index];

      if (character == openingSymbol) {
        depth++;
        continue;
      }

      if (character == closingSymbol) {
        depth--;

        if (depth == 0) {
          return index;
        }
      }
    }

    return -1;
  }

  bool _isValidCondition(String condition) {
    final String value = condition.trim();

    if (value.isEmpty) {
      return false;
    }

    if (!_hasBalancedParentheses(value)) {
      return false;
    }

    if (RegExp(r'\(\s*\)').hasMatch(value)) {
      return false;
    }

    if (_startsWithInvalidOperator(value)) {
      return false;
    }

    if (_endsWithOperator(value)) {
      return false;
    }

    if (_containsInvalidOperatorPair(value)) {
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
      r'&&|\|\||!|'
      r'=|\+=|-=|\*=|/=|%='
      r')\s*$',
    ).hasMatch(condition);
  }

  bool _containsInvalidOperatorPair(String condition) {
    final String compact =
        condition.replaceAll(RegExp(r'\s+'), '');

    const Set<String> validPairs = <String>{
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

    const String operators = '+-*/%<>=!&|';

    for (int index = 0; index < compact.length - 1; index++) {
      final String first = compact[index];
      final String second = compact[index + 1];

      if (!operators.contains(first) ||
          !operators.contains(second)) {
        continue;
      }

      final String pair = '$first$second';

      if (!validPairs.contains(pair)) {
        return true;
      }
    }

    return false;
  }

  bool _hasBalancedParentheses(String condition) {
    int depth = 0;

    for (int index = 0; index < condition.length; index++) {
      final String character = condition[index];

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

  int _lineNumberAt(String text, int position) {
    int lineNumber = 1;

    for (int index = 0;
        index < position && index < text.length;
        index++) {
      if (text[index] == '\n') {
        lineNumber++;
      }
    }

    return lineNumber;
  }

  String _removeCommentsAndStrings(String code) {
    final StringBuffer cleaned = StringBuffer();

    bool inLineComment = false;
    bool inBlockComment = false;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < code.length; index++) {
      final String character = code[index];

      final String nextCharacter =
          index + 1 < code.length ? code[index + 1] : '';

      if (inLineComment) {
        if (character == '\n') {
          inLineComment = false;
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        continue;
      }

      if (inBlockComment) {
        if (character == '*' && nextCharacter == '/') {
          cleaned.write(' ');
          cleaned.write(' ');
          inBlockComment = false;
          index++;
        } else if (character == '\n') {
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        continue;
      }

      if (inDoubleQuote || inSingleQuote) {
        if (character == '\n') {
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        if (escaped) {
          escaped = false;
          continue;
        }

        if (character == r'\') {
          escaped = true;
          continue;
        }

        if (inDoubleQuote && character == '"') {
          inDoubleQuote = false;
        } else if (inSingleQuote && character == "'") {
          inSingleQuote = false;
        }

        continue;
      }

      if (character == '/' && nextCharacter == '/') {
        cleaned.write(' ');
        cleaned.write(' ');
        inLineComment = true;
        index++;
        continue;
      }

      if (character == '/' && nextCharacter == '*') {
        cleaned.write(' ');
        cleaned.write(' ');
        inBlockComment = true;
        index++;
        continue;
      }

      if (character == '"') {
        cleaned.write(' ');
        inDoubleQuote = true;
        continue;
      }

      if (character == "'") {
        cleaned.write(' ');
        inSingleQuote = true;
        continue;
      }

      cleaned.write(character);
    }

    return cleaned.toString();
  }
}