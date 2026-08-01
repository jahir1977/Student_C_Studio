import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('HeaderChecker Context Migration', () {
    test('HeaderChecker produces identical result using sanitized source', () {
      const source = '''
// Fake header:
// #include<stdio.h>

#include<stdio.h>

int main()
{
    return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      final legacy =
          HeaderChecker().check(context.sanitizedSource);

      final migrated =
          HeaderChecker().checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}