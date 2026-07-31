import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/mock_compiler.dart';

void main() {
  group('MockCompiler integration tests', () {
    test('detects empty parenthesis through compiler pipeline', () {
      const code = '''
int main()
{
  int a;
  a = ();
}
''';

      const compiler = MockCompiler();
      final result = compiler.compile(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Empty parenthesis is not allowed.',
      );
      expect(result.errorLine, 4);
      expect(
        result.banglaExplanation,
        'খালি বন্ধনীর ভেতরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন থাকতে হবে।',
      );
    });
    test('detects empty expression through compiler pipeline', () {
  const code = '''
int main()
{
  int a;
  a = ;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    "Expression expected after '='.",
  );
  expect(result.errorLine, 4);
  expect(
    result.banglaExplanation,
    "সমান চিহ্নের পরে একটি মান, ভেরিয়েবল বা এক্সপ্রেশন লিখতে হবে।",
  );
});
test('detects invalid identifier through compiler pipeline', () {
  const code = '''
int main()
{
  int 2number;
  return 0;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    "invalid variable name '2number'",
  );
  expect(result.errorLine, 3);
  expect(
    result.banglaExplanation,
    'চলকের নাম অক্ষর বা underscore দিয়ে শুরু হবে; '
    'পরে অক্ষর, সংখ্যা বা underscore থাকতে পারে।',
  );
});
test('detects reserved keyword as variable name through compiler pipeline', () {
  const code = '''
int main()
{
  int for;
  return 0;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(result.errorLine, 3);
  expect(result.error, contains('for'));
  expect(result.banglaExplanation, isNotEmpty);
});
test('detects invalid character in identifier through compiler pipeline', () {
  const code = '''
int main()
{
  int student-name;
  return 0;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(result.errorLine, 3);
  expect(result.error, contains('student-name'));
  expect(result.banglaExplanation, isNotEmpty);
});
test('detects invalid for loop through compiler pipeline', () {
  const code = '''
int main()
{
  int i;
  for (i = 1 i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    'A for loop must contain exactly two semicolons.',
  );
  expect(result.errorLine, 4);
  expect(
    result.banglaExplanation,
    'for লুপের বন্ধনীর ভেতরে initialization, condition এবং update—'
    'এই তিনটি অংশ আলাদা করার জন্য ঠিক দুটি সেমিকোলন দিতে হবে।',
  );
});
test('detects invalid if condition through compiler pipeline', () {
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

  const compiler = MockCompiler();
  final result = compiler.compile(code);

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
test('detects invalid switch statement through compiler pipeline', () {
  const code = '''
int main()
{
  int choice = 1;

  switch ()
  {
    case 1:
      printf("One");
      break;
  }

  return 0;
}
''';

  const compiler = MockCompiler();
  final result = compiler.compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    'Switch expression cannot be empty.',
  );
  expect(result.errorLine, 5);
  expect(
    result.banglaExplanation,
    'switch-এর বন্ধনীর ভেতরে একটি ভেরিয়েবল বা expression লিখতে হবে।',
  );
});
test('detects invalid while condition through compiler pipeline', () {
  const code = '''
#include<stdio.h>

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

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(result.error, 'Invalid while condition.');
  expect(result.errorLine, 7);
});
test('detects invalid do while through compiler pipeline', () {
  const code = '''
#include<stdio.h>

int main()
{
    do
    {
        printf("Hello");
    }
    while (1)

    return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    'Missing semicolon after do-while statement.',
  );
  expect(result.errorLine, 9);
});
test('detects break outside loop', () {
  const code = '''
#include<stdio.h>

int main()
{
  break;

  return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    'break statement is not inside a loop or switch.',
  );
});
test('detects continue outside loop', () {
  const code = '''
#include<stdio.h>

int main()
{
  continue;

  return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(
    result.error,
    'continue statement is not inside a loop.',
  );
});
test('detects undefined goto label', () {
  const code = '''
#include<stdio.h>

int main()
{
  goto unknown;

  return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(result.error, 'Undefined label: unknown.');
});
test('detects duplicate label', () {
  const code = '''
#include<stdio.h>

int main()
{
level:
  printf("A");

level:
  printf("B");

  return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isFalse);
  expect(result.error, 'Duplicate label: level.');
});
test('accepts valid goto', () {
  const code = '''
#include<stdio.h>

int main()
{
start:
  printf("Hello");

  goto start;

  return 0;
}
''';

  final result = MockCompiler().compile(code);

  expect(result.isSuccess, isTrue);
});

  });
}