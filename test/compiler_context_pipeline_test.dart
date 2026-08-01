import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('CompilerContext Pipeline', () {
    test('context exposes all required compiler data', () {
      const source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      final context =
          CompilerContextBuilder.build(source);

      expect(context.rawSource, source);

      expect(
        context.sanitizedSource,
        isNotEmpty,
      );

      expect(
        context.rawLines,
        isNotEmpty,
      );

      expect(
        context.sanitizedLines,
        isNotEmpty,
      );

      expect(
        context.rawLines.length,
        context.sanitizedLines.length,
      );
    });
  });
}