import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/mock_compiler.dart';

void main() {
  group('MockCompiler registry integration', () {
    test('compiles a valid C program successfully', () {
      const code = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
''';

      const compiler = MockCompiler();

      final result = compiler.compile(code);

      expect(result.isSuccess, isTrue);
      expect(result.output, 'Hello');
    });

    test('registry still reports header errors', () {
      const code = '''
int main()
{
    printf("Hello");
    return 0;
}
''';

      const compiler = MockCompiler();

      final result = compiler.compile(code);

      expect(result.isSuccess, isFalse);
    });

    test('registry still reports brace errors', () {
      const code = '''
#include<stdio.h>

int main()
{
    printf("Hello");

''';

      const compiler = MockCompiler();

      final result = compiler.compile(code);

      expect(result.isSuccess, isFalse);
    });
  });
}
