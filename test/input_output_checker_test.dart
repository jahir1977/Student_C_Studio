import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/input_output_checker.dart';

void main() {
  group('InputOutputChecker', () {
    // ==================================================
    // Valid printf()
    // ==================================================

    test('accepts printf with only text', () {
      const code = '''
int main()
{
    printf("Hello World");
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts printf with one variable', () {
      const code = '''
int main()
{
    int number;
    printf("%d", number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts printf with multiple variables', () {
      const code = '''
int main()
{
    int age;
    float marks;
    printf("Age = %d, Marks = %f", age, marks);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    // ==================================================
    // Valid scanf()
    // ==================================================

    test('accepts scanf with address operator', () {
      const code = '''
int main()
{
    int number;
    scanf("%d", &number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts scanf with multiple variables', () {
      const code = '''
int main()
{
    int age;
    float marks;
    char grade;
    scanf("%d%f%c", &age, &marks, &grade);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts scanf string without address operator', () {
      const code = '''
int main()
{
    char name[20];
    scanf("%s", name);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    // ==================================================
    // Wrong quotation marks
    // ==================================================

    test('detects two single quotes instead of double quote', () {
      const code = '''
int main()
{
    int number;
    printf(''%d'', number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid quotation mark in printf().',
      );
      expect(
        result.banglaExplanation,
        "printf()-এর Format String লেখার জন্য একটি Double Quote (\") "
        "ব্যবহার করতে হবে।\n"
        "দুটি Single Quote ('') কখনো Double Quote (\") নয়।",
      );
      expect(result.errorLine, 4);
    });

    test('detects single quotes around printf format string', () {
      const code = '''
int main()
{
    int number;
    printf('%d', number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid quotation mark in printf().',
      );
      expect(
        result.banglaExplanation,
        "printf()-এর Format String অবশ্যই Double Quote (\")-এর মধ্যে লিখতে হবে।\n"
        "Single Quote (') ব্যবহার করা যাবে না।",
      );
      expect(result.errorLine, 4);
    });

    test('detects two single quotes in scanf', () {
      const code = '''
int main()
{
    int number;
    scanf(''%d'', &number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Invalid quotation mark in scanf().',
      );
      expect(
        result.banglaExplanation,
        "scanf()-এর Format String লেখার জন্য একটি Double Quote (\") "
        "ব্যবহার করতে হবে।\n"
        "দুটি Single Quote ('') কখনো Double Quote (\") নয়।",
      );
      expect(result.errorLine, 4);
    });

    // ==================================================
    // Missing comma
    // ==================================================

    test('detects missing comma after printf format string', () {
      const code = '''
int main()
{
    int number;
    printf("%d" number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing comma after printf format string.',
      );
      expect(
        result.banglaExplanation,
        'printf()-এর Format String এবং Variable-এর মাঝে কমা (,) দিতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects missing comma after scanf format string', () {
      const code = '''
int main()
{
    int number;
    scanf("%d" &number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Missing comma after scanf format string.',
      );
      expect(
        result.banglaExplanation,
        'scanf()-এর Format String এবং Variable-এর মাঝে কমা (,) দিতে হবে।',
      );
      expect(result.errorLine, 4);
    });

    // ==================================================
    // scanf() address operator
    // ==================================================

    test('detects missing address operator in scanf', () {
      const code = '''
int main()
{
    int number;
    scanf("%d", number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Missing address operator before variable 'number'.",
      );
      expect(
        result.banglaExplanation,
        "scanf()-এ 'number' ভ্যারিয়েবলের আগে Address Operator (&) দিতে হবে।",
      );
      expect(result.errorLine, 4);
    });

    test('detects missing address operator among multiple scanf variables', () {
      const code = '''
int main()
{
    int age;
    float marks;
    scanf("%d%f", &age, marks);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Missing address operator before variable 'marks'.",
      );
      expect(
        result.banglaExplanation,
        "scanf()-এ 'marks' ভ্যারিয়েবলের আগে Address Operator (&) দিতে হবে।",
      );
      expect(result.errorLine, 5);
    });

    test('detects unnecessary address operator before string', () {
      const code = '''
int main()
{
    char name[20];
    scanf("%s", &name);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Unnecessary address operator before string 'name'.",
      );
      expect(
        result.banglaExplanation,
        "String Input নেওয়ার সময় 'name'-এর আগে Address Operator (&) "
        "দিতে হবে না।",
      );
      expect(result.errorLine, 4);
    });

    // ==================================================
    // printf() address operator
    // ==================================================

    test('detects address operator in printf', () {
      const code = '''
int main()
{
    int number;
    printf("%d", &number);
}
''';

      final checker = InputOutputChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Address operator is not allowed before 'number' in printf().",
      );
      expect(
        result.banglaExplanation,
        "printf()-এ 'number' ভ্যারিয়েবলের আগে Address Operator (&) "
        "ব্যবহার করা যাবে না।",
      );
      expect(result.errorLine, 4);
    });
  });
}