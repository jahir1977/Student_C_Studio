import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/string_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('StringChecker Context Migration', () {
    test('checkContext returns same result as check()', () {
      const String source = '''
#include<stdio.h>
#include<string.h>

int main()
{
    char name[20] = "Jahir";
    printf("%s", name);
    return 0;
}
''';

      final context =
          CompilerContextBuilder.build(source);

      final legacy =
          StringChecker.check(context.sanitizedSource);

      final migrated =
          StringChecker.checkContext(context);

      expect(migrated.isSuccess, legacy.isSuccess);
      expect(migrated.error, legacy.error);
      expect(migrated.errorLine, legacy.errorLine);
      expect(migrated.output, legacy.output);
      expect(migrated.displayText, legacy.displayText);
    });
  });
}