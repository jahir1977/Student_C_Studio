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
  });
}
