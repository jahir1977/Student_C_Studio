import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/brace_checker.dart';
import 'package:student_c_studio/services/checkers/checker_registry.dart';
import 'package:student_c_studio/services/checkers/header_checker.dart';

void main() {
  group('CheckerRegistry', () {
    test('stores checkers in the provided order', () {
      final registry = CheckerRegistry(
        checkers: [
          HeaderChecker(),
          BraceChecker(),
        ],
      );

      expect(registry.checkers.length, 2);
      expect(registry.checkers[0], isA<HeaderChecker>());
      expect(registry.checkers[1], isA<BraceChecker>());
    });
  });
}
