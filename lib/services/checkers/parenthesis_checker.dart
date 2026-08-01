import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class ParenthesisChecker implements CompilerChecker {
  CompilerResult check(String sourceCode) {
    final openingParentheses = <int>[];

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

      if (current == '(') {
        openingParentheses.add(lineNumber);
        continue;
      }

      if (current == ')') {
        if (openingParentheses.isEmpty) {
          final banglaLine = _toBanglaNumber(lineNumber);

          return CompilerResult.failure(
            error: 'Extra closing parenthesis.',
            explanation:
                'লাইন $banglaLine-এ অতিরিক্ত Closing Parenthesis ()) ব্যবহার করা হয়েছে। '
                'এর বিপরীতে কোনো Opening Parenthesis (() নেই।',
            errorLine: lineNumber,
          );
        }

        openingParentheses.removeLast();
      }
    }

    if (openingParentheses.isNotEmpty) {
      final missingParenthesisLine = openingParentheses.last;
      final banglaLine = _toBanglaNumber(missingParenthesisLine);

      return CompilerResult.failure(
        error: 'Missing closing parenthesis.',
        explanation:
            'লাইন $banglaLine-এ ব্যবহৃত Opening Parenthesis (()-এর বিপরীতে '
            'Closing Parenthesis ()) দেওয়া হয়নি।',
        errorLine: missingParenthesisLine,
      );
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All parentheses are balanced.',
    );
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

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}
