import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/break_continue_checker.dart';

void main() {
  group('BreakContinueChecker valid syntax', () {
    test('accepts break inside while', () {
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

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts continue inside while', () {
      const code = '''
int main()
{
  while (1)
  {
    continue;
  }

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts break inside for', () {
      const code = '''
int main()
{
  for(int i=0;i<10;i++)
  {
    break;
  }

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts continue inside for', () {
      const code = '''
int main()
{
  for(int i=0;i<10;i++)
  {
    continue;
  }

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts break inside do while', () {
      const code = '''
int main()
{
  do
  {
    break;
  }
  while(1);

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts break inside switch', () {
      const code = '''
int main()
{
  switch(1)
  {
    case 1:
      break;
  }

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('BreakContinueChecker invalid syntax', () {
    test('detects break outside loop or switch', () {
      const code = '''
int main()
{
  break;

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'break statement is not inside a loop or switch.',
      );
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'break শুধুমাত্র loop বা switch-এর ভিতরে ব্যবহার করা যায়।',
      );
    });

    test('detects continue outside loop', () {
      const code = '''
int main()
{
  continue;

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'continue statement is not inside a loop.',
      );
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'continue শুধুমাত্র loop-এর ভিতরে ব্যবহার করা যায়।',
      );
    });

    test('detects continue inside switch only', () {
      const code = '''
int main()
{
  switch(1)
  {
    case 1:
      continue;
  }

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'continue statement is not inside a loop.',
      );
      expect(result.errorLine, 6);
    });
  });

  group('BreakContinueChecker special cases', () {
    test('ignores break inside string', () {
      const code = '''
int main()
{
  printf("break");
  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores continue inside comments', () {
      const code = '''
int main()
{
  // continue;
  /* break; */

  return 0;
}
''';

      final result = BreakContinueChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}