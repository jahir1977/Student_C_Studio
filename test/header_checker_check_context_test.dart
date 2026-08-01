import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('HeaderChecker.checkContext', () {
    test('uses CompilerContext directly', () {
      const source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      final context = CompilerContextBuilder.build(source);

      final result = HeaderChecker().checkContext(context);

      expect(result.isSuccess, isTrue);
    });
  });
}