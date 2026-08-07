import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/format_specifier_checker.dart';

void main() {
  group('FormatSpecifierChecker', () {
    // ==================================================
    // Single format specifier
    // ==================================================

    test('accepts %d for int variable', () {
      const code = '''
int main()
{
    int a;
    printf("%d", a);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts %f for float variable', () {
      const code = '''
int main()
{
    float x;
    printf("%f", x);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts %lf for double variable', () {
      const code = '''
int main()
{
    double value;
    printf("%lf", value);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts %c for char variable', () {
      const code = '''
int main()
{
    char grade;
    printf("%c", grade);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts %s for character array', () {
      const code = '''
int main()
{
    char name[20];
    printf("%s", name);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    // ==================================================
    // Multiple format specifiers
    // ==================================================

    test('accepts multiple format specifiers of same type', () {
      const code = '''
int main()
{
    int a, b, c;
    printf("%d%d%d", a, b, c);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiple mixed format specifiers', () {
      const code = '''
int main()
{
    int age;
    float marks;
    char grade;
    printf("%d %f %c", age, marks, grade);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiple format specifiers in scanf', () {
      const code = '''
int main()
{
    int age;
    float marks;
    char grade;
    scanf("%d%f%c", &age, &marks, &grade);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    // ==================================================
    // Type mismatch
    // ==================================================

    test('detects format specifier and variable type mismatch', () {
      const code = '''
int main()
{
    float marks;
    printf("%d", marks);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Format specifier '%d' does not match variable 'marks'.",
      );
      expect(
        result.banglaExplanation,
        "'%d' int টাইপ ডাটার জন্য ব্যবহৃত হয়।\n"
        "'marks' হলো float টাইপ ভ্যারিয়েবল।",
      );
      expect(result.errorLine, 4);
    });

    test('detects mismatch among multiple format specifiers', () {
      const code = '''
int main()
{
    int age;
    float marks;
    printf("%f %d", age, marks);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Format specifier '%f' does not match variable 'age'.",
      );
      expect(
        result.banglaExplanation,
        "'%f' float টাইপ ডাটার জন্য ব্যবহৃত হয়।\n"
        "'age' হলো int টাইপ ভ্যারিয়েবল।",
      );
      expect(result.errorLine, 5);
    });

    // ==================================================
    // Number mismatch
    // ==================================================

    test('detects fewer variables than format specifiers', () {
      const code = '''
int main()
{
    int a;
    printf("%d%d", a);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Format specifier count does not match variable count.',
      );
      expect(
        result.banglaExplanation,
        '২টি Format Specifier ব্যবহার করা হয়েছে, কিন্তু ১টি Variable দেওয়া হয়েছে।',
      );
      expect(result.errorLine, 4);
    });

    test('detects more variables than format specifiers', () {
      const code = '''
int main()
{
    int a, b;
    printf("%d", a, b);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        'Format specifier count does not match variable count.',
      );
      expect(
        result.banglaExplanation,
        '১টি Format Specifier ব্যবহার করা হয়েছে, কিন্তু ২টি Variable দেওয়া হয়েছে।',
      );
      expect(result.errorLine, 4);
    });

    // ==================================================
    // Unsupported format specifier
    // ==================================================

    test('detects unsupported format specifier', () {
      const code = '''
int main()
{
    int number;
    printf("%u", number);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Unsupported format specifier '%u'.",
      );
      expect(
        result.banglaExplanation,
        "'%u' HSC পাঠ্যবইয়ের অনুমোদিত Format Specifier নয়।\n\n"
        "বৈধ Format Specifier:\n"
        "• %c — char\n"
        "• %d — int\n"
        "• %f — float\n"
        "• %lf — double\n"
        "• %s — string",
      );
      expect(result.errorLine, 4);
    });

    // ==================================================
    // Precision / width modifiers
    // ==================================================

    test('accepts %.2f for float variable', () {
      const code = '''
int main()
{
    float avg;
    printf("Average = %.2f", avg);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts %5.2f and %05d with matching variables', () {
      const code = '''
int main()
{
    float total;
    int count;
    printf("Total = %5.2f, Count = %05d", total, count);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects type mismatch through a precision specifier', () {
      const code = '''
int main()
{
    int total;
    printf("Total = %.2f", total);
}
''';

      final checker = FormatSpecifierChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Format specifier '%f' does not match variable 'total'.",
      );
    });
  });
}