import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/loop_checker.dart';

void main() {
  group('LoopChecker - Valid for loops', () {
    test('accepts standard for loop with increment', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts standard for loop with decrement', () {
      const code = '''
int main()
{
  int i;
  for (i = 10; i >= 1; i--)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts pre-increment update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; ++i)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts pre-decrement update', () {
      const code = '''
int main()
{
  int i;
  for (i = 10; i >= 1; --i)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts omitted initialization', () {
      const code = '''
int main()
{
  int i = 1;
  for (; i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts omitted condition', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; ; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts omitted update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10;)
  {
    printf("%d", i);
    i++;
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts all three omitted parts', () {
      const code = '''
int main()
{
  for (;;)
  {
    printf("Running");
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts ternary operator in initialization', () {
      const code = '''
int main()
{
  int a = 5, b = 10, i;
  for (i = (a < b ? a : b); i <= 20; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts assignment update using any integer', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 100; i = i + 7)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts assignment update using a variable', () {
      const code = '''
int main()
{
  int i, n = 5;
  for (i = 1; i <= 100; i = i + n)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts multiplication assignment update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 100; i = i * 2)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts compound addition assignment', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 100; i += 5)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts compound subtraction assignment', () {
      const code = '''
int main()
{
  int i;
  for (i = 100; i >= 1; i -= 10)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts compound assignment using a variable', () {
      const code = '''
int main()
{
  int i, step = 3;
  for (i = 1; i <= 100; i += step)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, true);
    });
  });

  group('LoopChecker - Invalid for loop structure', () {
    test('detects missing first semicolon', () {
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

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects missing second semicolon', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10 i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects missing closing parenthesis', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i++
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects extra closing parenthesis', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i++))
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects too few loop sections', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects too many semicolons', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i++;)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });
  });

  group('LoopChecker - Invalid initialization', () {
    test('detects missing variable before assignment', () {
      const code = '''
int main()
{
  int i;
  for (= 1; i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects missing value after assignment', () {
      const code = '''
int main()
{
  int i;
  for (i = ; i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects invalid non-assignment initialization', () {
      const code = '''
int main()
{
  int i;
  for (i + 1; i <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });
  });

  group('LoopChecker - Invalid condition', () {
    test('detects condition containing only an operator', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; +; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects condition missing left operand', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; <= 10; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects condition missing right operand', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <; i++)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });
  });

  group('LoopChecker - Invalid update', () {
    test('detects incomplete arithmetic update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i +)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects empty assignment update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i =)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects empty compound assignment update', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; i +=)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });

    test('detects compound assignment without variable', () {
      const code = '''
int main()
{
  int i;
  for (i = 1; i <= 10; *= 2)
  {
    printf("%d", i);
  }
  return 0;
}
''';

      final checker = LoopChecker();
      final result = checker.check(code);

      expect(result.isSuccess, false);
      expect(result.errorLine, 4);
    });
  });
}