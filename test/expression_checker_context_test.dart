import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/expression_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('ExpressionChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int a = 5;
    int b = 10;
    int c;

    c = a + b;

    return 0;
}
''';

      final ExpressionChecker checker = ExpressionChecker();
      final context = CompilerContextBuilder.build(source);

      final legacy = checker.check(context.sanitizedSource);
      final migrated = checker.checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}