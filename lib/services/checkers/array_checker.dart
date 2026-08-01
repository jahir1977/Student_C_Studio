import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class ArrayChecker implements CompilerChecker {
  CompilerResult check(String code) {
    final List<String> sanitizedLines = _sanitizeCode(code);

    final Map<String, int?> declaredArrays =
        _collectDeclaredArrays(sanitizedLines);

    for (int index = 0; index < sanitizedLines.length; index++) {
      final String line = sanitizedLines[index];
      final int lineNumber = index + 1;

      final CompilerResult? bracketResult = _checkSquareBrackets(
        line,
        lineNumber,
      );

      if (bracketResult != null) {
        return bracketResult;
      }

      final CompilerResult? sizeResult = _checkArraySize(
        line,
        lineNumber,
      );

      if (sizeResult != null) {
        return sizeResult;
      }

      final CompilerResult? initializerResult = _checkArrayInitializer(
        line,
        lineNumber,
      );

      if (initializerResult != null) {
        return initializerResult;
      }

      final CompilerResult? indexResult = _checkArrayIndex(
        line,
        lineNumber,
        declaredArrays.keys.toSet(),
      );

      if (indexResult != null) {
        return indexResult;
      }

      final CompilerResult? boundsResult = _checkArrayBounds(
        line,
        lineNumber,
        declaredArrays,
      );

      if (boundsResult != null) {
        return boundsResult;
      }

      final CompilerResult? assignmentResult = _checkWholeArrayAssignment(
        line,
        lineNumber,
        declaredArrays.keys.toSet(),
      );

      if (assignmentResult != null) {
        return assignmentResult;
      }
    }

    return CompilerResult.success(
      output: '',
    );
  }

  Map<String, int?> _collectDeclaredArrays(
    List<String> lines,
  ) {
    final Map<String, int?> declaredArrays = <String, int?>{};

    final RegExp declarationPattern = RegExp(
      r'\b(?:int|float|double|char)\s+'
      r'([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'\[\s*([^\]]*)\s*\]'
      r'(?:\s*=\s*\{([^}]*)\})?',
    );

    for (final String line in lines) {
      final Iterable<RegExpMatch> matches = declarationPattern.allMatches(line);

      for (final RegExpMatch match in matches) {
        final String arrayName = match.group(1)?.trim() ?? '';

        final String sizeText = match.group(2)?.trim() ?? '';

        final String initializerText = match.group(3)?.trim() ?? '';

        if (arrayName.isEmpty) {
          continue;
        }

        if (RegExp(r'^\d+$').hasMatch(sizeText)) {
          declaredArrays[arrayName] = int.parse(sizeText);

          continue;
        }

        if (sizeText.isEmpty && initializerText.isNotEmpty) {
          declaredArrays[arrayName] = _countInitializerValues(
            initializerText,
          );

          continue;
        }

        // Variable বা expression দিয়ে size দেওয়া হলে
        // compile-time bounds নির্ধারণ করা হবে না।
        declaredArrays[arrayName] = null;
      }
    }

    return declaredArrays;
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
        explanation: 'অ্যারের সাইজ লেখার পর বন্ধ বর্গাকার বন্ধনী ] দিতে হবে।',
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

    final Iterable<RegExpMatch> matches = declarationPattern.allMatches(line);

    for (final RegExpMatch match in matches) {
      final String sizeText = match.group(1)?.trim() ?? '';

      // int numbers[] = {1, 2, 3}; বৈধ।
      if (sizeText.isEmpty) {
        continue;
      }

      if (RegExp(r'^-\s*\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'array size cannot be negative',
          explanation: 'অ্যারের সাইজ ঋণাত্মক সংখ্যা হতে পারে না।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^\d+\.\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'array size must be an integer',
          explanation: 'অ্যারের সাইজ হিসেবে পূর্ণসংখ্যা ব্যবহার করতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (sizeText == '0') {
        return CompilerResult.failure(
          error: 'array size must be greater than zero',
          explanation: 'অ্যারের সাইজ অবশ্যই শূন্যের চেয়ে বড় হতে হবে।',
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

    final Iterable<RegExpMatch> matches = initializerPattern.allMatches(line);

    for (final RegExpMatch match in matches) {
      final String sizeText = match.group(1)?.trim() ?? '';

      final String initializerText = match.group(2)?.trim() ?? '';

      if (initializerText.isEmpty) {
        return CompilerResult.failure(
          error: 'array initializer cannot be empty',
          explanation: 'অ্যারে মান নির্ধারণ করতে হলে অন্তত একটি মান দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      // [] হলে initializer-এর মান থেকে size নির্ধারিত হবে।
      if (sizeText.isEmpty) {
        continue;
      }

      // কেবল সরাসরি পূর্ণসংখ্যার size তুলনা করা হবে।
      if (!RegExp(r'^\d+$').hasMatch(sizeText)) {
        continue;
      }

      final int declaredSize = int.parse(sizeText);

      final int initializerCount = _countInitializerValues(
        initializerText,
      );

      if (initializerCount > declaredSize) {
        return CompilerResult.failure(
          error: 'too many initializers for array',
          explanation: 'অ্যারের নির্ধারিত ঘরের তুলনায় বেশি মান দেওয়া হয়েছে।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  CompilerResult? _checkArrayIndex(
    String line,
    int lineNumber,
    Set<String> declaredArrayNames,
  ) {
    final RegExp indexPattern = RegExp(
      r'\b([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'\[\s*([^\]]*)\s*\]',
    );

    final Iterable<RegExpMatch> matches = indexPattern.allMatches(line);

    for (final RegExpMatch match in matches) {
      final String arrayName = match.group(1)?.trim() ?? '';

      final String indexText = match.group(2)?.trim() ?? '';

      if (!declaredArrayNames.contains(arrayName)) {
        continue;
      }

      if (_isArrayDeclarationMatch(
        line,
        match.start,
      )) {
        continue;
      }

      if (indexText.isEmpty) {
        return CompilerResult.failure(
          error: 'array index cannot be empty',
          explanation:
              'অ্যারে কোনো মান ব্যবহার বা পরিবর্তন করতে হলে ইনডেক্স দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^-\s*\d+$').hasMatch(indexText)) {
        return CompilerResult.failure(
          error: 'array index cannot be negative',
          explanation: 'অ্যারের ইনডেক্স ঋণাত্মক সংখ্যা হতে পারে না।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^\d+\.\d+$').hasMatch(indexText)) {
        return CompilerResult.failure(
          error: 'array index must be an integer',
          explanation:
              'অ্যারের ইনডেক্স হিসেবে পূর্ণসংখ্যা বা পূর্ণসংখ্যার এক্সপ্রেশন ব্যবহার করতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (indexText.contains(',')) {
        return CompilerResult.failure(
          error: 'invalid array index',
          explanation:
              'একটি অ্যারের ইনডেক্সের মধ্যে কমা দিয়ে একাধিক মান লেখা যাবে না।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  CompilerResult? _checkArrayBounds(
    String line,
    int lineNumber,
    Map<String, int?> declaredArrays,
  ) {
    final RegExp pattern = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*)\[(\d+)\]',
    );

    for (final RegExpMatch match in pattern.allMatches(line)) {
      final String arrayName = match.group(1)!;

      if (!declaredArrays.containsKey(arrayName)) {
        continue;
      }

      // declaration line skip
      if (_isArrayDeclarationMatch(line, match.start)) {
        continue;
      }

      final int? size = declaredArrays[arrayName];

      if (size == null) {
        continue;
      }

      final int index = int.parse(match.group(2)!);

      if (index >= size) {
        return CompilerResult.failure(
          error: 'array index out of bounds',
          explanation:
              'অ্যারের ইনডেক্স অবশ্যই ০ থেকে ${_toBanglaNumber(size - 1)} এর মধ্যে হতে হবে।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  bool _isArrayDeclarationMatch(
    String line,
    int arrayNameStart,
  ) {
    final String textBeforeArrayName = line.substring(
      0,
      arrayNameStart,
    );

    return RegExp(
      r'\b(?:int|float|double|char)\s*$',
    ).hasMatch(textBeforeArrayName);
  }

  CompilerResult? _checkWholeArrayAssignment(
    String line,
    int lineNumber,
    Set<String> declaredArrayNames,
  ) {
    final RegExp assignmentPattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'=\s*([^;]+)\s*;\s*$',
    );

    final RegExpMatch? match = assignmentPattern.firstMatch(line);

    if (match == null) {
      return null;
    }

    final String leftName = match.group(1)?.trim() ?? '';

    final String rightText = match.group(2)?.trim() ?? '';

    if (!declaredArrayNames.contains(leftName)) {
      return null;
    }

    final bool rightSideIsSingleIdentifier = RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*$',
    ).hasMatch(rightText);

    if (rightSideIsSingleIdentifier && declaredArrayNames.contains(rightText)) {
      return CompilerResult.failure(
        error: 'cannot assign one array to another',
        explanation:
            'একটি সম্পূর্ণ অ্যারেকে সরাসরি অন্য অ্যারেতে অ্যাসাইন করা যায় না।',
        errorLine: lineNumber,
      );
    }

    return CompilerResult.failure(
      error: 'cannot assign value to entire array',
      explanation:
          'সম্পূর্ণ অ্যারেতে সরাসরি একটি মান রাখা যায় না। নির্দিষ্ট ঘরে মান রাখতে ইনডেক্স ব্যবহার করতে হবে।',
      errorLine: lineNumber,
    );
  }

  int _countInitializerValues(
    String initializerText,
  ) {
    int valueCount = 1;

    int parenthesisDepth = 0;
    int bracketDepth = 0;
    int braceDepth = 0;

    for (int index = 0; index < initializerText.length; index++) {
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

  String _toBanglaNumber(int number) {
    const english = '0123456789';
    const bangla = '০১২৩৪৫৬৭৮৯';

    return number
        .toString()
        .split('')
        .map((digit) => bangla[english.indexOf(digit)])
        .join();
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

      sanitizedLines.add(
        buffer.toString(),
      );
    }

    return sanitizedLines;
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}
