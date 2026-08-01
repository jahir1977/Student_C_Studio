import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('CompilerContext migration', () {
    test('HeaderChecker receives sanitized source from context', () {
      const source = '''
// #include<stdio.h>

#include<stdio.h>

int main()
{
    return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      expect(
        context.sanitizedSource.contains('#include<stdio.h>'),
        isTrue,
      );

      expect(
        context.sanitizedSource.contains('//'),
        isFalse,
      );
    });
  });
}