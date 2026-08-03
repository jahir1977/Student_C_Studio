import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/educational_output_engine.dart';

void main() {
  group('EducationalOutputEngine', () {
    const EducationalOutputEngine engine = EducationalOutputEngine();

    test('supports assignment update', () {
      const String code = '''
int a = 10;
a = 20;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '20',
      );
    });
    test('supports assignment expression update', () {
      const String code = '''
int a = 10;
a = a + 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '15',
      );
    });
    test('supports postfix increment', () {
      const String code = '''
int a = 10;
a++;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '11',
      );
    });
    test('supports postfix decrement', () {
      const String code = '''
int a = 10;
a--;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '9',
      );
    });
    test('supports prefix increment', () {
      const String code = '''
int a = 10;
++a;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '11',
      );
    });
    test('supports prefix decrement', () {
      const String code = '''
int a = 10;
--a;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '9',
      );
    });
    test('supports compound addition assignment', () {
      const String code = '''
int a = 10;
a += 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '15',
      );
    });
    test('supports compound subtraction assignment', () {
      const String code = '''
int a = 10;
a -= 3;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '7',
      );
    });
    test('supports compound multiplication assignment', () {
      const String code = '''
int a = 10;
a *= 3;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '30',
      );
    });
    test('supports compound division assignment', () {
      const String code = '''
int a = 20;
a /= 4;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '5',
      );
    });
    test('supports compound modulus assignment', () {
      const String code = '''
int a = 23;
a %= 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '3',
      );
    });
    test('supports simple if statement', () {
      const String code = '''
int a = 10;

if (a > 5)
{
    printf("OK");
}
''';

      expect(
        engine.execute(code),
        'OK',
      );
    });
    test('skips if body when condition is false', () {
      const String code = '''
int a = 2;

if (a > 5)
{
    printf("OK");
}
''';

      expect(
        engine.execute(code),
        '',
      );
    });
    test('executes if body only when condition is true', () {
      const String code = '''
int a = 10;

if (a > 5)
{
    printf("YES");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'YESEND',
      );
    });
    test('executes else body when if condition is false', () {
      const String code = '''
int a = 2;

if (a > 5)
{
    printf("YES");
}
else
{
    printf("NO");
}
''';

      expect(
        engine.execute(code),
        'NO',
      );
    });
    test('executes only one branch of if else', () {
      const String code = '''
int a = 2;

if (a > 5)
{
    printf("YES");
}
else
{
    printf("NO");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'NOEND',
      );
    });
    test('executes true branch instead of else', () {
      const String code = '''
int a = 10;

if (a > 5)
{
    printf("YES");
}
else
{
    printf("NO");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'YESEND',
      );
    });
    test('supports nested if statements', () {
      const String code = '''
int a = 10;
int b = 20;

if (a > 5)
{
    if (b > 10)
    {
        printf("OK");
    }
}
''';

      expect(
        engine.execute(code),
        'OK',
      );
    });
    test('skips inner if when inner condition is false', () {
      const String code = '''
int a = 10;
int b = 5;

if (a > 5)
{
    if (b > 10)
    {
        printf("OK");
    }
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });
  });
}
