import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/models/compiler_metadata.dart';

void main() {
  group('CompilerMetadata', () {
    test('stores compiler metadata', () {
      const metadata = CompilerMetadata(
        lineCount: 7,
      );

      expect(metadata.lineCount, 7);
      expect(metadata.checkerVersion, 1);
      expect(metadata.pipelineVersion, 2);
    });
  });
}