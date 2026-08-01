import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/switch_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('SwitchChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int number = 1;

    switch (number)
    {
        case 1:
            break;
        default:
            break;
    }

    return 0;
}
''';

      final SwitchChecker checker = SwitchChecker();
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