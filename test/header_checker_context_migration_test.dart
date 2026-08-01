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

      final result =
          HeaderChecker().check(context.sanitizedSource);

      expect(result.isSuccess, isTrue);
    });
  });
}