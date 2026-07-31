import '../../models/compiler_result.dart';

class ArrayChecker {
  CompilerResult check(String code) {
    final List<String> sanitizedLines = _sanitizeCode(code);

    for (int index = 0; index < sanitizedLines.length; index++) {
      final String line = sanitizedLines[index];
      final int lineNumber = index + 1;

      final CompilerResult? bracketResult =
          _checkSquareBrackets(
        line,
        lineNumber,
      );

      if (bracketResult != null) {
        return bracketResult;
      }

      final CompilerResult? sizeResult =
          _checkArraySize(
        line,
        lineNumber,
      );

      if (sizeResult != null) {
        return sizeResult;
      }

      final CompilerResult? initializerResult =
          _checkArrayInitializer(
        line,
        lineNumber,
      );

      if (initializerResult != null) {
        return initializerResult;
      }
    }

    return CompilerResult.success(
      output: '',
    );
  }

  CompilerResult? _checkSquareBrackets(
    String line,
    int lineNumber,
  ) {
    int balance = 0;

    for (int index = 0; index < line.length; index++) {
      final String character = line[index];

      if (character == '[') {
        balance++;
      } else if (character == ']') {
        if (balance == 0) {
          return CompilerResult.failure(
            error: "unexpected ']'",
            explanation:
                'অ্যারের সাইজ লেখার আগে খোলা বর্গাকার বন্ধনী [ দিতে হবে।',
            errorLine: lineNumber,
          );
        }

        balance--;
      }
    }

    if (balance > 0) {
      return CompilerResult.failure(
        error: "expected ']'",
        explanation:
            'অ্যারের সাইজ লেখার পর বন্ধ বর্গাকার বন্ধনী ] দিতে হবে।',
        errorLine: lineNumber,
      );
    }

    return null;
  }

  CompilerResult? _checkArraySize(
    String line,
    int lineNumber,
  ) {
    final RegExp declarationPattern = RegExp(
      r'\b(?:int|float|double|char)\s+'
      r'[A-Za-z_][A-Za-z0-9_]*\s*'
      r'\[\s*([^\]]*)\s*\]',
    );

    final Iterable<RegExpMatch> matches =
        declarationPattern.allMatches(line);

    for (final RegExpMatch match in matches) {
      final String sizeText =
          match.group(1)?.trim() ?? '';

      // int numbers[] = {1, 2, 3}; বৈধ।
      if (sizeText.isEmpty) {
        continue;
      }

      if (RegExp(r'^-\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'array size cannot be negative',
          explanation:
              'অ্যারের সাইজ ঋণাত্মক সংখ্যা হতে পারে না।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^\d+\.\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'array size must be an integer',
          explanation:
              'অ্যারের সাইজ হিসেবে পূর্ণসংখ্যা ব্যবহার করতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (sizeText == '0') {
        return CompilerResult.failure(
          error: 'array size must be greater than zero',
          explanation:
              'অ্যারের সাইজ অবশ্যই শূন্যের চেয়ে বড় হতে হবে।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  CompilerResult? _checkArrayInitializer(
    String line,
    int lineNumber,
  ) {
    final RegExp initializerPattern = RegExp(
      r'\b(?:int|float|double|char)\s+'
      r'[A-Za-z_][A-Za-z0-9_]*\s*'
      r'\[\s*([^\]]*)\s*\]\s*'
      r'=\s*\{([^}]*)\}',
    );

    final Iterable<RegExpMatch> matches =
        initializerPattern.allMatches(line);

    for (final RegExpMatch match in matches) {
      final String sizeText =
          match.group(1)?.trim() ?? '';

      final String initializerText =
          match.group(2)?.trim() ?? '';

      if (initializerText.isEmpty) {
        return CompilerResult.failure(
          error: 'array initializer cannot be empty',
          explanation:
              'অ্যারে মান নির্ধারণ করতে হলে অন্তত একটি মান দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      // [] হলে initializer-এর মান থেকে size নির্ধারিত হবে।
      if (sizeText.isEmpty) {
        continue;
      }

      // এই পর্যায়ে কেবল সরাসরি পূর্ণসংখ্যার size তুলনা করা হবে।
      if (!RegExp(r'^\d+$').hasMatch(sizeText)) {
        continue;
      }

      final int declaredSize = int.parse(sizeText);

      final int initializerCount =
          _countInitializerValues(initializerText);

      if (initializerCount > declaredSize) {
        return CompilerResult.failure(
          error: 'too many initializers for array',
          explanation:
              'অ্যারের নির্ধারিত ঘরের তুলনায় বেশি মান দেওয়া হয়েছে।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  int _countInitializerValues(String initializerText) {
    int valueCount = 1;

    int parenthesisDepth = 0;
    int bracketDepth = 0;
    int braceDepth = 0;

    for (
      int index = 0;
      index < initializerText.length;
      index++
    ) {
      final String character = initializerText[index];

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        parenthesisDepth--;
      } else if (character == '[') {
        bracketDepth++;
      } else if (character == ']') {
        bracketDepth--;
      } else if (character == '{') {
        braceDepth++;
      } else if (character == '}') {
        braceDepth--;
      } else if (character == ',' &&
          parenthesisDepth == 0 &&
          bracketDepth == 0 &&
          braceDepth == 0) {
        valueCount++;
      }
    }

    return valueCount;
  }

  List<String> _sanitizeCode(String code) {
    final List<String> sanitizedLines = <String>[];
    final List<String> lines = code.split('\n');

    bool insideBlockComment = false;

    for (final String line in lines) {
      final StringBuffer buffer = StringBuffer();

      bool insideString = false;
      bool insideCharacter = false;
      bool escaped = false;

      int index = 0;

      while (index < line.length) {
        final String character = line[index];

        final String nextCharacter =
            index + 1 < line.length
                ? line[index + 1]
                : '';

        if (insideBlockComment) {
          if (character == '*' &&
              nextCharacter == '/') {
            insideBlockComment = false;
            buffer.write('  ');
            index += 2;
          } else {
            buffer.write(' ');
            index++;
          }

          continue;
        }

        if (insideString) {
          buffer.write(' ');

          if (escaped) {
            escaped = false;
          } else if (character == r'\') {
            escaped = true;
          } else if (character == '"') {
            insideString = false;
          }

          index++;
          continue;
        }

        if (insideCharacter) {
          buffer.write(' ');

          if (escaped) {
            escaped = false;
          } else if (character == r'\') {
            escaped = true;
          } else if (character == "'") {
            insideCharacter = false;
          }

          index++;
          continue;
        }

        if (character == '/' &&
            nextCharacter == '/') {
          while (index < line.length) {
            buffer.write(' ');
            index++;
          }

          break;
        }

        if (character == '/' &&
            nextCharacter == '*') {
          insideBlockComment = true;
          buffer.write('  ');
          index += 2;
          continue;
        }

        if (character == '"') {
          insideString = true;
          buffer.write(' ');
          index++;
          continue;
        }

        if (character == "'") {
          insideCharacter = true;
          buffer.write(' ');
          index++;
          continue;
        }

        buffer.write(character);
        index++;
      }

      sanitizedLines.add(buffer.toString());
    }

    return sanitizedLines;
  }
}