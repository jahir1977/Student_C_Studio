import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';

class BraceChecker {
  CompilerResult check(String sourceCode) {
    final openingBraces = <_OpeningBrace>[];

    bool insideDoubleQuote = false;
    bool insideSingleQuote = false;
    bool insideSingleLineComment = false;
    bool insideMultiLineComment = false;
    bool escaped = false;

    int lineNumber = 1;

    for (int i = 0; i < sourceCode.length; i++) {
      final current = sourceCode[i];
      final next = i + 1 < sourceCode.length ? sourceCode[i + 1] : '';

      if (current == '\n') {
        lineNumber++;
        insideSingleLineComment = false;
        escaped = false;
        continue;
      }

      if (insideSingleLineComment) {
        continue;
      }

      if (insideMultiLineComment) {
        if (current == '*' && next == '/') {
          insideMultiLineComment = false;
          i++;
        }

        continue;
      }

      if (insideDoubleQuote) {
        if (escaped) {
          escaped = false;
          continue;
        }

        if (current == r'\') {
          escaped = true;
          continue;
        }

        if (current == '"') {
          insideDoubleQuote = false;
        }

        continue;
      }

      if (insideSingleQuote) {
        if (escaped) {
          escaped = false;
          continue;
        }

        if (current == r'\') {
          escaped = true;
          continue;
        }

        if (current == "'") {
          insideSingleQuote = false;
        }

        continue;
      }

      if (current == '/' && next == '/') {
        insideSingleLineComment = true;
        i++;
        continue;
      }

      if (current == '/' && next == '*') {
        insideMultiLineComment = true;
        i++;
        continue;
      }

      if (current == '"') {
        insideDoubleQuote = true;
        continue;
      }

      if (current == "'") {
        insideSingleQuote = true;
        continue;
      }

      if (current == '{') {
        openingBraces.add(
          _OpeningBrace(
            lineNumber: lineNumber,
            indentation: _lineIndentationAt(
              sourceCode,
              i,
            ),
          ),
        );
        continue;
      }

      if (current == '}') {
        if (openingBraces.isEmpty) {
          final banglaLine = _toBanglaNumber(lineNumber);

          return CompilerResult.failure(
            error: 'Extra closing brace.',
            explanation:
                'লাইন $banglaLine-এ অতিরিক্ত Closing Brace (}) ব্যবহার করা হয়েছে। '
                'এর বিপরীতে কোনো Opening Brace ({) নেই।',
            errorLine: lineNumber,
          );
        }

        final previousStatement = _previousMeaningfulLine(
          sourceCode,
          lineNumber,
        );

        final closingIndentation = _lineIndentationAt(
          sourceCode,
          i,
        );

        if (_isMainReturn(previousStatement) && openingBraces.length > 1) {
          final matchingIndex = openingBraces.lastIndexWhere(
            (brace) => brace.indentation == closingIndentation,
          );

          if (matchingIndex >= 0) {
            openingBraces.removeAt(matchingIndex);
          } else {
            openingBraces.removeLast();
          }
        } else {
          openingBraces.removeLast();
        }
      }
    }

    if (openingBraces.isNotEmpty) {
      final missingBraceLine = openingBraces.last.lineNumber;
      final banglaLine = _toBanglaNumber(missingBraceLine);

      return CompilerResult.failure(
        error: 'Missing closing brace.',
        explanation: 'লাইন $banglaLine-এ ব্যবহৃত Opening Brace ({)-এর বিপরীতে '
            'Closing Brace (}) দেওয়া হয়নি।',
        errorLine: missingBraceLine,
      );
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All braces are balanced.',
    );
  }

  int _lineIndentationAt(
    String sourceCode,
    int characterIndex,
  ) {
    int lineStart = characterIndex;

    while (lineStart > 0 && sourceCode[lineStart - 1] != '\n') {
      lineStart--;
    }

    int indentation = 0;

    while (lineStart + indentation < characterIndex) {
      final character = sourceCode[lineStart + indentation];

      if (character == ' ') {
        indentation++;
        continue;
      }

      if (character == '\t') {
        indentation += 4;
        continue;
      }

      break;
    }

    return indentation;
  }

  String _previousMeaningfulLine(
    String sourceCode,
    int currentLineNumber,
  ) {
    final lines = sourceCode.split('\n');

    int index = currentLineNumber - 2;

    while (index >= 0) {
      final line = lines[index].trim();

      if (line.isNotEmpty) {
        return line;
      }

      index--;
    }

    return '';
  }

  bool _isMainReturn(String line) {
    return RegExp(
      r'^return\s+0\s*;\s*$',
    ).hasMatch(line);
  }

  String _toBanglaNumber(int number) {
    const englishDigits = '0123456789';
    const banglaDigits = '০১২৩৪৫৬৭৮৯';

    return number.toString().split('').map((digit) {
      final index = englishDigits.indexOf(digit);

      if (index == -1) {
        return digit;
      }

      return banglaDigits[index];
    }).join();
  }

  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

class _OpeningBrace {
  final int lineNumber;
  final int indentation;

  const _OpeningBrace({
    required this.lineNumber,
    required this.indentation,
  });
}
