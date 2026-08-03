import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/educational_output_engine.dart';

void main() {
  group('EducationalOutputEngine', () {
    const EducationalOutputEngine engine = EducationalOutputEngine();

    test('supports assignment update', () {
      const String code = '''
int a = 10;
a = 20;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '20',
      );
    });
    test('supports assignment expression update', () {
      const String code = '''
int a = 10;
a = a + 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '15',
      );
    });
    test('supports postfix increment', () {
      const String code = '''
int a = 10;
a++;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '11',
      );
    });
    test('supports postfix decrement', () {
      const String code = '''
int a = 10;
a--;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '9',
      );
    });
    test('supports prefix increment', () {
      const String code = '''
int a = 10;
++a;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '11',
      );
    });
    test('supports prefix decrement', () {
      const String code = '''
int a = 10;
--a;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '9',
      );
    });
    test('supports compound addition assignment', () {
      const String code = '''
int a = 10;
a += 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '15',
      );
    });
    test('supports compound subtraction assignment', () {
      const String code = '''
int a = 10;
a -= 3;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '7',
      );
    });
    test('supports compound multiplication assignment', () {
      const String code = '''
int a = 10;
a *= 3;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '30',
      );
    });
    test('supports compound division assignment', () {
      const String code = '''
int a = 20;
a /= 4;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '5',
      );
    });
    test('supports compound modulus assignment', () {
      const String code = '''
int a = 23;
a %= 5;
printf("%d", a);
''';

      expect(
        engine.execute(code),
        '3',
      );
    });
  });
}
