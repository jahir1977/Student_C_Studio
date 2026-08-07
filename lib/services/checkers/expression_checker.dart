import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class ExpressionChecker implements CompilerChecker {
  @override
  CompilerResult check(String sourceCode) {
    final ternaryResult = _checkTernaryOperators(sourceCode);

    if (!ternaryResult.isSuccess) {
      return ternaryResult;
    }

    final lines = sourceCode.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i].trim();

      if (rawLine.isEmpty) continue;

      final line = _maskQuotedLiterals(rawLine);

      // ১. কমেন্ট ও প্রি-প্রসেসর (#include) এড়িয়ে যাওয়া
      if (rawLine.startsWith('//') || rawLine.startsWith('#')) continue;

      // ২. ইনক্রিমেন্ট/ডিক্রিমেন্ট (যেমন: i++; বা ++i;) এড়িয়ে যাওয়া
      if (RegExp(r'(\+\+|--)\s*;?$').hasMatch(line)) continue;

      // ৩. ExpressionChecker কেবল সেই লাইনগুলোই চেক করবে যেগুলোতে অ্যাসাইনমেন্ট (=) আছে।
      // (তবে ==, <=, >=, != এর মতো শর্তযুক্ত সমতাকে অ্যাসাইনমেন্ট হিসেবে ধরবে না)
      final hasAssignment = RegExp(r'(?<![=!<>])=(?![=])').hasMatch(line);

      // যদি অ্যাসাইনমেন্ট না থাকে (যেমন: while (i <= n); বা return 0;), তবে এটি স্কিপ করবে
      if (!hasAssignment) continue;

      final emptyRightSideMatch = RegExp(r'=\s*;$').firstMatch(line);

      if (emptyRightSideMatch != null) {
        return CompilerResult.failure(
          error: "Expression expected after '='.",
          explanation: "সমান চিহ্নের পরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন লিখতে হবে।",
          errorLine: i + 1,
        );
      }

      final endingOperatorMatch = RegExp(r'([+\-*/%])\s*;$').firstMatch(line);

      if (endingOperatorMatch != null) {
        final operator = endingOperatorMatch.group(1)!;

        return CompilerResult.failure(
          error: "Expression is incomplete after operator '$operator'.",
          explanation: "অপারেটরের পরে একটি মান বা ভেরিয়েবল থাকা প্রয়োজন।",
          errorLine: i + 1,
        );
      }

      final startingOperatorMatch = RegExp(r'=\s*([+*/%])').firstMatch(line);

      if (startingOperatorMatch != null) {
        final operator = startingOperatorMatch.group(1)!;

        return CompilerResult.failure(
          error: "Expression cannot start with operator '$operator'.",
          explanation: "অ্যাসাইনমেন্ট চিহ্নের পরে সরাসরি অপারেটর ব্যবহার করা যাবে না।",
          errorLine: i + 1,
        );
      }

      final invalidConsecutiveOperators =
          _findInvalidConsecutiveOperators(line);

      if (invalidConsecutiveOperators != null) {
        final firstOperator = invalidConsecutiveOperators.$1;
        final secondOperator = invalidConsecutiveOperators.$2;

        return CompilerResult.failure(
          error: "Two operators cannot appear consecutively: "
              "'$firstOperator' and '$secondOperator'.",
          explanation: "দুটি গাণিতিক অপারেটর পাশাপাশি ব্যবহার করা যাবে না।",
          errorLine: i + 1,
        );
      }

      final operatorBeforeClosingParenthesis =
          _findOperatorBeforeClosingParenthesis(line);

      if (operatorBeforeClosingParenthesis != null) {
        return CompilerResult.failure(
          error: "Expression is incomplete before closing parenthesis.",
          explanation: "সমাপনী বন্ধনীর আগে অপারেটরের পরে একটি মান বা ভেরিয়েবল থাকতে হবে।",
          errorLine: i + 1,
        );
      }

      final operatorAfterOpeningParenthesisMatch =
          RegExp(r'\(\s*([+*/%])').firstMatch(line);

      if (operatorAfterOpeningParenthesisMatch != null) {
        return CompilerResult.failure(
          error: "Expression cannot start with operator after '('.",
          explanation: "খোলা বন্ধনীর পরে সরাসরি অপারেটর ব্যবহার করা যাবে না।",
          errorLine: i + 1,
        );
      }

      final emptyParenthesisMatch = RegExp(r'=\s*\(\s*\)\s*;').firstMatch(line);

      if (emptyParenthesisMatch != null) {
        return CompilerResult.failure(
          error: "Empty parenthesis is not allowed.",
          explanation: "খালি বন্ধনীর ভেতরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন থাকতে হবে।",
          errorLine: i + 1,
        );
      }

      if (line.contains('=')) {
        final rightSide = line.split('=').skip(1).join('=');

        final missingOperatorMatch = RegExp(
          r'\b(?:\d+|[A-Za-z_]\w*)\s+(?:\d+|[A-Za-z_]\w*)\b',
        ).firstMatch(rightSide);

        if (missingOperatorMatch != null) {
          return CompilerResult.failure(
            error: "Operator expected between operands.",
            explanation: "দুইটি মান বা ভেরিয়েবলের মাঝে একটি অপারেটর থাকতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      final openingParenthesisCount = '('.allMatches(line).length;
      final closingParenthesisCount = ')'.allMatches(line).length;

      if (openingParenthesisCount > closingParenthesisCount) {
        return CompilerResult.failure(
          error: "Missing closing parenthesis ')'.",
          explanation: "খোলা বন্ধনীর জন্য একটি সমাপনী বন্ধনী ')' দিতে হবে।",
          errorLine: i + 1,
        );
      }

      if (closingParenthesisCount > openingParenthesisCount) {
        return CompilerResult.failure(
          error: "Extra closing parenthesis ')'.",
          explanation: "এই সমাপনী বন্ধনী ')' এর জন্য কোনো খোলা বন্ধনী নেই। ",
          errorLine: i + 1,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Expression is valid.',
    );
  }

  String _maskQuotedLiterals(String line) {
    final StringBuffer masked = StringBuffer();

    bool insideDoubleQuote = false;
    bool insideSingleQuote = false;
    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      final String character = line[i];

      if (escaped) {
        masked.write('a');
        escaped = false;
        continue;
      }

      if ((insideDoubleQuote || insideSingleQuote) && character == r'\') {
        masked.write('a');
        escaped = true;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        masked.write('"');
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        masked.write("'");
        continue;
      }

      if (insideDoubleQuote || insideSingleQuote) {
        masked.write('a');
      } else {
        masked.write(character);
      }
    }

    return masked.toString();
  }

  CompilerResult _checkTernaryOperators(String sourceCode) {
    final lines = sourceCode.split('\n');
    final questionStack = <_TernaryQuestion>[];

    bool insideBlockComment = false;

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      bool insideDoubleQuote = false;
      bool insideSingleQuote = false;
      bool escaped = false;

      for (int charIndex = 0; charIndex < line.length; charIndex++) {
        final character = line[charIndex];
        final nextCharacter =
            charIndex + 1 < line.length ? line[charIndex + 1] : '';

        if (insideBlockComment) {
          if (character == '*' && nextCharacter == '/') {
            insideBlockComment = false;
            charIndex++;
          }
          continue;
        }

        if (!insideDoubleQuote &&
            !insideSingleQuote &&
            character == '/' &&
            nextCharacter == '*') {
          insideBlockComment = true;
          charIndex++;
          continue;
        }

        if (!insideDoubleQuote &&
            !insideSingleQuote &&
            character == '/' &&
            nextCharacter == '/') {
          break;
        }

        if (escaped) {
          escaped = false;
          continue;
        }

        if ((insideDoubleQuote || insideSingleQuote) && character == r'\') {
          escaped = true;
          continue;
        }

        if (!insideSingleQuote && character == '"') {
          insideDoubleQuote = !insideDoubleQuote;
          continue;
        }

        if (!insideDoubleQuote && character == "'") {
          insideSingleQuote = !insideSingleQuote;
          continue;
        }

        if (insideDoubleQuote || insideSingleQuote) {
          continue;
        }

        if (character == '?') {
          questionStack.add(
            _TernaryQuestion(
              lineNumber: lineIndex + 1,
              lineIndex: lineIndex,
              charIndex: charIndex,
            ),
          );
          continue;
        }

        if (character == ':') {
          if (questionStack.isEmpty) {
            final trimmedLine = line.trimLeft();

            final isSwitchLabel = trimmedLine.startsWith('case ') ||
                trimmedLine.startsWith('default:');

            if (!isSwitchLabel && line.contains('=')) {
              return CompilerResult.failure(
                error: "Ternary operator is missing '?'.",
                explanation: "শর্তের পরে '?' চিহ্ন ব্যবহার করে সত্য মানটি লিখতে হবে।",
                errorLine: lineIndex + 1,
              );
            }
            continue;
          }

          final question = questionStack.removeLast();

          final trueExpression = _extractTextBetween(
            lines: lines,
            startLine: question.lineIndex,
            startCharacter: question.charIndex + 1,
            endLine: lineIndex,
            endCharacter: charIndex,
          );

          if (_isExpressionEmpty(trueExpression)) {
            return CompilerResult.failure(
              error: "True expression is missing after '?'.",
              explanation: "'?' চিহ্নের পরে শর্ত সত্য হলে যে মানটি নেওয়া হবে তা লিখতে হবে।",
              errorLine: question.lineNumber,
            );
          }

          final remainingText = line.substring(charIndex + 1).trimLeft();

          if (remainingText.isEmpty ||
              remainingText.startsWith(';') ||
              remainingText.startsWith(')')) {
            return CompilerResult.failure(
              error: "False expression is missing after ':'.",
              explanation: "':' চিহ্নের পরে শর্ত মিথ্যা হলে যে মানটি নেওয়া হবে তা লিখতে হবে।",
              errorLine: lineIndex + 1,
            );
          }
        }
      }
    }

    if (questionStack.isNotEmpty) {
      final question = questionStack.last;

      return CompilerResult.failure(
        error: "Ternary operator is missing ':'.",
        explanation: "'?' চিহ্নের পরে সত্য মান এবং ':' চিহ্নের পরে মিথ্যা মান লিখতে হবে।",
        errorLine: question.lineNumber,
      );
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Ternary operator is valid.',
    );
  }

  (String, String)? _findInvalidConsecutiveOperators(String line) {
    final matches = RegExp(r'([+\-*/%])\s*([+\-*/%])').allMatches(line);

    for (final match in matches) {
      final firstOperator = match.group(1)!;
      final secondOperator = match.group(2)!;

      final isIncrement = firstOperator == '+' && secondOperator == '+';
      final isDecrement = firstOperator == '-' && secondOperator == '-';

      if (isIncrement || isDecrement) {
        continue;
      }

      return (firstOperator, secondOperator);
    }

    return null;
  }

  String? _findOperatorBeforeClosingParenthesis(String line) {
    final matches = RegExp(r'([+\-*/%])\s*\)').allMatches(line);

    for (final match in matches) {
      final operator = match.group(1)!;
      final operatorIndex = match.start;

      if (operator == '+' &&
          operatorIndex > 0 &&
          line[operatorIndex - 1] == '+') {
        continue;
      }

      if (operator == '-' &&
          operatorIndex > 0 &&
          line[operatorIndex - 1] == '-') {
        continue;
      }

      return operator;
    }

    return null;
  }

  String _extractTextBetween({
    required List<String> lines,
    required int startLine,
    required int startCharacter,
    required int endLine,
    required int endCharacter,
  }) {
    if (startLine == endLine) {
      return lines[startLine].substring(
        startCharacter,
        endCharacter,
      );
    }

    final buffer = StringBuffer();

    buffer.write(lines[startLine].substring(startCharacter));
    buffer.write(' ');

    for (int i = startLine + 1; i < endLine; i++) {
      buffer.write(lines[i]);
      buffer.write(' ');
    }

    buffer.write(lines[endLine].substring(0, endCharacter));

    return buffer.toString();
  }

  bool _isExpressionEmpty(String expression) {
    var cleanedExpression = expression.trim();

    while (cleanedExpression.startsWith('(') &&
        cleanedExpression.endsWith(')') &&
        cleanedExpression.length >= 2) {
      cleanedExpression =
          cleanedExpression.substring(1, cleanedExpression.length - 1).trim();
    }

    return cleanedExpression.isEmpty;
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

class _TernaryQuestion {
  final int lineNumber;
  final int lineIndex;
  final int charIndex;

  const _TernaryQuestion({
    required this.lineNumber,
    required this.lineIndex,
    required this.charIndex,
  });
}