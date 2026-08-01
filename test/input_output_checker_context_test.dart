import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/input_output_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('InputOutputChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
#include<stdio.h>

int main()
{
    int number;
    scanf("%d", &number);
    printf("%d", number);
    return 0;
}
''';

      final checker = InputOutputChecker();
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