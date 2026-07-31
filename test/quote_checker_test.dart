import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/quote_checker.dart';

void main() {
  group('QuoteChecker', () {
    test('accepts valid double quoted string', () {
      const code = '''
int main()
{
    printf("Hello World");
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts valid single quoted character', () {
      const code = '''
int main()
{
    char grade = 'A';
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts escaped double quote inside string', () {
      const code = r'''
int main()
{
    printf("He said \"Hello\"");
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts escaped single quote inside character literal', () {
      const code = r'''
int main()
{
    char symbol = '\'';
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts escape character literal', () {
      const code = r'''
int main()
{
    char newLine = '\n';
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing closing double quote', () {
      const code = '''
int main()
{
    printf("Hello World);
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing double quote.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৩-এ String শুরু করার জন্য Double Quote (") ব্যবহার করা হয়েছে, '
        'কিন্তু String শেষ করার জন্য আরেকটি Double Quote (") দেওয়া হয়নি।',
      );
      expect(result.errorLine, 3);
    });

    test('detects missing closing single quote', () {
      const code = '''
int main()
{
    char grade = 'A;
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing single quote.',
      );
      expect(
        result.banglaExplanation,
        "লাইন ৩-এ Character শুরু করার জন্য Single Quote (') ব্যবহার করা হয়েছে, "
        "কিন্তু Character শেষ করার জন্য আরেকটি Single Quote (') দেওয়া হয়নি।",
      );
      expect(result.errorLine, 3);
    });

    test('detects two single quotes used instead of double quotes in printf', () {
      const code = '''
int main()
{
    int number = 10;
    printf(''%d'', number);
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Two single quotes cannot replace a double quote.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৪-এ দুটি Single Quote (\'\') ব্যবহার করে Double Quote (") '
        'তৈরি করার চেষ্টা করা হয়েছে।\n'
        'দুটি Single Quote (\'\') কখনো একটি Double Quote (") নয়।',
      );
      expect(result.errorLine, 4);
    });

    test('detects two single quotes used instead of double quotes in scanf', () {
      const code = '''
int main()
{
    int number;
    scanf(''%d'', &number);
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Two single quotes cannot replace a double quote.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৪-এ দুটি Single Quote (\'\') ব্যবহার করে Double Quote (") '
        'তৈরি করার চেষ্টা করা হয়েছে।\n'
        'দুটি Single Quote (\'\') কখনো একটি Double Quote (") নয়।',
      );
      expect(result.errorLine, 4);
    });

    test('detects string written with single quotes', () {
      const code = '''
int main()
{
    printf('Hello World');
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'String cannot be written with single quotes.',
      );
      expect(
        result.banglaExplanation,
        "লাইন ৩-এ String লেখার জন্য Single Quote (') ব্যবহার করা হয়েছে।\n"
        'String অবশ্যই Double Quote (")-এর মধ্যে লিখতে হবে।',
      );
      expect(result.errorLine, 3);
    });

    test('detects multiple characters inside single quotes', () {
      const code = '''
int main()
{
    char grade = 'AB';
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Character literal contains multiple characters.',
      );
      expect(
        result.banglaExplanation,
        "লাইন ৩-এ Single Quote (')-এর মধ্যে একাধিক Character লেখা হয়েছে।\n"
        "Single Quote (')-এর মধ্যে শুধুমাত্র একটি Character লেখা যাবে।",
      );
      expect(result.errorLine, 3);
    });

    test('detects empty character literal', () {
      const code = '''
int main()
{
    char grade = '';
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Empty character literal.',
      );
      expect(
        result.banglaExplanation,
        "লাইন ৩-এ Single Quote (')-এর মধ্যে কোনো Character লেখা হয়নি।\n"
        "Single Quote (')-এর মধ্যে একটি Character লিখতে হবে।",
      );
      expect(result.errorLine, 3);
    });

    test('ignores quotes inside single-line comment', () {
      const code = '''
int main()
{
    // "This quote is ignored
    printf("Hello");
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores quotes inside multi-line comment', () {
      const code = '''
int main()
{
    /*
       "This double quote is ignored
       'This single quote is ignored
    */

    printf("Hello");
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects first quote error only', () {
      const code = '''
int main()
{
    char grade = 'AB';
    printf("Hello World);
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Character literal contains multiple characters.',
      );
      expect(result.errorLine, 3);
    });

    test('accepts source code containing no quotes', () {
      const code = '''
#include<stdio.h>

int main()
{
    return 0;
}
''';

      final checker = QuoteChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}