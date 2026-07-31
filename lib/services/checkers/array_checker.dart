import '../../models/compiler_result.dart';

class ArrayChecker {
  CompilerResult check(String code) {
    final sanitizedLines = _sanitizeCode(code);

    for (int index = 0; index < sanitizedLines.length; index++) {
      final line = sanitizedLines[index];
      final lineNumber = index + 1;

      final bracketResult = _checkSquareBrackets(
        line,
        lineNumber,
      );

      if (bracketResult != null) {
        return bracketResult;
      }

      final sizeResult = _checkArraySize(
        line,
        lineNumber,
      );

      if (sizeResult != null) {
        return sizeResult;
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
      final character = line[index];

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
    final declarationPattern = RegExp(
      r'\b(?:int|float|double|char)\s+'
      r'[A-Za-z_][A-Za-z0-9_]*\s*'
      r'\[\s*([^\]]*)\s*\]',
    );

    final matches = declarationPattern.allMatches(line);

    for (final match in matches) {
      final sizeText = match.group(1)?.trim() ?? '';

      // int numbers[] = {1, 2, 3}; is valid.
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

  List<String> _sanitizeCode(String code) {
    final sanitizedLines = <String>[];
    final lines = code.split('\n');

    bool insideBlockComment = false;

    for (final line in lines) {
      final buffer = StringBuffer();

      bool insideString = false;
      bool insideCharacter = false;
      bool escaped = false;

      int index = 0;

      while (index < line.length) {
        final character = line[index];
        final nextCharacter =
            index + 1 < line.length ? line[index + 1] : '';

        if (insideBlockComment) {
          if (character == '*' && nextCharacter == '/') {
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

        if (character == '/' && nextCharacter == '/') {
          while (index < line.length) {
            buffer.write(' ');
            index++;
          }

          break;
        }

        if (character == '/' && nextCharacter == '*') {
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