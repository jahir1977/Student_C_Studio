import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class BreakContinueChecker implements CompilerChecker {
  CompilerResult check(String code) {
    final String cleanedCode = _removeCommentsAndStrings(code);

    final Map<int, _BlockType> controlledBlocks =
        _findControlledBlockOpenings(cleanedCode);

    final List<_BlockType?> blockStack = <_BlockType?>[];

    int index = 0;

    while (index < cleanedCode.length) {
      final String character = cleanedCode[index];

      if (character == '{') {
        blockStack.add(controlledBlocks[index]);
        index++;
        continue;
      }

      if (character == '}') {
        if (blockStack.isNotEmpty) {
          blockStack.removeLast();
        }

        index++;
        continue;
      }

      if (_isIdentifierStart(character)) {
        final int wordStart = index;

        index++;

        while (index < cleanedCode.length &&
            _isIdentifierCharacter(cleanedCode[index])) {
          index++;
        }

        final String word = cleanedCode.substring(wordStart, index);

        if (word == 'break') {
          final bool insideLoopOrSwitch = blockStack.any(
            (type) => type == _BlockType.loop || type == _BlockType.switchBlock,
          );

          if (!insideLoopOrSwitch) {
            return CompilerResult.failure(
              error: 'break statement is not inside a loop or switch.',
              explanation:
                  'break শুধুমাত্র loop বা switch-এর ভিতরে ব্যবহার করা যায়।',
              errorLine: _lineNumberAt(cleanedCode, wordStart),
            );
          }
        }

        if (word == 'continue') {
          final bool insideLoop = blockStack.any(
            (type) => type == _BlockType.loop,
          );

          if (!insideLoop) {
            return CompilerResult.failure(
              error: 'continue statement is not inside a loop.',
              explanation: 'continue শুধুমাত্র loop-এর ভিতরে ব্যবহার করা যায়।',
              errorLine: _lineNumberAt(cleanedCode, wordStart),
            );
          }
        }

        continue;
      }

      index++;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All break and continue statements are valid.',
    );
  }

  Map<int, _BlockType> _findControlledBlockOpenings(
    String code,
  ) {
    final Map<int, _BlockType> openings = <int, _BlockType>{};

    int index = 0;

    while (index < code.length) {
      if (!_isIdentifierStart(code[index])) {
        index++;
        continue;
      }

      final int wordStart = index;

      index++;

      while (index < code.length && _isIdentifierCharacter(code[index])) {
        index++;
      }

      final String word = code.substring(wordStart, index);

      if (word == 'do') {
        final int nextIndex = _skipWhitespace(code, index);

        if (nextIndex < code.length && code[nextIndex] == '{') {
          openings[nextIndex] = _BlockType.loop;
        }

        continue;
      }

      if (word != 'for' && word != 'while' && word != 'switch') {
        continue;
      }

      int position = _skipWhitespace(code, index);

      if (position >= code.length || code[position] != '(') {
        continue;
      }

      final int closingParenthesis = _findMatchingParenthesis(code, position);

      if (closingParenthesis == -1) {
        continue;
      }

      position = _skipWhitespace(
        code,
        closingParenthesis + 1,
      );

      if (position >= code.length || code[position] != '{') {
        continue;
      }

      if (word == 'switch') {
        openings[position] = _BlockType.switchBlock;
      } else {
        openings[position] = _BlockType.loop;
      }
    }

    return openings;
  }

  int _findMatchingParenthesis(
    String code,
    int openingIndex,
  ) {
    int depth = 0;

    for (int index = openingIndex; index < code.length; index++) {
      final String character = code[index];

      if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;

        if (depth == 0) {
          return index;
        }
      }
    }

    return -1;
  }

  int _skipWhitespace(String text, int startIndex) {
    int index = startIndex;

    while (index < text.length && RegExp(r'\s').hasMatch(text[index])) {
      index++;
    }

    return index;
  }

  bool _isIdentifierStart(String character) {
    return RegExp(r'[A-Za-z_]').hasMatch(character);
  }

  bool _isIdentifierCharacter(String character) {
    return RegExp(r'[A-Za-z0-9_]').hasMatch(character);
  }

  int _lineNumberAt(String text, int position) {
    int lineNumber = 1;

    for (int index = 0; index < position && index < text.length; index++) {
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

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

enum _BlockType {
  loop,
  switchBlock,
}
