import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  test('extracts included headers', () {
    const source = '''
#include<stdio.h>
#include<math.h>

int main()
{
    return 0;
}
''';

    final context =
        CompilerContextBuilder.build(source);

    expect(
      context.includedHeaders,
      contains('stdio.h'),
    );

    expect(
      context.includedHeaders,
      contains('math.h'),
    );

    expect(
      context.includedHeaders.length,
      2,
    );
  });
}