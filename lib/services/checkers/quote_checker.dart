import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class QuoteChecker {
  CompilerResult check(String sourceCode) {
    bool insideSingleLineComment = false;
    bool insideMultiLineComment = false;

    int lineNumber = 1;
    int index = 0;

    while (index < sourceCode.length) {
      final current = sourceCode[index];
      final next = index + 1 < sourceCode.length
          ? sourceCode[index + 1]
          : '';

      if (current == '\n') {
        lineNumber++;
        insideSingleLineComment = false;
        index++;
        continue;
      }

      if (insideSingleLineComment) {
        index++;
        continue;
      }

      if (insideMultiLineComment) {
        if (current == '*' && next == '/') {
          insideMultiLineComment = false;
          index += 2;
          continue;
        }

        index++;
        continue;
      }

      if (current == '/' && next == '/') {
        insideSingleLineComment = true;
        index += 2;
        continue;
      }

      if (current == '/' && next == '*') {
        insideMultiLineComment = true;
        index += 2;
        continue;
      }

      if (current == '"') {
        final doubleQuoteResult = _checkDoubleQuotedString(
          sourceCode: sourceCode,
          startIndex: index,
          lineNumber: lineNumber,
        );

        if (doubleQuoteResult.errorResult != null) {
          return doubleQuoteResult.errorResult!;
        }

        index = doubleQuoteResult.nextIndex;
        continue;
      }

      if (current == "'") {
        final lineText = _getCurrentLine(
          sourceCode,
          index,
        );

        final isInputOutputFunction =
            RegExp(r'\b(?:printf|scanf)\s*\(').hasMatch(lineText);

        /*
         * দুটি পরপর Single Quote কখনো Double Quote নয়।
         *
         * printf(''%d'', number);
         * scanf(''%d'', &number);
         */
        if (next == "'" && isInputOutputFunction) {
          final banglaLine = _toBanglaNumber(lineNumber);

          return CompilerResult.failure(
            error: 'Two single quotes cannot replace a double quote.',
            explanation:
                'লাইন $banglaLine-এ দুটি Single Quote (\'\') ব্যবহার করে '
                'Double Quote (") তৈরি করার চেষ্টা করা হয়েছে।\n'
                'দুটি Single Quote (\'\') কখনো একটি Double Quote (") নয়।',
            errorLine: lineNumber,
          );
        }

        final singleQuoteResult = _checkSingleQuotedLiteral(
          sourceCode: sourceCode,
          startIndex: index,
          lineNumber: lineNumber,
          isInputOutputFunction: isInputOutputFunction,
        );

        if (singleQuoteResult.errorResult != null) {
          return singleQuoteResult.errorResult!;
        }

        index = singleQuoteResult.nextIndex;
        continue;
      }

      index++;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All quotes are valid.',
    );
  }

  _QuoteScanResult _checkDoubleQuotedString({
    required String sourceCode,
    required int startIndex,
    required int lineNumber,
  }) {
    bool escaped = false;
    int index = startIndex + 1;

    while (index < sourceCode.length) {
      final current = sourceCode[index];

      if (current == '\n') {
        final banglaLine = _toBanglaNumber(lineNumber);

        return _QuoteScanResult.failure(
          CompilerResult.failure(
            error: 'Missing closing double quote.',
            explanation:
                'লাইন $banglaLine-এ String শুরু করার জন্য Double Quote (") '
                'ব্যবহার করা হয়েছে, কিন্তু String শেষ করার জন্য আরেকটি '
                'Double Quote (") দেওয়া হয়নি।',
            errorLine: lineNumber,
          ),
        );
      }

      if (escaped) {
        escaped = false;
        index++;
        continue;
      }

      if (current == r'\') {
        escaped = true;
        index++;
        continue;
      }

      if (current == '"') {
        return _QuoteScanResult.success(index + 1);
      }

      index++;
    }

    final banglaLine = _toBanglaNumber(lineNumber);

    return _QuoteScanResult.failure(
      CompilerResult.failure(
        error: 'Missing closing double quote.',
        explanation:
            'লাইন $banglaLine-এ String শুরু করার জন্য Double Quote (") '
            'ব্যবহার করা হয়েছে, কিন্তু String শেষ করার জন্য আরেকটি '
            'Double Quote (") দেওয়া হয়নি।',
        errorLine: lineNumber,
      ),
    );
  }

  _QuoteScanResult _checkSingleQuotedLiteral({
    required String sourceCode,
    required int startIndex,
    required int lineNumber,
    required bool isInputOutputFunction,
  }) {
    final content = StringBuffer();

    bool escaped = false;
    bool closingQuoteFound = false;

    int index = startIndex + 1;

    while (index < sourceCode.length) {
      final current = sourceCode[index];

      if (current == '\n') {
        break;
      }

      if (escaped) {
        content.write(r'\');
        content.write(current);
        escaped = false;
        index++;
        continue;
      }

      if (current == r'\') {
        escaped = true;
        index++;
        continue;
      }

      if (current == "'") {
        closingQuoteFound = true;
        break;
      }

      content.write(current);
      index++;
    }

    if (!closingQuoteFound) {
      final banglaLine = _toBanglaNumber(lineNumber);

      return _QuoteScanResult.failure(
        CompilerResult.failure(
          error: 'Missing closing single quote.',
          explanation:
              "লাইন $banglaLine-এ Character শুরু করার জন্য Single Quote (') "
              "ব্যবহার করা হয়েছে, কিন্তু Character শেষ করার জন্য আরেকটি "
              "Single Quote (') দেওয়া হয়নি।",
          errorLine: lineNumber,
        ),
      );
    }

    final literalContent = content.toString();

    if (literalContent.isEmpty) {
      final banglaLine = _toBanglaNumber(lineNumber);

      return _QuoteScanResult.failure(
        CompilerResult.failure(
          error: 'Empty character literal.',
          explanation:
              "লাইন $banglaLine-এ Single Quote (')-এর মধ্যে কোনো Character "
              "লেখা হয়নি।\n"
              "Single Quote (')-এর মধ্যে একটি Character লিখতে হবে।",
          errorLine: lineNumber,
        ),
      );
    }

    final characterCount = _countLogicalCharacters(literalContent);

    if (characterCount > 1 && isInputOutputFunction) {
      final banglaLine = _toBanglaNumber(lineNumber);

      return _QuoteScanResult.failure(
        CompilerResult.failure(
          error: 'String cannot be written with single quotes.',
          explanation:
              "লাইন $banglaLine-এ String লেখার জন্য Single Quote (') "
              "ব্যবহার করা হয়েছে।\n"
              'String অবশ্যই Double Quote (")-এর মধ্যে লিখতে হবে।',
          errorLine: lineNumber,
        ),
      );
    }

    if (characterCount > 1) {
      final banglaLine = _toBanglaNumber(lineNumber);

      return _QuoteScanResult.failure(
        CompilerResult.failure(
          error: 'Character literal contains multiple characters.',
          explanation:
              "লাইন $banglaLine-এ Single Quote (')-এর মধ্যে একাধিক "
              "Character লেখা হয়েছে।\n"
              "Single Quote (')-এর মধ্যে শুধুমাত্র একটি Character লেখা যাবে।",
          errorLine: lineNumber,
        ),
      );
    }

    return _QuoteScanResult.success(index + 1);
  }

  int _countLogicalCharacters(String content) {
    int count = 0;
    int index = 0;

    while (index < content.length) {
      if (content[index] == r'\' && index + 1 < content.length) {
        count++;
        index += 2;
        continue;
      }

      count++;
      index++;
    }

    return count;
  }

  String _getCurrentLine(
    String sourceCode,
    int characterIndex,
  ) {
    int lineStart = characterIndex;
    int lineEnd = characterIndex;

    while (lineStart > 0 && sourceCode[lineStart - 1] != '\n') {
      lineStart--;
    }

    while (lineEnd < sourceCode.length &&
        sourceCode[lineEnd] != '\n') {
      lineEnd++;
    }

    return sourceCode.substring(lineStart, lineEnd);
  }

  String _toBanglaNumber(int number) {
    const englishDigits = '0123456789';
    const banglaDigits = '০১২৩৪৫৬৭৮৯';

    return number.toString().split('').map((digit) {
      final digitIndex = englishDigits.indexOf(digit);

      if (digitIndex == -1) {
        return digit;
      }

      return banglaDigits[digitIndex];
    }).join();
  }
  CompilerResult checkContext(
  CompilerContext context,
) {
  return check(context.sanitizedSource);
}
}

class _QuoteScanResult {
  final int nextIndex;
  final CompilerResult? errorResult;

  const _QuoteScanResult._({
    required this.nextIndex,
    required this.errorResult,
  });

  factory _QuoteScanResult.success(int nextIndex) {
    return _QuoteScanResult._(
      nextIndex: nextIndex,
      errorResult: null,
    );
  }

  factory _QuoteScanResult.failure(
    CompilerResult errorResult,
  ) {
    return _QuoteScanResult._(
      nextIndex: -1,
      errorResult: errorResult,
    );
  }
}