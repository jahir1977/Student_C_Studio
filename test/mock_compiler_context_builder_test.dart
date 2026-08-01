import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('MockCompiler Context Preparation', () {
    test('CompilerContextBuilder preserves source correctly', () {
      const source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      expect(context.rawSource, source);
      expect(context.sanitizedSource.isNotEmpty, isTrue);
      expect(context.rawLines.length, context.sanitizedLines.length);
    });
  });
}