import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/identifier_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('IdentifierChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int number = 10;
    printf("%d", number);
    return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      final legacy =
          IdentifierChecker.check(context.sanitizedSource);

      final migrated =
          IdentifierChecker.checkContext(context);

      expect(migrated?.isSuccess, legacy?.isSuccess);
      expect(migrated?.error, legacy?.error);
      expect(migrated?.errorLine, legacy?.errorLine);
      expect(migrated?.displayText, legacy?.displayText);
    });
  });
}