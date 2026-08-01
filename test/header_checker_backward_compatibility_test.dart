import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('HeaderChecker backward compatibility', () {
    test('legacy and context APIs remain equivalent', () {
      const String source = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      final HeaderChecker checker = HeaderChecker();
      final context = CompilerContextBuilder.build(source);

      final legacy = checker.check(source);
      final contextResult = checker.checkContext(context);

      expect(contextResult.isSuccess, legacy.isSuccess);
      expect(contextResult.error, legacy.error);
      expect(contextResult.errorLine, legacy.errorLine);
      expect(contextResult.output, legacy.output);
      expect(contextResult.displayText, legacy.displayText);
    });
  });
}