import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/brace_checker.dart';

void main() {
  group('BraceChecker', () {
    test('accepts correctly balanced braces', () {
      const code = '''
int main()
{
    int a = 10;

    if (a > 5)
    {
        printf("%d", a);
    }

    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts braces written on the same line', () {
      const code = '''
int main() {
    if (1) {
        printf("Hello");
    }
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested balanced braces', () {
      const code = '''
int main()
{
    int i;

    for (i = 1; i <= 5; i++)
    {
        if (i % 2 == 0)
        {
            printf("%d", i);
        }
    }

    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing closing brace of main function', () {
      const code = '''
int main()
{
    printf("Hello");
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ২-এ ব্যবহৃত Opening Brace ({)-এর বিপরীতে '
        'Closing Brace (}) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 2);
    });

    test('detects missing closing brace of if block', () {
      const code = '''
int main()
{
    int a = 10;

    if (a > 5)
    {
        printf("%d", a);

    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৬-এ ব্যবহৃত Opening Brace ({)-এর বিপরীতে '
        'Closing Brace (}) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 6);
    });

    test('detects extra closing brace', () {
      const code = '''
int main()
{
    printf("Hello");
}
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Extra closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৫-এ অতিরিক্ত Closing Brace (}) ব্যবহার করা হয়েছে। '
        'এর বিপরীতে কোনো Opening Brace ({) নেই।',
      );
      expect(result.errorLine, 5);
    });

    test('detects closing brace before opening brace', () {
      const code = '''
}
int main()
{
    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Extra closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ১-এ অতিরিক্ত Closing Brace (}) ব্যবহার করা হয়েছে। '
        'এর বিপরীতে কোনো Opening Brace ({) নেই।',
      );
      expect(result.errorLine, 1);
    });

    test('reports the innermost missing closing brace first', () {
      const code = '''
int main()
{
    if (1)
    {
        while (1)
        {
            printf("Running");
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৬-এ ব্যবহৃত Opening Brace ({)-এর বিপরীতে '
        'Closing Brace (}) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 6);
    });

    test('ignores braces inside double quoted string', () {
      const code = '''
int main()
{
    printf("{ Hello }");
    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores brace inside character literal', () {
      const code = '''
int main()
{
    char symbol = '}';
    printf("%c", symbol);
    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores braces inside single-line comment', () {
      const code = '''
int main()
{
    // This brace is ignored: {
    printf("Hello");
    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores braces inside multi-line comment', () {
      const code = '''
int main()
{
    /*
       These braces are ignored:
       {
       }
    */

    printf("Hello");
    return 0;
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects real missing brace after ignoring comments and strings', () {
      const code = '''
int main()
{
    printf("{");
    // }
    if (1)
    {
        printf("Hello");
}
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing brace.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ২-এ ব্যবহৃত Opening Brace ({)-এর বিপরীতে '
        'Closing Brace (}) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 2);
    });

    test('accepts source code containing no braces', () {
      const code = '''
#include<stdio.h>
''';

      final checker = BraceChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}