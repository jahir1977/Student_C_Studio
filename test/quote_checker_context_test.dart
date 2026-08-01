import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/quote_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('QuoteChecker Context Migration', () {
    test('legacy and sanitized context produce identical result', () {
      const source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      final checker = QuoteChecker();
      final context = CompilerContextBuilder.build(source);

      final legacy = checker.check(context.sanitizedSource);
      final migrated = checker.check(context.sanitizedSource);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}