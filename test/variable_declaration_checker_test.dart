import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/variable_declaration_checker.dart';

void main() {
  group('VariableDeclarationChecker', () {
    test('accepts valid declarations', () {
      const String code = '''
int a;
int a1 = 10;
float result = 5.5;
double total, average;
char grade = 'A';
unsigned int count = 0;
int *pointer;
int numbers[10];
''';

      final VariableCheckResult result =
          VariableDeclarationChecker.check(code);

      expect(result.isValid, isTrue);
    });

    test('rejects missing variable name', () {
      final VariableCheckResult result =
          VariableDeclarationChecker.check('int;');

      expect(result.isValid, isFalse);
      expect(result.error, 'variable name expected');
      expect(result.line, 1);
    });

    test('rejects invalid identifier', () {
      final VariableCheckResult result =
          VariableDeclarationChecker.check('int 10a;');

      expect(result.isValid, isFalse);
      expect(result.error, contains('invalid variable name'));
    });

    test('rejects empty initializer', () {
      final VariableCheckResult result =
          VariableDeclarationChecker.check('int a =;');

      expect(result.isValid, isFalse);
      expect(result.error, "expression expected after '='");
    });

    test('rejects adjacent commas', () {
      final VariableCheckResult result =
          VariableDeclarationChecker.check('int a,,b;');

      expect(result.isValid, isFalse);
      expect(result.error, 'invalid variable declaration');
    });

    test('rejects reserved word as identifier', () {
      final VariableCheckResult result =
          VariableDeclarationChecker.check('int return;');

      expect(result.isValid, isFalse);
      expect(result.error, contains('reserved word'));
    });
  });
}
