import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/do_while_checker.dart';

void main() {
  group('DoWhileChecker valid syntax tests', () {
    test('accepts a valid do while loop', () {
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

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts do while with braces on same line', () {
      const code = '''
int main()
{
  int i = 1;

  do {
    i++;
  } while (i <= 10);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts single statement do while', () {
      const code = '''
int main()
{
  int i = 1;

  do
    i++;
  while (i <= 10);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts infinite do while loop', () {
      const code = '''
int main()
{
  do
  {
    break;
  }
  while (1);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiline condition', () {
      const code = '''
int main()
{
  int i = 1;
  int n = 10;

  do
  {
    i++;
  }
  while (
    i <= n &&
    n > 0
  );

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('DoWhileChecker invalid syntax tests', () {
    test('detects missing while part', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing while statement after do block.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'do ব্লকের পরে while(condition); লিখতে হবে।',
      );
    });

    test('detects missing opening parenthesis', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }
  while i <= 10);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing opening parenthesis in while statement.');
      expect(result.errorLine, 7);
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }
  while (i <= 10;

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing closing parenthesis in while statement.');
      expect(result.errorLine, 7);
    });

    test('detects missing semicolon', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }
  while (i <= 10)

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing semicolon after do-while statement.');
      expect(result.errorLine, 7);
      expect(
        result.banglaExplanation,
        'do-while statement শেষে ";" দিতে হবে।',
      );
    });

    test('detects empty condition', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }
  while ();

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'While condition cannot be empty.');
      expect(result.errorLine, 7);
    });

    test('detects invalid condition', () {
      const code = '''
int main()
{
  do
  {
    int i = 1;
  }
  while (i <=);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid while condition.');
      expect(result.errorLine, 7);
    });

    test('detects while without do', () {
      const code = '''
int main()
{
  while (1);

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('DoWhileChecker special behavior', () {
    test('ignores do while inside string', () {
      const code = '''
int main()
{
  printf("do while");
  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores do while inside comments', () {
      const code = '''
int main()
{
  // do while
  /*
     do
     while()
  */

  return 0;
}
''';

      final result = DoWhileChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}