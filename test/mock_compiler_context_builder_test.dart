import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/models/compiler_context.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';
import 'package:student_c_studio/services/mock_compiler.dart';

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

      final CompilerContext context = CompilerContextBuilder.build(source);

      expect(context.rawSource, source);
      expect(context.sanitizedSource.isNotEmpty, isTrue);
      expect(
        context.rawLines.length,
        context.sanitizedLines.length,
      );
    });

    test('MockCompiler builds CompilerContext exactly once', () {
      var buildCount = 0;

      final MockCompiler compiler = MockCompiler(
        contextBuilder: (String source) {
          buildCount++;
          return CompilerContextBuilder.build(source);
        },
      );

      const String source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      compiler.compile(source);

      expect(buildCount, 1);
    });
  });
}
