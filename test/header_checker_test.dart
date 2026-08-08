import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';

void main() {
  group('HeaderChecker', () {
    // =========================
    // stdio.h
    // =========================

    test('accepts stdio header for printf', () {
      const code = '''
#include<stdio.h>

int main()
{
    printf("Hello");
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing stdio header', () {
      const code = '''
int main()
{
    printf("Hello");
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Missing header file 'stdio.h'.");
      expect(
        result.banglaExplanation,
        "printf() অথবা scanf() ব্যবহারের জন্য #include<stdio.h> লিখতে হবে।",
      );
      expect(result.errorLine, 3);
    });

    // =========================
    // math.h
    // =========================

    test('accepts math header', () {
      const code = '''
#include<math.h>

int main()
{
    pow(2,3);
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing math header', () {
      const code = '''
int main()
{
    sqrt(25);
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Missing header file 'math.h'.");
      expect(
        result.banglaExplanation,
        "pow() অথবা sqrt() ব্যবহারের জন্য #include<math.h> লিখতে হবে।",
      );
      expect(result.errorLine, 3);
    });

    // =========================
    // string.h
    // =========================

    test('accepts string header', () {
      const code = '''
#include<string.h>

int main()
{
    strlen("Guru");
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing string header', () {
      const code = '''
int main()
{
    strcmp("A","B");
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Missing header file 'string.h'.");
      expect(
        result.banglaExplanation,
        "strlen() অথবা strcmp() অথবা strcpy() ব্যবহারের জন্য #include<string.h> লিখতে হবে।",
      );
      expect(result.errorLine, 3);
    });

    // =========================
    // conio.h
    // =========================

    test('accepts conio header', () {
      const code = '''
#include<conio.h>

int main()
{
    getch();
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects missing conio header', () {
      const code = '''
int main()
{
    getch();
}
''';

      final checker = HeaderChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Missing header file 'conio.h'.");
      expect(
        result.banglaExplanation,
        "getch() ব্যবহারের জন্য #include<conio.h> লিখতে হবে।",
      );
      expect(result.errorLine, 3);
    });
  });
}
