import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/array_checker.dart';

void main() {
  group('ArrayChecker - valid array declarations', () {
    test('accepts valid integer array declaration', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[5];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });

    test('accepts array declaration with initialization', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[5] = {10, 20, 30, 40, 50};
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });

    test('accepts array size inferred from values', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[] = {10, 20, 30};
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });

    test('accepts character array', () {
      const code = '''
#include<stdio.h>
int main()
{
  char name[20];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });
  });

  group('ArrayChecker - invalid array declarations', () {
    test('detects missing closing square bracket', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[5;
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, "expected ']'");
      expect(
        result.banglaExplanation,
        'অ্যারের সাইজ লেখার পর বন্ধ বর্গাকার বন্ধনী ] দিতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects missing opening square bracket', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks5];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, "unexpected ']'");
      expect(
        result.banglaExplanation,
        'অ্যারের সাইজ লেখার আগে খোলা বর্গাকার বন্ধনী [ দিতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects zero array size', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[0];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'array size must be greater than zero');
      expect(
        result.banglaExplanation,
        'অ্যারের সাইজ অবশ্যই শূন্যের চেয়ে বড় হতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects negative array size', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[-5];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'array size cannot be negative');
      expect(
        result.banglaExplanation,
        'অ্যারের সাইজ ঋণাত্মক সংখ্যা হতে পারে না।',
      );
      expect(result.errorLine, 4);
    });

    test('detects non-integer numeric array size', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[5.5];
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'array size must be an integer');
      expect(
        result.banglaExplanation,
        'অ্যারের সাইজ হিসেবে পূর্ণসংখ্যা ব্যবহার করতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    test('ignores square brackets inside string', () {
      const code = '''
#include<stdio.h>
int main()
{
  printf("[Hello]");
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });

    test('ignores square brackets inside comment', () {
      const code = '''
#include<stdio.h>
int main()
{
  // int marks[5;
  int number = 10;
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, true);
    });
  });

  group('ArrayChecker - array initialization validation', () {
    test('detects too many array initializer values', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[3] = {10, 20, 30, 40};
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'too many initializers for array');
      expect(
        result.banglaExplanation,
        'অ্যারের নির্ধারিত ঘরের তুলনায় বেশি মান দেওয়া হয়েছে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects empty array initializer', () {
      const code = '''
#include<stdio.h>
int main()
{
  int marks[5] = {};
  return 0;
}
''';

      final result = ArrayChecker().check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'array initializer cannot be empty');
      expect(
        result.banglaExplanation,
        'অ্যারে মান নির্ধারণ করতে হলে অন্তত একটি মান দিতে হবে।',
      );
      expect(result.errorLine, 4);
    });
  });
}