import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/function_checker.dart';

void main() {
  group('FunctionChecker', () {
    const validFunctionMessage = '''
বৈধ Function:
• main()
• printf()
• scanf()
• pow()
• sqrt()
• strlen()
• strcmp()
• getch()
''';

    test('detects misspelled printf function', () {
      const code = '''
int main()
{
    pritnf("Hello");
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Unknown function 'pritnf'.",
      );
      expect(
        result.banglaExplanation,
        "'pritnf()' C ভাষার বৈধ Function নয়।\n\n$validFunctionMessage",
      );
      expect(result.errorLine, 3);
    });

    test('detects misspelled scanf function', () {
      const code = '''
int main()
{
    scnaf("%d",&a);
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Unknown function 'scnaf'.",
      );
      expect(
        result.banglaExplanation,
        "'scnaf()' C ভাষার বৈধ Function নয়।\n\n$validFunctionMessage",
      );
      expect(result.errorLine, 3);
    });

    test('rejects unknown function', () {
      const code = '''
int main()
{
    puts("Hello");
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(
        result.error,
        "Unknown function 'puts'.",
      );
      expect(
        result.banglaExplanation,
        "'puts()' C ভাষার বৈধ Function নয়।\n\n$validFunctionMessage",
      );
      expect(result.errorLine, 3);
    });

    test('accepts pow function', () {
      const code = '''
#include<stdio.h>
#include<math.h>

int main()
{
    printf("%f", pow(2,3));
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts sqrt function', () {
      const code = '''
#include<stdio.h>
#include<math.h>

int main()
{
    printf("%f", sqrt(25));
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts strlen function', () {
      const code = '''
#include<stdio.h>
#include<string.h>

int main()
{
    char name[20]="Guru";
    printf("%d", strlen(name));
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts strcmp function', () {
      const code = '''
#include<stdio.h>
#include<string.h>

int main()
{
    strcmp("A","B");
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts getch function', () {
      const code = '''
#include<stdio.h>
#include<conio.h>

int main()
{
    getch();
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
    test('accepts for loop as a control statement', () {
      const code = '''
int main()
{
    int i;

    for (i = 0; i < 3; i++)
    {
        printf("Hello");
    }
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts C conditional and loop keywords', () {
      const code = '''
int main()
{
    int i = 0;

    if (i == 0)
    {
        while (i < 3)
        {
            i++;
        }
    }

    switch (i)
    {
        case 3:
            break;
    }
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}
