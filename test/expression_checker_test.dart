import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/expression_checker.dart';

void main() {
  group('ExpressionChecker', () {
    test('ExpressionChecker detects expression ending with an operator', () {
      const sourceCode = '''
int a;
a = 10 +;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Expression is incomplete after operator '+'.",
      );
      expect(result.errorLine, 2);

      // ১. বাংলা ব্যাখ্যা ফাঁকা নয় নিশ্চিত করা
      expect(result.banglaExplanation.isNotEmpty, isTrue);

      // ২. বাক্যটি সঠিক বিষয় নিয়ে শুরু হয়েছে কিনা তা চেক করা (ইউনিকোড ও স্পেস এরর মুক্ত)
      expect(result.banglaExplanation.startsWith('অপারেটরের পরে'), isTrue);
    });

    // এর পর থেকে আপনার বাকি test(...) ব্লকগুলো শুরু হবে...

    test('detects expression starting with an operator', () {
      const sourceCode = '''
int a;
a = + 10;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Expression cannot start with operator '+'.",
      );
      expect(result.errorLine, 2);
      expect(
        result.banglaExplanation,
        "অ্যাসাইনমেন্ট চিহ্নের পরে সরাসরি অপারেটর ব্যবহার করা যাবে না।",
      );
    });

    test('detects consecutive operators', () {
      const sourceCode = '''
int a;
a = 10 + * 5;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Two operators cannot appear consecutively: '+' and '*'.",
      );
      expect(result.errorLine, 2);
      expect(
        result.banglaExplanation,
        "দুটি গাণিতিক অপারেটর পাশাপাশি ব্যবহার করা যাবে না।",
      );
    });

    test('detects missing closing parenthesis', () {
      const sourceCode = '''
int a;
a = (10 + 5;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Missing closing parenthesis ')'.",
      );
      expect(result.errorLine, 2);
      expect(
        result.banglaExplanation,
        "খোলা বন্ধনীর জন্য একটি সমাপনী বন্ধনী ')' দিতে হবে।",
      );
    });

    test('detects extra closing parenthesis', () {
      const sourceCode = '''
int a;
a = 10 + 5);
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Extra closing parenthesis ')'.",
      );
      expect(result.errorLine, 2);
      expect(
  result.banglaExplanation.replaceAll('\u200B', '').trim(),
  'এই সমাপনী বন্ধনী \')\' এর জন্য কোনো খোলা বন্ধনী নেই।'.replaceAll('\u200B', '').trim(),
);
    });
    test('accepts a valid expression', () {
      const sourceCode = '''
int a;
a = (10 + 5) * 2;
''';
      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);
      expect(result.isSuccess, isTrue);
      expect(result.error, '');
    });
    test('detects empty right side of assignment', () {
      const sourceCode = '''
int a;
a = ;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Expression expected after '='.",
      );
      expect(result.errorLine, 2);
      expect(
        result.banglaExplanation.replaceAll('\u200B', '').trim(),
        "সমান চিহ্নের পরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন লিখতে হবে।",
      );
    });
    test('detects missing operator between operands', () {
      const sourceCode = '''
int a;
a = 10 5;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Operator expected between operands.",
      );
      expect(result.errorLine, 2);
      expect(
  result.banglaExplanation.replaceAll('\u200B', '').trim(),
  'দুইটি মান বা ভেরিয়েবলের মাঝে একটি অপারেটর থাকতে হবে।'.replaceAll('\u200B', '').trim(),
);
    });
    test('detects operator before closing parenthesis', () {
      const sourceCode = '''
int a;
a = (10 + );
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Expression is incomplete before closing parenthesis.",
      );
      expect(result.errorLine, 2);
      expect(
  result.banglaExplanation.replaceAll('\u200B', '').trim(),
  'সমাপনী বন্ধনীর আগে অপারেটরের পরে একটি মান বা ভেরিয়েবল থাকতে হবে।'.replaceAll('\u200B', '').trim(),
);
    });
    test('detects operator immediately after opening parenthesis', () {
      const sourceCode = '''
int a;
a = (*10);
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Expression cannot start with operator after '('.",
      );
      expect(result.errorLine, 2);
      expect(
        result.banglaExplanation,
        "খোলা বন্ধনীর পরে সরাসরি অপারেটর ব্যবহার করা যাবে না।",
      );
    });
    test('detects empty parenthesis', () {
      const sourceCode = '''
int a;
a = ();
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Empty parenthesis is not allowed.",
      );
      expect(result.errorLine, 2);
      expect(
  result.banglaExplanation.replaceAll('\u200B', '').trim(),
  'খালি বন্ধনীর ভেতরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন থাকতে হবে।'.replaceAll('\u200B', '').trim(),
);
    });
    test('accepts unary minus expression', () {
      const sourceCode = '''
int a;
a = -5;
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isTrue);
      expect(result.error, '');
    });

    test('accepts scanf format string with percent specifiers', () {
      const sourceCode = '''
scanf("%d %d", &a, &b);
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isTrue);
      expect(result.error, '');
    });

    test('accepts printf text containing equals and percent', () {
      const sourceCode = '''
printf("Sum = %d", sum);
''';

      final checker = ExpressionChecker();
      final result = checker.check(sourceCode);

      expect(result.isSuccess, isTrue);
      expect(result.error, '');
    });
  });
}
