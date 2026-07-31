import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/goto_checker.dart';

void main() {
  group('GotoChecker valid syntax', () {
    test('accepts backward goto', () {
      const code = '''
int main()
{
  int i=1;

level:
  i=i+1;

  if(i<=10)
    goto level;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts forward goto', () {
      const code = '''
int main()
{
  goto finish;

  printf("Hello");

finish:
  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts label beginning with underscore', () {
      const code = '''
int main()
{
_start:
  goto _start;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts label containing digits', () {
      const code = '''
int main()
{
level2:
  goto level2;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiple goto statements for same label', () {
      const code = '''
int main()
{
level:
  if(1)
    goto level;

  goto level;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiple valid labels', () {
      const code = '''
int main()
{
first:
  goto second;

second:
  goto first;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('GotoChecker invalid goto statements', () {
    test('detects goto without label name', () {
      const code = '''
int main()
{
  goto;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Label name is missing after goto.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'goto-এর পরে একটি বৈধ label-এর নাম লিখতে হবে।',
      );
    });

    test('detects missing semicolon after goto', () {
      const code = '''
int main()
{
  goto level

level:
  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing semicolon after goto statement.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'goto statement-এর শেষে semicolon (;) দিতে হবে।',
      );
    });

    test('detects undefined label', () {
      const code = '''
int main()
{
  goto unknown;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Undefined label: unknown.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        '"unknown" নামে কোনো label পাওয়া যায়নি।',
      );
    });

    test('detects invalid label name after goto', () {
      const code = '''
int main()
{
  goto 2level;

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid label name after goto.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'Label-এর নাম সংখ্যা দিয়ে শুরু করা যাবে না।',
      );
    });
  });

  group('GotoChecker invalid label declarations', () {
    test('detects duplicate label', () {
      const code = '''
int main()
{
level:
  printf("One");

level:
  printf("Two");

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Duplicate label: level.');
      expect(result.errorLine, 6);
      expect(
        result.banglaExplanation,
        '"level" label একাধিকবার লেখা হয়েছে। প্রতিটি label-এর নাম আলাদা হতে হবে।',
      );
    });

    test('detects label beginning with number', () {
      const code = '''
int main()
{
2level:
  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid label name: 2level.');
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'Label-এর নাম সংখ্যা দিয়ে শুরু করা যাবে না।',
      );
    });
  });

  group('GotoChecker special cases', () {
    test('ignores goto and labels inside string', () {
      const code = '''
int main()
{
  printf("goto unknown;");
  printf("level:");

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('ignores goto and labels inside comments', () {
      const code = '''
int main()
{
  // goto unknown;
  // level:

  /*
    goto missing;
    another:
  */

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('does not treat case and default as labels', () {
      const code = '''
int main()
{
  switch(1)
  {
    case 1:
      break;

    default:
      break;
  }

  return 0;
}
''';

      final result = GotoChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}