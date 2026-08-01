import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/loop_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('LoopChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int i;
    for(i = 0; i < 10; i++)
    {
    }
    return 0;
}
''';

      final LoopChecker checker = LoopChecker();
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