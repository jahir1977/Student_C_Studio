import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/while_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('WhileChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int i = 0;

    while (i < 10)
    {
        i++;
    }

    return 0;
}
''';

      final WhileChecker checker = WhileChecker();
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