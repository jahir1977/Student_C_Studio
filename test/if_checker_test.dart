import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/if_checker.dart';

void main() {
  group('IfChecker valid syntax tests', () {
    test('accepts a valid if statement', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 5)
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts if statement with brace on same line', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 5) {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts if statement without braces', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 5)
    a = a + 1;

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts a valid else if statement', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 10)
  {
    a = 1;
  }
  else if (a == 10)
  {
    a = 2;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested parentheses in condition', () {
      const code = '''
int main()
{
  int a = 10;
  int b = 20;

  if ((a < b) && (b > 5))
  {
    a = b;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('IfChecker invalid syntax tests', () {
    test('detects missing opening parenthesis', () {
      const code = '''
int main()
{
  int a = 10;

  if a > 5)
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing opening parenthesis in if statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'if-এর condition শুরু করার আগে "(" দিতে হবে।',
      );
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 5
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis in if statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'if-এর condition শেষ করার পরে ")" দিতে হবে।',
      );
    });

    test('detects empty if condition', () {
      const code = '''
int main()
{
  int a = 10;

  if ()
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'If condition cannot be empty.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'if-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
      );
    });

    test('detects empty else if condition', () {
      const code = '''
int main()
{
  int a = 10;

  if (a > 10)
  {
    a = 1;
  }
  else if ()
  {
    a = 2;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Else-if condition cannot be empty.',
      );
      expect(result.errorLine, 9);
      expect(
        result.banglaExplanation,
        'else if-এর বন্ধনীর ভেতরে একটি condition লিখতে হবে।',
      );
    });

    test('detects incomplete if condition ending with operator', () {
      const code = '''
int main()
{
  int a = 10;

  if (a >)
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid if condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'if-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });

    test('detects incomplete if condition starting with operator', () {
      const code = '''
int main()
{
  int a = 10;

  if (> a)
  {
    a = a + 1;
  }

  return 0;
}
''';

      final result = IfChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid if condition.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'if-এর condition-টি সম্পূর্ণ ও বৈধ expression হতে হবে।',
      );
    });
  });
}