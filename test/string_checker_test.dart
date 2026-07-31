import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/string_checker.dart';

String _program(String body) {
  return '''
#include<stdio.h>
#include<string.h>

int main()
{
$body
  return 0;
}
''';
}

void main() {
  group('StringChecker - declaration', () {
    test('accepts a valid fixed-size string declaration', () {
      final code = _program('  char name[20];');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts multiple valid string declarations', () {
      final code = _program('''
  char name[20];
  char city[30];
  char country[15];
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('ignores a scalar char variable', () {
      final code = _program("  char grade = 'A';");

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects character array declaration without size', () {
      final code = _program('  char name[];');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Array size is missing.');
      expect(
        result.banglaExplanation,
        'স্ট্রিং ঘোষণার সময় অ্যারের সাইজ উল্লেখ করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects character array declaration with zero size', () {
      final code = _program('  char name[0];');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Array size cannot be zero.');
      expect(
        result.banglaExplanation,
        'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ শূন্য হতে পারে না।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects character array declaration with negative size', () {
      final code = _program('  char name[-5];');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Array size cannot be negative.');
      expect(
        result.banglaExplanation,
        'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ ঋণাত্মক হতে পারে না।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects character array declaration with decimal size', () {
      final code = _program('  char name[10.5];');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Array size must be an integer.');
      expect(
        result.banglaExplanation,
        'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ অবশ্যই পূর্ণসংখ্যা হতে হবে।',
      );
      expect(result.errorLine, 6);
    });
  });

  group('StringChecker - initialization', () {
    test('accepts string initialization within declared size', () {
      final code = _program('  char name[10] = "Jahir";');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts exact string capacity including null character', () {
      final code = _program('  char name[6] = "Jahir";');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts inferred array size from string initializer', () {
      final code = _program('  char name[] = "Jahir";');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts an empty string initializer', () {
      final code = _program('  char name[5] = "";');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects initializer exceeding declared array size', () {
      final code = _program('  char name[5] = "Jahir";');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String initializer exceeds array size.');
      expect(
        result.banglaExplanation,
        'স্ট্রিংটি সংরক্ষণ করতে নাল ক্যারেক্টারসহ কমপক্ষে ৬ ঘর প্রয়োজন, কিন্তু অ্যারের সাইজ ৫।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects string initializer written with single quotes', () {
      final code = _program("  char name[10] = 'Jahir';");

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String literal must use double quotes.');
      expect(
        result.banglaExplanation,
        'স্ট্রিং লেখার জন্য ডাবল কোট ব্যবহার করতে হবে। সিঙ্গেল কোট শুধু একটি ক্যারেক্টারের জন্য ব্যবহৃত হয়।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects unquoted string initializer', () {
      final code = _program('  char name[10] = Jahir;');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Invalid string initializer.');
      expect(
        result.banglaExplanation,
        'স্ট্রিংয়ের মান ডাবল কোটের মধ্যে লিখতে হবে।',
      );
      expect(result.errorLine, 6);
    });
  });

  group('StringChecker - assignment', () {
    test('rejects assigning a string literal to a whole array', () {
      final code = _program('''
  char name[20];
  name = "Jahir";
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(
        result.error,
        'A string array cannot be assigned with = after declaration.',
      );
      expect(
        result.banglaExplanation,
        'ঘোষণার পরে = চিহ্ন দিয়ে পুরো স্ট্রিং অ্যারেতে মান বসানো যায় না। এ ক্ষেত্রে strcpy() ব্যবহার করতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects assigning one string array to another with equals', () {
      final code = _program('''
  char first[20] = "Jahir";
  char second[20];
  second = first;
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(
        result.error,
        'A string array cannot be assigned with = after declaration.',
      );
      expect(
        result.banglaExplanation,
        'ঘোষণার পরে = চিহ্ন দিয়ে পুরো স্ট্রিং অ্যারেতে মান বসানো যায় না। এ ক্ষেত্রে strcpy() ব্যবহার করতে হবে।',
      );
      expect(result.errorLine, 8);
    });
  });

  group('StringChecker - scanf', () {
    test('accepts scanf with percent s and a string variable', () {
      final code = _program('''
  char name[20];
  scanf("%s", name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects ampersand before string array in scanf', () {
      final code = _program('''
  char name[20];
  scanf("%s", &name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Do not use & with a string array.');
      expect(
        result.banglaExplanation,
        'scanf() দিয়ে স্ট্রিং ইনপুট নেওয়ার সময় অ্যারের নামের আগে & চিহ্ন দিতে হয় না।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects undeclared string variable in scanf', () {
      final code = _program('  scanf("%s", name);');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'name নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects non-string variable with percent s in scanf', () {
      final code = _program('''
  int number;
  scanf("%s", number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        '%s ফরম্যাট স্পেসিফায়ারের সঙ্গে একটি char অ্যারে বা স্ট্রিং ভেরিয়েবল ব্যবহার করতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - gets', () {
    test('accepts gets with a declared string variable', () {
      final code = _program('''
  char name[20];
  gets(name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared variable in gets', () {
      final code = _program('  gets(name);');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'name নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects non-string variable in gets', () {
      final code = _program('''
  int number;
  gets(number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        'gets() ফাংশনের আর্গুমেন্ট হিসেবে একটি char অ্যারে বা স্ট্রিং ভেরিয়েবল দিতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - puts', () {
    test('accepts puts with a declared string variable', () {
      final code = _program('''
  char name[20] = "Jahir";
  puts(name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts puts with a string literal', () {
      final code = _program('  puts("Hello");');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared variable in puts', () {
      final code = _program('  puts(name);');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'name নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects non-string variable in puts', () {
      final code = _program('''
  int number;
  puts(number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        'puts() ফাংশনের আর্গুমেন্ট হিসেবে একটি স্ট্রিং ভেরিয়েবল বা ডাবল কোটের স্ট্রিং দিতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - printf percent s', () {
    test('accepts printf percent s with a string variable', () {
      final code = _program('''
  char name[20] = "Jahir";
  printf("%s", name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts printf percent s with a string literal', () {
      final code = _program('  printf("%s", "Jahir");');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('ignores printf without percent s', () {
      final code = _program('  printf("Hello");');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared variable with percent s in printf', () {
      final code = _program('  printf("%s", name);');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'name নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects non-string variable with percent s in printf', () {
      final code = _program('''
  int number = 10;
  printf("%s", number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        '%s ফরম্যাট স্পেসিফায়ারের সঙ্গে একটি স্ট্রিং ভেরিয়েবল বা ডাবল কোটের স্ট্রিং ব্যবহার করতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - strlen', () {
    test('accepts strlen with a declared string variable', () {
      final code = _program('''
  char name[20] = "Jahir";
  int length = strlen(name);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts strlen with a string literal', () {
      final code = _program('  int length = strlen("Jahir");');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared variable in strlen', () {
      final code = _program('  int length = strlen(name);');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'name নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects non-string variable in strlen', () {
      final code = _program('''
  int number = 10;
  int length = strlen(number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        'strlen() ফাংশনের আর্গুমেন্ট হিসেবে একটি স্ট্রিং দিতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - strcpy', () {
    test('accepts strcpy between two declared string variables', () {
      final code = _program('''
  char source[20] = "Jahir";
  char destination[20];
  strcpy(destination, source);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts strcpy with a string literal as source', () {
      final code = _program('''
  char name[20];
  strcpy(name, "Jahir");
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared destination in strcpy', () {
      final code = _program('''
  char source[20] = "Jahir";
  strcpy(destination, source);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'destination নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects undeclared source in strcpy', () {
      final code = _program('''
  char destination[20];
  strcpy(destination, source);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'source নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects strcpy when destination is too small for literal source', () {
      final code = _program('''
  char name[5];
  strcpy(name, "Jahir");
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Source string exceeds destination size.');
      expect(
        result.banglaExplanation,
        'উৎস স্ট্রিংটি সংরক্ষণ করতে নাল ক্যারেক্টারসহ কমপক্ষে ৬ ঘর প্রয়োজন, কিন্তু destination অ্যারের সাইজ ৫।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - strcat', () {
    test('accepts strcat with declared string variables', () {
      final code = _program('''
  char first[30] = "Jahir";
  char second[10] = " Islam";
  strcat(first, second);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts strcat with a string literal source', () {
      final code = _program('''
  char name[20] = "Jahir";
  strcat(name, " Islam");
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared destination in strcat', () {
      final code = _program('''
  char second[10] = " Islam";
  strcat(first, second);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'first নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects undeclared source in strcat', () {
      final code = _program('''
  char first[20] = "Jahir";
  strcat(first, second);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'second নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 7);
    });
  });

  group('StringChecker - strcmp', () {
    test('accepts strcmp with two declared string variables', () {
      final code = _program('''
  char first[20] = "Jahir";
  char second[20] = "Jahir";
  int result = strcmp(first, second);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts strcmp with string literals', () {
      final code = _program(
        '  int result = strcmp("Jahir", "Jahir");',
      );

      final result = StringChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects undeclared variable in strcmp', () {
      final code = _program('''
  char first[20] = "Jahir";
  int result = strcmp(first, second);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'String variable is not declared.');
      expect(
        result.banglaExplanation,
        'second নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects non-string variable in strcmp', () {
      final code = _program('''
  char first[20] = "Jahir";
  int number = 10;
  int result = strcmp(first, number);
''');

      final result = StringChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Argument must be a string variable.');
      expect(
        result.banglaExplanation,
        'strcmp() ফাংশনের উভয় আর্গুমেন্ট অবশ্যই স্ট্রিং হতে হবে।',
      );
      expect(result.errorLine, 8);
    });
  });
}