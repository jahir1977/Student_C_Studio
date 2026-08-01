import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/array_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('ArrayChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int numbers[3] = {1, 2, 3};
    numbers[1] = 10;
    return 0;
}
''';

      final ArrayChecker checker = ArrayChecker();
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