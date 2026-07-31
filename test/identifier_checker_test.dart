import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/identifier_checker.dart';

void main() {
  group('IdentifierChecker', () {
    test('declared variable ব্যবহার করলে কোনো error হবে না', () {
      const code = '''
int main()
{
  int a;
  a = 10;
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNull);
    });

    test('undeclared variable assignment-এ ব্যবহার করলে error হবে', () {
      const code = '''
int main()
{
  a = 10;
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNotNull);
      expect(result!.error, contains("Undeclared identifier 'a'"));
      expect(result.errorLine, 3);
    });

    test('একই variable দ্বিতীয়বার declare করলে error হবে', () {
      const code = '''
int main()
{
  int a;
  int a;
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNotNull);
      expect(result!.error, contains("Duplicate declaration of 'a'"));
      expect(result.errorLine, 4);
    });

    test('declaration-এর আগে variable ব্যবহার করলে error হবে', () {
      const code = '''
int main()
{
  a = 10;
  int a;
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNotNull);
      expect(result!.error, contains("Undeclared identifier 'a'"));
      expect(result.errorLine, 3);
    });

    test('printf-এর argument হিসেবে undeclared variable ধরবে', () {
      const code = '''
#include<stdio.h>
int main()
{
  printf("%d", x);
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNotNull);
      expect(result!.error, contains("Undeclared identifier 'x'"));
      expect(result.errorLine, 4);
    });

    test('একাধিক declared variable সঠিকভাবে গ্রহণ করবে', () {
      const code = '''
int main()
{
  int a;
  float b;
  char ch;

  a = 10;
  b = 5.5;
  ch = 'A';

  printf("%d", a);
  return 0;
}
''';

      final result = IdentifierChecker.check(code);

      expect(result, isNull);
    });
  });
}