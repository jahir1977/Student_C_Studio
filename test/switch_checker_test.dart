import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/switch_checker.dart';

void main() {
  group('SwitchChecker valid syntax tests', () {
    test('accepts a valid switch statement', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    case 1:
      printf("One");
      break;

    case 2:
      printf("Two");
      break;

    default:
      printf("Invalid");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts switch brace on same line', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice) {
    case 1:
      printf("One");
      break;

    default:
      printf("Invalid");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts switch without default', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    case 1:
      printf("One");
      break;

    case 2:
      printf("Two");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts character case values', () {
      const code = '''
int main()
{
  char grade = 'A';

  switch (grade)
  {
    case 'A':
      printf("Excellent");
      break;

    case 'B':
      printf("Good");
      break;

    default:
      printf("Invalid");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiple case labels for one block', () {
      const code = '''
int main()
{
  int day = 1;

  switch (day)
  {
    case 1:
    case 2:
    case 3:
      printf("Working day");
      break;

    default:
      printf("Other day");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isTrue);
    });
  });

  group('SwitchChecker invalid switch syntax tests', () {
    test('detects missing opening parenthesis', () {
      const code = '''
int main()
{
  int choice = 1;

  switch choice)
  {
    case 1:
      printf("One");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing opening parenthesis in switch statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'switch-এর expression শুরু করার আগে "(" দিতে হবে।',
      );
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice
  {
    case 1:
      printf("One");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing closing parenthesis in switch statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'switch-এর expression শেষ করার পরে ")" দিতে হবে।',
      );
    });

    test('detects empty switch expression', () {
      const code = '''
int main()
{
  switch ()
  {
    case 1:
      printf("One");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Switch expression cannot be empty.',
      );
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'switch-এর বন্ধনীর ভেতরে একটি ভেরিয়েবল বা expression লিখতে হবে।',
      );
    });

    test('detects missing opening brace after switch', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
    case 1:
      printf("One");
      break;

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing opening brace after switch statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'switch statement-এর caseগুলো লেখার আগে "{" দিতে হবে।',
      );
    });
  });

  group('SwitchChecker invalid case tests', () {
    test('detects case without value', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    case:
      printf("One");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Case value cannot be empty.',
      );
      expect(result.errorLine, 7);
      expect(
        result.banglaExplanation,
        'case-এর পরে একটি নির্দিষ্ট মান লিখতে হবে।',
      );
    });

    test('detects missing colon after case', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    case 1
      printf("One");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing colon after case value.',
      );
      expect(result.errorLine, 7);
      expect(
        result.banglaExplanation,
        'case-এর মানের পরে ":" দিতে হবে।',
      );
    });

    test('detects duplicate case value', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    case 1:
      printf("One");
      break;

    case 1:
      printf("Again");
      break;
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Duplicate case value: 1.',
      );
      expect(result.errorLine, 11);
      expect(
        result.banglaExplanation,
        'একই switch statement-এর মধ্যে একই case value একাধিকবার ব্যবহার করা যাবে না।',
      );
    });

    test('detects case outside switch', () {
      const code = '''
int main()
{
  int choice = 1;

  case 1:
    printf("One");

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Case label found outside switch statement.',
      );
      expect(result.errorLine, 5);
      expect(
        result.banglaExplanation,
        'case শুধু switch statement-এর ভেতরে ব্যবহার করা যায়।',
      );
    });
  });

  group('SwitchChecker invalid default tests', () {
    test('detects missing colon after default', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    default
      printf("Invalid");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing colon after default.',
      );
      expect(result.errorLine, 7);
      expect(
        result.banglaExplanation,
        'default-এর পরে ":" দিতে হবে।',
      );
    });

    test('detects duplicate default label', () {
      const code = '''
int main()
{
  int choice = 1;

  switch (choice)
  {
    default:
      printf("Invalid");

    default:
      printf("Again");
  }

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Duplicate default label.',
      );
      expect(result.errorLine, 10);
      expect(
        result.banglaExplanation,
        'একটি switch statement-এর মধ্যে একটির বেশি default ব্যবহার করা যাবে না।',
      );
    });

    test('detects default outside switch', () {
      const code = '''
int main()
{
  default:
    printf("Invalid");

  return 0;
}
''';

      final result = SwitchChecker().check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Default label found outside switch statement.',
      );
      expect(result.errorLine, 3);
      expect(
        result.banglaExplanation,
        'default শুধু switch statement-এর ভেতরে ব্যবহার করা যায়।',
      );
    });
  });
}