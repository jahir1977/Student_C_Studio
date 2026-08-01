import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('CompilerContextBuilder', () {
    test('builds context correctly', () {
      const String source = '''
#include<stdio.h>
int main()
{
  int number = 10; // student value
  printf("%d", number);
  return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      expect(context.rawSource, source);

      expect(
        context.rawLines.length,
        context.sanitizedLines.length,
      );

      expect(
        context.sanitizedSource.contains('student value'),
        isFalse,
      );

      expect(
        context.sanitizedSource.contains(
          'printf("%d", number);',
        ),
        isTrue,
      );

      expect(
        context.metadata.lineCount,
        source.split('\n').length,
      );
    });
  });
}