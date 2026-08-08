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
• fabs()
• strlen()
• strcmp()
• strcpy()
• strcat()
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
    test('accepts a user-defined function call', () {
      const code = '''
int add(int a, int b)
{
    return a + b;
}

int main()
{
    int result;
    result = add(5, 3);
    return 0;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts user-defined function declared after main', () {
      const code = '''
int main()
{
    int result;
    result = add(5, 3);
    return 0;
}

int add(int a, int b)
{
    return a + b;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts multiline user-defined function header', () {
      const code = '''
int add(
    int a,
    int b
)
{
    return a + b;
}

int main()
{
    int result;
    result = add(5, 3);
    return 0;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('still rejects an undefined function', () {
      const code = '''
int main()
{
    calculate(5);
    return 0;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Unknown function 'calculate'.");
      expect(result.errorLine, 3);
    });

    test('does not treat a function prototype as a definition', () {
      const code = '''
int calculate(int value);

int main()
{
    calculate(5);
    return 0;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, "Unknown function 'calculate'.");
    });

    test('accepts void user-defined function', () {
      const code = '''
void display()
{
    printf("Hello");
}

int main()
{
    display();
    return 0;
}
''';

      final checker = FunctionChecker();
      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });
  });
}
