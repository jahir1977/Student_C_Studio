import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/while_checker.dart';

void main() {
  group('WhileChecker valid syntax tests', () {
    test('accepts a valid while loop', () {
      const code = '''
int main()
{
  int i = 1;

  while (i <= 10)
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts while loop with brace on same line', () {
      const code = '''
int main()
{
  int i = 1;

  while (i <= 10) {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts while loop without braces', () {
      const code = '''
int main()
{
  int i = 1;

  while (i <= 10)
    i++;

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested parentheses in while condition', () {
      const code = '''
int main()
{
  int i = 1;
  int n = 10;

  while ((i <= n) && (n > 0))
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts infinite while loop', () {
      const code = '''
int main()
{
  while (1)
  {
    break;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts while condition across multiple lines', () {
      const code = '''
int main()
{
  int i = 1;
  int n = 10;

  while (
    i <= n &&
    n > 0
  )
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('WhileChecker invalid syntax tests', () {
    test('detects missing opening parenthesis', () {
      const code = '''
int main()
{
  int i = 1;

  while i <= 10)
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing opening parenthesis in while statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition শুরু করার আগে "(" দিতে হবে।',
      );
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
  int i = 1;

  while (i <= 10
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis in while statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition শেষ করার পরে ")" দিতে হবে।',
      );
    });

    test('detects empty while condition', () {
      const code = '''
int main()
{
  while ()
  {
    break;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'While condition cannot be empty.',
      );
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'while-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
      );
    });

    test('detects condition ending with operator', () {
      const code = '''
int main()
{
  int i = 1;

  while (i <=)
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid while condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });

    test('detects condition starting with invalid operator', () {
      const code = '''
int main()
{
  int i = 1;

  while (> i)
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid while condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });

    test('detects empty nested parenthesis', () {
      const code = '''
int main()
{
  int i = 1;

  while (())
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid while condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });

    test('detects invalid consecutive operators', () {
      const code = '''
int main()
{
  int i = 1;

  while (i >> 10)
  {
    i++;
  }

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid while condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'while-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });
  });

  group('WhileChecker special behavior tests', () {
    test('does not confuse do while ending with normal while loop', () {
      const code = '''
int main()
{
  int i = 1;

  do
  {
    i++;
  }
  while (i <= 10);

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores while text inside string', () {
      const code = '''
int main()
{
  printf("while ()");
  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores while text inside line comment', () {
      const code = '''
int main()
{
  // while ()
  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores while text inside block comment', () {
      const code = '''
int main()
{
  /*
    while ()
  */

  return 0;
}
''';

      final result = WhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}