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
    test('accepts multiple variables in one declaration', () {
  const String code = '''
int a, b, c;
float x, y;
double total, average;
char first, second;
''';

  final VariableCheckResult result =
      VariableDeclarationChecker.check(code);

  expect(result.isValid, isTrue);
});

test('accepts mixed initialized and uninitialized variables', () {
  const String code = '''
int a = 1, b, c = 3;
float x = 2.5, y;
double total, average = 10.75;
char first = 'A', second;
''';

  final VariableCheckResult result =
      VariableDeclarationChecker.check(code);

  expect(result.isValid, isTrue);
});

test('accepts pointer array and ordinary variables together', () {
  const String code = '''
int value, *pointer, numbers[5];
char letter, *text, name[20];
''';

  final VariableCheckResult result =
      VariableDeclarationChecker.check(code);

  expect(result.isValid, isTrue);
});

test('accepts signed unsigned short and long declarations', () {
  const String code = '''
signed int first;
unsigned int second;
short int third;
long int fourth;
long long int fifth;
unsigned char character;
long double amount;
''';

  final VariableCheckResult result =
      VariableDeclarationChecker.check(code);

  expect(result.isValid, isTrue);
});

test('rejects leading comma in declaration', () {
  final VariableCheckResult result =
      VariableDeclarationChecker.check('int ,a;');

  expect(result.isValid, isFalse);
  expect(result.error, 'invalid variable declaration');
  expect(result.line, 1);
});

test('rejects trailing comma in declaration', () {
  final VariableCheckResult result =
      VariableDeclarationChecker.check('int a,;');

  expect(result.isValid, isFalse);
  expect(result.error, 'invalid variable declaration');
  expect(result.line, 1);
});

test('rejects missing variable between commas', () {
  final VariableCheckResult result =
      VariableDeclarationChecker.check('float a, ,b;');

  expect(result.isValid, isFalse);
  expect(result.error, 'invalid variable declaration');
  expect(result.line, 1);
});

test('rejects missing identifier before initializer', () {
  final VariableCheckResult result =
      VariableDeclarationChecker.check('int = 5;');

  expect(result.isValid, isFalse);
  expect(result.error, 'variable name expected');
  expect(result.line, 1);
});
  });
}
