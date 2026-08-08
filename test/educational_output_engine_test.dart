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

    test('supports logical AND condition', () {
      const String code = '''
int a = 10;
int b = 20;

if (a > 5 && b > 10)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'OKEND',
      );
    });

    test('skips logical AND when second condition is false', () {
      const String code = '''
int a = 10;
int b = 2;

if (a > 5 && b > 10)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports logical OR condition', () {
      const String code = '''
int a = 2;
int b = 20;

if (a > 5 || b > 10)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'OKEND',
      );
    });

    test('skips logical OR when both conditions are false', () {
      const String code = '''
int a = 2;
int b = 5;

if (a > 5 || b > 10)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports logical NOT condition', () {
      const String code = '''
int a = 0;

if (!a)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'OKEND',
      );
    });

    test('skips logical NOT condition when value is nonzero', () {
      const String code = '''
int a = 5;

if (!a)
{
    printf("OK");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports while loop execution', () {
      const String code = '''
int i = 1;

while (i <= 3)
{
    printf("%d", i);
    i++;
}
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('supports while loop with false initial condition', () {
      const String code = '''
int i = 5;

while (i < 5)
{
    printf("X");
    i++;
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports while loop with decrement', () {
      const String code = '''
int i = 3;

while (i > 0)
{
    printf("%d", i);
    i--;
}
''';

      expect(
        engine.execute(code),
        '321',
      );
    });

    test('supports while loop with compound addition assignment', () {
      const String code = '''
int i = 1;

while (i <= 4)
{
    printf("%d", i);
    i += 1;
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('supports while loop with compound subtraction assignment', () {
      const String code = '''
int i = 4;

while (i > 0)
{
    printf("%d", i);
    i -= 1;
}
''';

      expect(
        engine.execute(code),
        '4321',
      );
    });

    test('supports logical AND condition inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 5 && i != 4)
{
    printf("%d", i);
    i++;
}

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('supports logical OR condition inside while loop', () {
      const String code = '''
int i = 1;

while (i < 3 || i == 3)
{
    printf("%d", i);
    i++;
}
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('supports logical NOT condition inside while loop', () {
      const String code = '''
int i = 0;

while (!i)
{
    printf("OK");
    i++;
}

printf("END");
''';

      expect(
        engine.execute(code),
        'OKEND',
      );
    });

    test('supports if statement inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 4)
{
    if (i == 2)
    {
        printf("X");
    }

    printf("%d", i);
    i++;
}
''';

      expect(
        engine.execute(code),
        '1X234',
      );
    });

    test('supports if else statement inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 3)
{
    if (i == 2)
    {
        printf("X");
    }
    else
    {
        printf("%d", i);
    }

    i++;
}
''';

      expect(
        engine.execute(code),
        '1X3',
      );
    });

    test('supports multiple printf statements inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 2)
{
    printf("[");
    printf("%d", i);
    printf("]");
    i++;
}
''';

      expect(
        engine.execute(code),
        '[1][2]',
      );
    });

    test('supports expression assignment inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 4)
{
    printf("%d", i);
    i = i + 1;
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('supports multiplication update inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 8)
{
    printf("%d ", i);
    i *= 2;
}
''';

      expect(
        engine.execute(code),
        '1 2 4 8 ',
      );
    });

    test('supports division update inside while loop', () {
      const String code = '''
int i = 8;

while (i >= 1)
{
    printf("%d ", i);
    i /= 2;
}
''';

      expect(
        engine.execute(code),
        '8 4 2 1 ',
      );
    });

    test('supports nested while loop execution', () {
      const String code = '''
int i = 1;
int j = 1;

while (i <= 2)
{
    j = 1;

    while (j <= 2)
    {
        printf("%d", i);
        printf("%d", j);
        j++;
    }

    i++;
}
''';

      expect(
        engine.execute(code),
        '11122122',
      );
    });

    test('preserves printf after while loop', () {
      const String code = '''
int i = 1;

while (i <= 3)
{
    printf("%d", i);
    i++;
}

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('stops non-progressing while loop safely', () {
      const String code = '''
int i = 1;

while (i <= 3)
{
    printf("X");
}
''';

      final String output = engine.execute(code);

      expect(
        output.length,
        lessThanOrEqualTo(10000),
      );
    });

    test('supports do while loop execution', () {
      const String code = '''
int i = 1;

do
{
    printf("%d", i);
    i++;
}
while (i <= 3);
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('executes do while body once when condition is initially false', () {
      const String code = '''
int i = 5;

do
{
    printf("%d", i);
    i++;
}
while (i < 5);

printf("END");
''';

      expect(
        engine.execute(code),
        '5END',
      );
    });

    test('supports do while loop with decrement', () {
      const String code = '''
int i = 3;

do
{
    printf("%d", i);
    i--;
}
while (i > 0);
''';

      expect(
        engine.execute(code),
        '321',
      );
    });

    test('supports compound assignment inside do while loop', () {
      const String code = '''
int i = 1;

do
{
    printf("%d", i);
    i += 1;
}
while (i <= 4);
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('supports logical AND condition inside do while loop', () {
      const String code = '''
int i = 1;

do
{
    printf("%d", i);
    i++;
}
while (i <= 5 && i != 4);

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('supports logical OR condition inside do while loop', () {
      const String code = '''
int i = 1;

do
{
    printf("%d", i);
    i++;
}
while (i < 3 || i == 3);
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('supports logical NOT condition inside do while loop', () {
      const String code = '''
int i = 0;

do
{
    printf("OK");
    i++;
}
while (!i);

printf("END");
''';

      expect(
        engine.execute(code),
        'OKEND',
      );
    });

    test('supports if statement inside do while loop', () {
      const String code = '''
int i = 1;

do
{
    if (i == 2)
    {
        printf("X");
    }

    printf("%d", i);
    i++;
}
while (i <= 3);
''';

      expect(
        engine.execute(code),
        '1X23',
      );
    });

    test('supports nested do while loop execution', () {
      const String code = '''
int i = 1;
int j = 1;

do
{
    j = 1;

    do
    {
        printf("%d", i);
        printf("%d", j);
        j++;
    }
    while (j <= 2);

    i++;
}
while (i <= 2);
''';

      expect(
        engine.execute(code),
        '11122122',
      );
    });

    test('preserves printf after do while loop', () {
      const String code = '''
int i = 1;

do
{
    printf("%d", i);
    i++;
}
while (i <= 3);

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('stops non-progressing do while loop safely', () {
      const String code = '''
int i = 1;

do
{
    printf("X");
}
while (i <= 3);
''';

      final String output = engine.execute(code);

      expect(
        output.length,
        lessThanOrEqualTo(10000),
      );
    });

    test('supports for loop execution', () {
      const String code = '''
for (int i = 1; i <= 3; i++)
{
    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('supports for loop with existing variable', () {
      const String code = '''
int i = 1;

for (i = 1; i <= 4; i++)
{
    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('skips for loop when initial condition is false', () {
      const String code = '''
for (int i = 5; i < 5; i++)
{
    printf("X");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports for loop with decrement', () {
      const String code = '''
for (int i = 3; i > 0; i--)
{
    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '321',
      );
    });

    test('supports compound update inside for header', () {
      const String code = '''
for (int i = 1; i <= 8; i *= 2)
{
    printf("%d ", i);
}
''';

      expect(
        engine.execute(code),
        '1 2 4 8 ',
      );
    });

    test('supports assignment update inside for header', () {
      const String code = '''
for (int i = 1; i <= 4; i = i + 1)
{
    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('supports logical condition inside for loop', () {
      const String code = '''
for (int i = 1; i <= 5 && i != 4; i++)
{
    printf("%d", i);
}

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('supports if statement inside for loop', () {
      const String code = '''
for (int i = 1; i <= 4; i++)
{
    if (i == 2)
    {
        printf("X");
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1X234',
      );
    });

    test('supports nested for loop execution', () {
      const String code = '''
for (int i = 1; i <= 2; i++)
{
    for (int j = 1; j <= 2; j++)
    {
        printf("%d", i);
        printf("%d", j);
    }
}
''';

      expect(
        engine.execute(code),
        '11122122',
      );
    });

    test('supports while loop inside for loop', () {
      const String code = '''
int j = 1;

for (int i = 1; i <= 2; i++)
{
    j = 1;

    while (j <= 2)
    {
        printf("%d", i);
        printf("%d", j);
        j++;
    }
}
''';

      expect(
        engine.execute(code),
        '11122122',
      );
    });

    test('preserves printf after for loop', () {
      const String code = '''
for (int i = 1; i <= 3; i++)
{
    printf("%d", i);
}

printf("END");
''';

      expect(
        engine.execute(code),
        '123END',
      );
    });

    test('stops non-progressing for loop safely', () {
      const String code = '''
for (;;)
{
    printf("X");
}
''';

      final String output = engine.execute(code);

      expect(
        output.length,
        lessThanOrEqualTo(10000),
      );
    });

    test('supports break inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 10)
{
    if (i == 5)
    {
        break;
    }

    printf("%d", i);
    i++;
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('supports break inside do while loop', () {
      const String code = '''
int i = 1;

do
{
    if (i == 4)
    {
        break;
    }

    printf("%d", i);
    i++;
}
while (i <= 10);
''';

      expect(
        engine.execute(code),
        '123',
      );
    });

    test('supports break inside for loop', () {
      const String code = '''
for (int i = 1; i <= 10; i++)
{
    if (i == 5)
    {
        break;
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1234',
      );
    });

    test('break exits only nearest nested while loop', () {
      const String code = '''
int i = 1;
int j = 1;

while (i <= 2)
{
    j = 1;

    while (j <= 3)
    {
        if (j == 2)
        {
            break;
        }

        printf("%d", i);
        printf("%d", j);
        j++;
    }

    i++;
}
''';

      expect(
        engine.execute(code),
        '1121',
      );
    });

    test('break exits only nearest nested for loop', () {
      const String code = '''
for (int i = 1; i <= 2; i++)
{
    for (int j = 1; j <= 3; j++)
    {
        if (j == 2)
        {
            break;
        }

        printf("%d", i);
        printf("%d", j);
    }
}
''';

      expect(
        engine.execute(code),
        '1121',
      );
    });

    test('supports break from infinite for loop', () {
      const String code = '''
int i = 1;

for (;;)
{
    printf("%d", i);
    break;
}

printf("END");
''';

      expect(
        engine.execute(code),
        '1END',
      );
    });

    test('supports immediate break inside while loop', () {
      const String code = '''
int i = 1;

while (i <= 3)
{
    break;
    printf("X");
}

printf("END");
''';

      expect(
        engine.execute(code),
        'END',
      );
    });

    test('supports break inside if else within for loop', () {
      const String code = '''
for (int i = 1; i <= 4; i++)
{
    if (i == 3)
    {
        break;
    }
    else
    {
        printf("%d", i);
    }
}

printf("END");
''';

      expect(
        engine.execute(code),
        '12END',
      );
    });

    test('preserves statements after loop containing break', () {
      const String code = '''
int i = 1;

while (i <= 5)
{
    if (i == 3)
    {
        break;
    }

    printf("%d", i);
    i++;
}

printf("END");
''';

      expect(
        engine.execute(code),
        '12END',
      );
    });

    test('break prevents later statements in same loop iteration', () {
      const String code = '''
for (int i = 1; i <= 5; i++)
{
    printf("%d", i);

    if (i == 3)
    {
        break;
    }

    printf("X");
}
''';

      expect(
        engine.execute(code),
        '1X2X3',
      );
    });

    test('supports continue inside while loop', () {
      const String code = '''
int i = 0;

while (i < 5)
{
    i++;

    if (i == 3)
    {
        continue;
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1245',
      );
    });

    test('supports continue inside do while loop', () {
      const String code = '''
int i = 0;

do
{
    i++;

    if (i == 3)
    {
        continue;
    }

    printf("%d", i);
}
while (i < 5);
''';

      expect(
        engine.execute(code),
        '1245',
      );
    });

    test('supports continue inside for loop', () {
      const String code = '''
for (int i = 1; i <= 5; i++)
{
    if (i == 3)
    {
        continue;
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1245',
      );
    });

    test('continue skips remaining statements in while iteration', () {
      const String code = '''
int i = 0;

while (i < 4)
{
    i++;

    if (i == 2)
    {
        continue;
    }

    printf("%d", i);
    printf("X");
}
''';

      expect(
        engine.execute(code),
        '1X3X4X',
      );
    });

    test('continue skips remaining statements in for iteration', () {
      const String code = '''
for (int i = 1; i <= 4; i++)
{
    printf("%d", i);

    if (i == 2)
    {
        continue;
    }

    printf("X");
}
''';

      expect(
        engine.execute(code),
        '1X23X4X',
      );
    });

    test('continue affects only nearest nested while loop', () {
      const String code = '''
int i = 1;
int j = 0;

while (i <= 2)
{
    j = 0;

    while (j < 3)
    {
        j++;

        if (j == 2)
        {
            continue;
        }

        printf("%d", i);
        printf("%d", j);
    }

    i++;
}
''';

      expect(
        engine.execute(code),
        '11132123',
      );
    });

    test('continue affects only nearest nested for loop', () {
      const String code = '''
for (int i = 1; i <= 2; i++)
{
    for (int j = 1; j <= 3; j++)
    {
        if (j == 2)
        {
            continue;
        }

        printf("%d", i);
        printf("%d", j);
    }
}
''';

      expect(
        engine.execute(code),
        '11132123',
      );
    });

    test('supports continue inside logical condition branch', () {
      const String code = '''
for (int i = 1; i <= 6; i++)
{
    if (i > 2 && i < 5)
    {
        continue;
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '1256',
      );
    });

    test('supports continue inside OR condition branch', () {
      const String code = '''
for (int i = 1; i <= 5; i++)
{
    if (i == 2 || i == 4)
    {
        continue;
    }

    printf("%d", i);
}
''';

      expect(
        engine.execute(code),
        '135',
      );
    });

    test('preserves statements after loop containing continue', () {
      const String code = '''
for (int i = 1; i <= 3; i++)
{
    if (i == 2)
    {
        continue;
    }

    printf("%d", i);
}

printf("END");
''';

      expect(
        engine.execute(code),
        '13END',
      );
    });

    test('supports scanf integer input', () {
      const String code = '''
int a = 0;
scanf("%d", &a);
printf("%d", a);
''';

      expect(
        engine.execute(code, input: '25'),
        '25',
      );
    });

    test('supports scanf with multiple integer variables', () {
      const String code = '''
int a = 0;
int b = 0;

scanf("%d%d", &a, &b);
printf("%d", a);
printf("%d", b);
''';

      expect(
        engine.execute(code, input: '10 20'),
        '1020',
      );
    });

    test('supports arithmetic expression after scanf', () {
      const String code = '''
int a = 0;
int b = 0;

scanf("%d%d", &a, &b);
printf("%d", a + b);
''';

      expect(
        engine.execute(code, input: '12 8'),
        '20',
      );
    });

    test('supports if condition after scanf', () {
      const String code = '''
int a = 0;

scanf("%d", &a);

if (a > 10)
{
    printf("BIG");
}
else
{
    printf("SMALL");
}
''';

      expect(
        engine.execute(code, input: '15'),
        'BIG',
      );
    });

    test('supports scanf value as while loop limit', () {
      const String code = '''
int limit = 0;
int i = 1;

scanf("%d", &limit);

while (i <= limit)
{
    printf("%d", i);
    i++;
}
''';

      expect(
        engine.execute(code, input: '4'),
        '1234',
      );
    });

    test('supports repeated scanf inside while loop', () {
      const String code = '''
int i = 1;
int value = 0;

while (i <= 3)
{
    scanf("%d", &value);
    printf("%d", value);
    i++;
}
''';

      expect(
        engine.execute(code, input: '7 8 9'),
        '789',
      );
    });

    test('supports multiple scanf statements in input order', () {
      const String code = '''
int a = 0;
int b = 0;

scanf("%d", &a);
scanf("%d", &b);

printf("%d", a);
printf("%d", b);
''';

      expect(
        engine.execute(code, input: '3 6'),
        '36',
      );
    });

    test('supports negative integer input with scanf', () {
      const String code = '''
int a = 0;

scanf("%d", &a);
printf("%d", a);
''';

      expect(
        engine.execute(code, input: '-12'),
        '-12',
      );
    });

    test('preserves current value when scanf input is missing', () {
      const String code = '''
int a = 7;

scanf("%d", &a);
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '7',
      );
    });

    test('supports scanf input inside do while loop', () {
      const String code = '''
int count = 0;
int value = 0;

do
{
    scanf("%d", &value);
    printf("%d", value);
    count++;
}
while (count < 3);
''';

      expect(
        engine.execute(code, input: '4 5 6'),
        '456',
      );
    });

    test('supports float scanf arithmetic and printf', () {
      const String code = '''
float celsius;
float fahrenheit;
scanf("%f", &celsius);
fahrenheit = (celsius * 9 / 5) + 32;
printf("%.2f", fahrenheit);
''';

      expect(
        engine.execute(code, input: '25.5'),
        '77.90',
      );
    });

    test('supports double scanf and printf', () {
      const String code = '''
double value;
scanf("%lf", &value);
printf("%.3lf", value);
''';

      expect(
        engine.execute(code, input: '12.3456'),
        '12.346',
      );
    });

    test('supports character scanf and printf', () {
      const String code = '''
char ch;
scanf("%c", &ch);
printf("%c", ch);
''';

      expect(
        engine.execute(code, input: 'A'),
        'A',
      );
    });

    test('supports string scanf and printf', () {
      const String code = '''
char name[30];
scanf("%s", name);
printf("%s", name);
''';

      expect(
        engine.execute(code, input: 'Jahir'),
        'Jahir',
      );
    });

    test('supports mixed scanf specifiers', () {
      const String code = '''
int age;
float mark;
char grade;
char name[30];

scanf("%d%f%c%s", &age, &mark, &grade, name);
printf("%d %.1f %c %s", age, mark, grade, name);
''';

      expect(
        engine.execute(
          code,
          input: '18\n87.5\nA\nStudent',
        ),
        '18 87.5 A Student',
      );
    });

    test('preserves integer division behavior', () {
      const String code = '''
int a = 5;
int b = 2;
printf("%d", a / b);
''';

      expect(
        engine.execute(code),
        '2',
      );
    });

    test('uses floating point division when float is involved', () {
      const String code = '''
float a = 5;
float b = 2;
printf("%.1f", a / b);
''';

      expect(
        engine.execute(code),
        '2.5',
      );
    });

    test('supports comma separated float declarations', () {
      const String code = '''
float a, b, sum;
scanf("%f%f", &a, &b);
sum = a + b;
printf("%.2f", sum);
''';

      expect(
        engine.execute(code, input: '2.25\n3.5'),
        '5.75',
      );
    });

    test('supports Celsius to Fahrenheit program with float input', () {
      const String code = '''
#include<stdio.h>

int main()
{
    float celsius, fahrenheit;
    printf("Enter temperature in Celsius: ");
    scanf("%f", &celsius);
    fahrenheit = (celsius * 9 / 5) + 32;
    printf("Fahrenheit = %.2f", fahrenheit);
    return 0;
}
''';

      expect(
        engine.execute(code, input: '25.5'),
        'Enter temperature in Celsius: Fahrenheit = 77.90',
      );
    });

    test('prints float with default six decimal places', () {
      const String code = '''
float value;
scanf("%f", &value);
printf("%f", value);
''';
      expect(engine.execute(code, input: '12.5'), '12.500000');
    });

    test('prints float with two decimal places', () {
      const String code = '''
float value;
scanf("%f", &value);
printf("%.2f", value);
''';
      expect(engine.execute(code, input: '12.345'), '12.35');
    });

    test('prints float with three decimal places', () {
      const String code = '''
float value;
scanf("%f", &value);
printf("%.3f", value);
''';
      expect(engine.execute(code, input: '12.3456'), '12.346');
    });

    test('supports negative float input', () {
      const String code = '''
float value;
scanf("%f", &value);
printf("%.2f", value);
''';
      expect(engine.execute(code, input: '-7.25'), '-7.25');
    });

    test('supports double arithmetic', () {
      const String code = '''
double a;
double b;
double result;
scanf("%lf", &a);
scanf("%lf", &b);
result = a / b;
printf("%.4lf", result);
''';
      expect(engine.execute(code, input: '10\n4'), '2.5000');
    });

    test('supports character assignment and comparison', () {
      const String code = '''
char grade;
scanf("%c", &grade);
if (grade == 'A')
{
    printf("Excellent");
}
else
{
    printf("Other");
}
''';
      expect(engine.execute(code, input: 'A'), 'Excellent');
    });

    test('supports string declaration initializer and printf', () {
      const String code = '''
char name[30] = "Student";
printf("%s", name);
''';
      expect(engine.execute(code), 'Student');
    });

    test('supports multiple string inputs in separate scanf calls', () {
      const String code = '''
char first[30];
char second[30];
scanf("%s", first);
scanf("%s", second);
printf("%s %s", first, second);
''';
      expect(engine.execute(code, input: 'Hello\nWorld'), 'Hello World');
    });

    test('supports int plus float arithmetic', () {
      const String code = '''
int a = 5;
float b = 2.5;
float result;
result = a + b;
printf("%.1f", result);
''';
      expect(engine.execute(code), '7.5');
    });

    test('supports float multiplied by integer', () {
      const String code = '''
float price = 12.5;
int quantity = 4;
float total;
total = price * quantity;
printf("%.2f", total);
''';
      expect(engine.execute(code), '50.00');
    });

    test('supports float compound assignment', () {
      const String code = '''
float value = 10.5;
value += 2.25;
printf("%.2f", value);
''';
      expect(engine.execute(code), '12.75');
    });

    test('supports float decrement and increment', () {
      const String code = '''
float value = 2.5;
value++;
printf("%.1f", value);
value--;
printf("%.1f", value);
''';
      expect(engine.execute(code), '3.52.5');
    });

    test('supports mixed printf arguments in one statement', () {
      const String code = '''
int age = 18;
float mark = 87.5;
char grade = 'A';
char name[30] = "Student";
printf("%s %d %.1f %c", name, age, mark, grade);
''';
      expect(engine.execute(code), 'Student 18 87.5 A');
    });

    test('supports mixed scanf in separate statements', () {
      const String code = '''
int age;
float mark;
double score;
char grade;
char name[30];
scanf("%d", &age);
scanf("%f", &mark);
scanf("%lf", &score);
scanf("%c", &grade);
scanf("%s", name);
printf("%d %.1f %.2lf %c %s", age, mark, score, grade, name);
''';
      expect(
        engine.execute(code, input: '18\n87.5\n92.75\nA\nStudent'),
        '18 87.5 92.75 A Student',
      );
    });

    test('supports float condition inside while loop', () {
      const String code = '''
float value = 1.0;
while (value <= 3.0)
{
    printf("%.1f", value);
    value += 1.0;
}
''';
      expect(engine.execute(code), '1.02.03.0');
    });

    test('supports float condition inside for loop', () {
      const String code = '''
float value;
for (value = 1.0; value <= 3.0; value += 1.0)
{
    printf("%.1f", value);
}
''';
      expect(engine.execute(code), '1.02.03.0');
    });

    test('supports escaped percent with float output', () {
      const String code = '''
float value = 50.0;
printf("%.1f%%", value);
''';
      expect(engine.execute(code), '50.0%');
    });

    test('supports zero precision float output', () {
      const String code = '''
float value = 12.6;
printf("%.0f", value);
''';
      expect(engine.execute(code), '13');
    });

    test('supports character numeric arithmetic', () {
      const String code = '''
char ch = 'A';
printf("%d", ch + 1);
''';
      expect(engine.execute(code), '66');
    });

    test('supports multiple float inputs in one scanf', () {
      const String code = '''
float a, b, average;
scanf("%f%f", &a, &b);
average = (a + b) / 2;
printf("%.2f", average);
''';
      expect(engine.execute(code, input: '10.5\n20.5'), '15.50');
    });

    // ==================================================
    // goto / label support
    // ==================================================

    test('supports goto loop that sums numbers up to n', () {
      const String code = '''
int i = 1, n, sum = 0;
scanf("%d", &n);
level:
sum = sum + i;
i++;
if(i <= n)
    goto level;
printf("Sum = %d", sum);
''';
      expect(engine.execute(code, input: '5'), 'Sum = 15');
    });

    test('label declaration alone does not block the next statement', () {
      const String code = '''
int sum = 0;
start:
sum = sum + 1;
printf("%d", sum);
''';
      expect(engine.execute(code), '1');
    });

    // ==================================================
    // Array element access
    // ==================================================

    test('reads a single array element directly', () {
      const String code = '''
int arr[3];
scanf("%d", &arr[0]);
printf("%d", arr[0]);
''';
      expect(engine.execute(code, input: '7'), '7');
    });

    test('supports array element inside an arithmetic expression', () {
      const String code = '''
int arr[10], i, s = 0;
for(i = 0; i < 10; i++)
{
    scanf("%d", &arr[i]);
}
for(i = 0; i < 10; i++)
{
    s = s + arr[i];
}
printf("sum=%d", s);
''';
      expect(
        engine.execute(code, input: '1 2 3 4 5 6 7 8 9 10'),
        'sum=55',
      );
    });
    test('supports direct array element assignment', () {
      const String code = '''
int arr[3];
arr[0] = 10;
arr[1] = 20;
arr[2] = 30;
printf("%d", arr[1]);
''';

      expect(
        engine.execute(code),
        '20',
      );
    });
    test('supports array initializer list', () {
      const String code = '''
int arr[5] = {10, 20, 30, 40, 50};
printf("%d", arr[2]);
''';

      expect(
        engine.execute(code),
        '30',
      );
    });

    test('supports inferred array size from initializer', () {
      const String code = '''
int arr[] = {5, 10, 15};
printf("%d", arr[2]);
''';

      expect(
        engine.execute(code),
        '15',
      );
    });
    test('finds largest value in an array', () {
      const String code = '''
int arr[5] = {12, 45, 7, 89, 34};
int i, largest;

largest = arr[0];

for(i = 1; i < 5; i++)
{
    if(arr[i] > largest)
    {
        largest = arr[i];
    }
}

printf("%d", largest);
''';

      expect(
        engine.execute(code),
        '89',
      );
    });
    test('calculates sum of array elements', () {
      const String code = '''
int arr[5] = {10, 20, 30, 40, 50};
int i, sum = 0;

for(i = 0; i < 5; i++)
{
    sum = sum + arr[i];
}

printf("%d", sum);
''';

      expect(
        engine.execute(code),
        '150',
      );
    });
    test('calculates average of array elements', () {
      const String code = '''
int arr[5] = {10, 20, 30, 40, 50};
int i, sum = 0;
float avg;

for(i = 0; i < 5; i++)
{
    sum = sum + arr[i];
}

avg = sum / 5.0;

printf("%.2f", avg);
''';

      expect(
        engine.execute(code),
        '30.00',
      );
    });
    test('prints array elements in reverse order', () {
      const String code = '''
int arr[5] = {10, 20, 30, 40, 50};
int i;

for(i = 4; i >= 0; i--)
{
    printf("%d ", arr[i]);
}
''';

      expect(
        engine.execute(code),
        '50 40 30 20 10 ',
      );
    });
    test('searches an element in an array', () {
      const String code = '''
int arr[5] = {10, 20, 30, 40, 50};
int i, key = 30, found = 0;

for(i = 0; i < 5; i++)
{
    if(arr[i] == key)
    {
        found = 1;
        break;
    }
}

printf("%d", found);
''';

      expect(
        engine.execute(code),
        '1',
      );
    });
    test('counts even numbers in an array', () {
      const String code = '''
int arr[6] = {10, 15, 20, 21, 30, 41};
int i, count = 0;

for(i = 0; i < 6; i++)
{
    if(arr[i] % 2 == 0)
    {
        count++;
    }
}

printf("%d", count);
''';

      expect(
        engine.execute(code),
        '3',
      );
    });
    test('copies one array into another', () {
      const String code = '''
int a[5] = {10, 20, 30, 40, 50};
int b[5];
int i;

for(i = 0; i < 5; i++)
{
    b[i] = a[i];
}

printf("%d %d %d %d %d",
    b[0], b[1], b[2], b[3], b[4]);
''';

      expect(
        engine.execute(code),
        '10 20 30 40 50',
      );
    });
    test('counts occurrences of a value in an array', () {
      const String code = '''
int arr[8] = {10, 20, 10, 30, 10, 40, 20, 10};
int i, count = 0;

for(i = 0; i < 8; i++)
{
    if(arr[i] == 10)
    {
        count++;
    }
}

printf("%d", count);
''';

      expect(
        engine.execute(code),
        '4',
      );
    });
    test('supports sqrt function', () {
      const String code = '''
float x = 4;
float result;
result = sqrt(x);
printf("%f", result);
''';

      expect(
        engine.execute(code),
        '2.000000',
      );
    });
    test('supports pow function', () {
      const String code = '''
float x = 2;
float result;
result = pow(x, 3);
printf("%f", result);
''';

      expect(
        engine.execute(code),
        '8.000000',
      );
    });
    test('supports fabs function', () {
      const String code = '''
float x = -7.25;
float result;
result = fabs(x);
printf("%.2f", result);
''';

      expect(
        engine.execute(code),
        '7.25',
      );
    });
    test('supports strlen function', () {
      const String code = '''
char word[30] = "Bangladesh";
int length;
length = strlen(word);
printf("%d", length);
''';

      expect(
        engine.execute(code),
        '10',
      );
    });
    test('supports strcmp function for equal strings', () {
      const String code = '''
char first[30] = "Bangladesh";
char second[30] = "Bangladesh";
int result;
result = strcmp(first, second);
printf("%d", result);
''';

      expect(
        engine.execute(code),
        '0',
      );
    });
    test('supports strcmp function for different strings', () {
      const String code = '''
char first[30] = "Apple";
char second[30] = "Banana";
int result;
result = strcmp(first, second);
printf("%d", result);
''';

      final String output = engine.execute(code);

      expect(
        int.parse(output),
        lessThan(0),
      );
    });
    test('supports strcpy function', () {
      const String code = '''
char source[30] = "Bangladesh";
char destination[30];
strcpy(destination, source);
printf("%s", destination);
''';

      expect(
        engine.execute(code),
        'Bangladesh',
      );
    });
    test('supports strcat function', () {
      const String code = '''
char first[30] = "Hello ";
char second[30] = "World";

strcat(first, second);

printf("%s", first);
''';

      expect(
        engine.execute(code),
        'Hello World',
      );
    });
  });
}
