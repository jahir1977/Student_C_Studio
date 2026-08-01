import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/compiler_context_builder.dart';

void main() {
  group('CompilerContext', () {
    test('line collections are unmodifiable', () {
      final context = CompilerContextBuilder.build(
        'int main() {\nreturn 0;\n}',
      );

      expect(
        () => context.rawLines.add('x'),
        throwsUnsupportedError,
      );

      expect(
        () => context.sanitizedLines.add('x'),
        throwsUnsupportedError,
      );
    });
  });
}