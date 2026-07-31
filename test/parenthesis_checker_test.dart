import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/parenthesis_checker.dart';

void main() {
  group('ParenthesisChecker', () {
    test('accepts correctly balanced parentheses', () {
      const code = '''
int main()
{
    printf("Hello");
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested parentheses', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;

    if ((a < b) && (b > 5))
    {
        printf("%d", a);
    }

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts parentheses in for loop', () {
      const code = '''
int main()
{
    int i;

    for (i = 0; i < 10; i++)
    {
        printf("%d", i);
    }

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts parentheses in while loop', () {
      const code = '''
int main()
{
    int i = 1;

    while (i <= 5)
    {
        i++;
    }

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested function calls', () {
      const code = '''
int main()
{
    double result;

    result = sqrt(pow(4, 2));
    printf("%lf", result);

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
    printf("Hello";
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৩-এ ব্যবহৃত Opening Parenthesis (()-এর বিপরীতে '
        'Closing Parenthesis ()) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 3);
    });

    test('detects missing closing parenthesis in if condition', () {
      const code = '''
int main()
{
    int a = 10;

    if (a > 5
    {
        printf("%d", a);
    }

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৫-এ ব্যবহৃত Opening Parenthesis (()-এর বিপরীতে '
        'Closing Parenthesis ()) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 5);
    });

    test('detects extra closing parenthesis', () {
      const code = '''
int main()
{
    printf("Hello"));
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Extra closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৩-এ অতিরিক্ত Closing Parenthesis ()) ব্যবহার করা হয়েছে। '
        'এর বিপরীতে কোনো Opening Parenthesis (() নেই।',
      );
      expect(result.errorLine, 3);
    });

    test('detects closing parenthesis before opening parenthesis', () {
      const code = '''
)
int main()
{
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Extra closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ১-এ অতিরিক্ত Closing Parenthesis ()) ব্যবহার করা হয়েছে। '
        'এর বিপরীতে কোনো Opening Parenthesis (() নেই।',
      );
      expect(result.errorLine, 1);
    });

    test('reports innermost missing closing parenthesis first', () {
      const code = '''
int main()
{
    int result;

    result = sqrt(pow(4, 2);
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৫-এ ব্যবহৃত Opening Parenthesis (()-এর বিপরীতে '
        'Closing Parenthesis ()) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 5);
    });

    test('ignores parentheses inside double quoted string', () {
      const code = '''
int main()
{
    printf("(Hello)");
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores parenthesis inside character literal', () {
      const code = '''
int main()
{
    char symbol = ')';
    printf("%c", symbol);
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores parentheses inside single-line comment', () {
      const code = '''
int main()
{
    // These are ignored: ( )
    printf("Hello");
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores parentheses inside multi-line comment', () {
      const code = '''
int main()
{
    /*
       These are ignored:
       (
       )
    */

    printf("Hello");
    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects real missing parenthesis after ignoring comments and strings', () {
      const code = '''
int main()
{
    printf("(");
    // )
    if (1
    {
        printf("Hello");
    }

    return 0;
}
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis.',
      );
      expect(
        result.banglaExplanation,
        'লাইন ৫-এ ব্যবহৃত Opening Parenthesis (()-এর বিপরীতে '
        'Closing Parenthesis ()) দেওয়া হয়নি।',
      );
      expect(result.errorLine, 5);
    });

    test('accepts source code containing no parentheses', () {
      const code = '''
#include<stdio.h>
''';

      final checker = ParenthesisChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}