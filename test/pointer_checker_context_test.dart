import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/pointer_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('PointerChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int value;
    int *ptr = &value;
    return 0;
}
''';

      final context =
          CompilerContextBuilder.build(source);

      final legacy =
          PointerChecker.check(context.sanitizedSource);

      final migrated =
          PointerChecker.checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}