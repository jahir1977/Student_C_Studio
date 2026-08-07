import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/format_specifier_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('FormatSpecifierChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
int main()
{
    int age;
    float marks;
    printf("%d %f", age, marks);
}
''';

      final checker = FormatSpecifierChecker();
      final context = CompilerContextBuilder.build(source);

      final legacy = checker.check(context.sanitizedSource);
      final migrated = checker.checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });

    test('checkContext returns same result as check() for precision specifiers', () {
      const String source = '''
int main()
{
    float avg;
    printf("Average = %.2f", avg);
}
''';

      final checker = FormatSpecifierChecker();
      final context = CompilerContextBuilder.build(source);

      final legacy = checker.check(context.sanitizedSource);
      final migrated = checker.checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.isSuccess, isTrue);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}