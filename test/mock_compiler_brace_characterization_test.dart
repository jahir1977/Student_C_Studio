import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/mock_compiler.dart';

void main() {
  group('MockCompiler brace fallback characterization', () {
    const MockCompiler compiler = MockCompiler();

    test('BraceChecker reports a missing main closing brace', () {
      const String code = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
''';

      final result = compiler.compile(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Missing closing brace.');
      expect(result.errorLine, 4);
    });

    test('BraceChecker reports an extra closing brace', () {
      const String code = '''
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
}
''';

      final result = compiler.compile(code);

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Extra closing brace.');
      expect(result.errorLine, 8);
    });

    test('braces inside a string do not cause a brace error', () {
      const String code = '''
#include<stdio.h>

int main()
{
    printf("{ Hello }");
    return 0;
}
''';

      final result = compiler.compile(code);

      expect(result.isSuccess, isTrue);
    });

    test('brace inside a character literal does not cause a brace error', () {
      const String code = '''
#include<stdio.h>

int main()
{
    char symbol = '}';
    printf("%c", symbol);
    return 0;
}
''';

      final result = compiler.compile(code);

      expect(result.isSuccess, isTrue);
    });

    test('nested balanced blocks pass the compiler pipeline', () {
      const String code = '''
#include<stdio.h>

int main()
{
    int i;

    for (i = 0; i < 3; i++)
    {
        if (i > 0)
        {
            printf("Hello");
        }
    }

    return 0;
}
''';

      final result = compiler.compile(code);

      expect(result.isSuccess, isTrue);
    });
  });
}
