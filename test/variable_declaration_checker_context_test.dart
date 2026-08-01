import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/variable_declaration_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('VariableDeclarationChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int number = 10;
    return 0;
}
''';

      final context =
          CompilerContextBuilder.build(source);

      final legacy =
          VariableDeclarationChecker.check(
        context.sanitizedSource,
      );

      final migrated =
          VariableDeclarationChecker.checkContext(
        context,
      );

      expect(migrated.isValid, legacy.isValid);
      expect(migrated.error, legacy.error);
      expect(migrated.explanation, legacy.explanation);
      expect(migrated.line, legacy.line);
    });
  });
}