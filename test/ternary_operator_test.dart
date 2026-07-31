import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/expression_checker.dart';

void main() {
  group('ExpressionChecker - Ternary Operator', () {
    late ExpressionChecker checker;

    setUp(() {
      checker = ExpressionChecker();
    });

    test('accepts valid ternary operator in assignment', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int max;

    max = (a > b) ? a : b;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts ternary operator without outer parentheses', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int min;

    min = a < b ? a : b;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts ternary operator in for loop initialization', () {
      const code = '''
int main()
{
    int a = 5;
    int b = 10;
    int i;

    for(i = (a < b ? a : b); i <= 20; i++)
    {
        printf("%d", i);
    }

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts ternary operator in variable initialization', () {
      const code = '''
int main()
{
    int a = 15;
    int b = 8;
    int largest = a > b ? a : b;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('accepts nested ternary operator', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int c = 15;
    int largest;

    largest = a > b
        ? (a > c ? a : c)
        : (b > c ? b : c);

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isTrue);
    });

    test('detects ternary operator with missing colon', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int max;

    max = a > b ? a;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.errorLine, 7);
    });

    test('detects ternary operator with missing question mark', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int max;

    max = a > b a : b;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.errorLine, 7);
    });

    test('detects empty true expression', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int result;

    result = a > b ? : b;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.errorLine, 7);
    });

    test('detects empty false expression', () {
      const code = '''
int main()
{
    int a = 10;
    int b = 20;
    int result;

    result = a > b ? a : ;

    return 0;
}
''';

      final result = checker.check(code);

      expect(result.isSuccess, isFalse);
      expect(result.errorLine, 7);
    });
  });
}