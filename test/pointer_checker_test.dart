import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/checkers/pointer_checker.dart';

String _program(String body) {
  return '''
#include<stdio.h>

int main()
{
$body
  return 0;
}
''';
}

void main() {
  group('PointerChecker - pointer declaration', () {
    test('accepts a valid int pointer declaration', () {
      final code = _program('  int *ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts a valid float pointer declaration', () {
      final code = _program('  float *ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts a valid char pointer declaration', () {
      final code = _program('  char *ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts pointer declaration with space after star', () {
      final code = _program('  int * ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts pointer declaration with star attached to type', () {
      final code = _program('  int* ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts multiple pointer declarations', () {
      final code = _program('''
  int *first;
  float *second;
  char *third;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects pointer declaration without variable name', () {
      final code = _program('  int *;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer variable name is missing.');
      expect(
        result.banglaExplanation,
        'পয়েন্টার ঘোষণার সময় * চিহ্নের পরে একটি বৈধ ভেরিয়েবলের নাম দিতে হবে।',
      );
      expect(result.errorLine, 5);
    });

    test('rejects pointer declaration with invalid identifier', () {
      final code = _program('  int *2ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Invalid pointer variable name.');
      expect(
        result.banglaExplanation,
        'পয়েন্টার ভেরিয়েবলের নাম সংখ্যা দিয়ে শুরু করা যায় না।',
      );
      expect(result.errorLine, 5);
    });

    test('rejects double pointer in HSC-level scope', () {
      final code = _program('  int **ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(
        result.error,
        'Multiple-level pointer is not supported.',
      );
      expect(
        result.banglaExplanation,
        'Student C Studio-এর বর্তমান HSC পর্যায়ে শুধু এক স্তরের পয়েন্টার সমর্থিত। একটি * চিহ্ন ব্যবহার করো।',
      );
      expect(result.errorLine, 5);
    });
  });

  group('PointerChecker - address initialization', () {
    test('accepts pointer initialized with address of matching variable', () {
      final code = _program('''
  int number = 10;
  int *ptr = &number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts pointer initialized with NULL', () {
      final code = _program('  int *ptr = NULL;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects address of undeclared variable', () {
      final code = _program('  int *ptr = &number;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Addressed variable is not declared.');
      expect(
        result.banglaExplanation,
        'number ভেরিয়েবলটির ঠিকানা নেওয়ার আগে ভেরিয়েবলটি ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 5);
    });

    test('rejects pointer initialized without address operator', () {
      final code = _program('''
  int number = 10;
  int *ptr = number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer must store an address.');
      expect(
        result.banglaExplanation,
        'পয়েন্টার ভেরিয়েবলে সাধারণ মান রাখা যায় না। ভেরিয়েবলের ঠিকানা দিতে & চিহ্ন ব্যবহার করো।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects pointer initialized with address of a literal', () {
      final code = _program('  int *ptr = &10;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Cannot take address of a literal value.');
      expect(
        result.banglaExplanation,
        'সরাসরি কোনো সংখ্যার ঠিকানা নেওয়া যায় না। & চিহ্নের পরে ঘোষিত ভেরিয়েবলের নাম দিতে হবে।',
      );
      expect(result.errorLine, 5);
    });

    test('rejects int pointer initialized with float variable address', () {
      final code = _program('''
  float number = 10.5;
  int *ptr = &number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer type does not match variable type.');
      expect(
        result.banglaExplanation,
        'int পয়েন্টারে float ভেরিয়েবলের ঠিকানা রাখা যায় না। পয়েন্টার ও ভেরিয়েবলের ডেটা টাইপ একই হতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('accepts char pointer initialized with char variable address', () {
      final code = _program('''
  char grade = 'A';
  char *ptr = &grade;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });
  });

  group('PointerChecker - pointer assignment', () {
    test('accepts assigning matching variable address after declaration', () {
      final code = _program('''
  int number = 10;
  int *ptr;
  ptr = &number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts assigning NULL after declaration', () {
      final code = _program('''
  int *ptr;
  ptr = NULL;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects assigning ordinary value to pointer', () {
      final code = _program('''
  int *ptr;
  ptr = 10;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer must store an address.');
      expect(
        result.banglaExplanation,
        'পয়েন্টার ভেরিয়েবলে সাধারণ মান রাখা যায় না। ভেরিয়েবলের ঠিকানা অথবা NULL দিতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects assigning address to undeclared pointer', () {
      final code = _program('''
  int number = 10;
  ptr = &number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer variable is not declared.');
      expect(
        result.banglaExplanation,
        'ptr পয়েন্টার ভেরিয়েবলটি ব্যবহারের আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects assigning mismatched address after declaration', () {
      final code = _program('''
  float number = 10.5;
  int *ptr;
  ptr = &number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer type does not match variable type.');
      expect(
        result.banglaExplanation,
        'int পয়েন্টারে float ভেরিয়েবলের ঠিকানা রাখা যায় না। পয়েন্টার ও ভেরিয়েবলের ডেটা টাইপ একই হতে হবে।',
      );
      expect(result.errorLine, 7);
    });

    test('accepts assigning one compatible pointer to another', () {
      final code = _program('''
  int number = 10;
  int *first = &number;
  int *second;
  second = first;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects assigning incompatible pointer types', () {
      final code = _program('''
  int number = 10;
  int *first = &number;
  float *second;
  second = first;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer types do not match.');
      expect(
        result.banglaExplanation,
        'float পয়েন্টারে int পয়েন্টারের ঠিকানা রাখা যায় না। উভয় পয়েন্টারের ডেটা টাইপ একই হতে হবে।',
      );
      expect(result.errorLine, 8);
    });
  });

  group('PointerChecker - dereference operator', () {
    test('accepts reading value through a declared pointer', () {
      final code = _program('''
  int number = 10;
  int *ptr = &number;
  int value = *ptr;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts assigning value through a declared pointer', () {
      final code = _program('''
  int number = 10;
  int *ptr = &number;
  *ptr = 20;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects dereferencing undeclared pointer', () {
      final code = _program('  int value = *ptr;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer variable is not declared.');
      expect(
        result.banglaExplanation,
        'ptr পয়েন্টার ভেরিয়েবলটি dereference করার আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 5);
    });

    test('rejects dereferencing ordinary variable', () {
      final code = _program('''
  int number = 10;
  int value = *number;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Only a pointer can be dereferenced.');
      expect(
        result.banglaExplanation,
        'number একটি সাধারণ ভেরিয়েবল। * চিহ্ন দিয়ে শুধু পয়েন্টার ভেরিয়েবলের সংরক্ষিত ঠিকানার মান পাওয়া যায়।',
      );
      expect(result.errorLine, 6);
    });

    test('rejects assigning through undeclared pointer', () {
      final code = _program('  *ptr = 20;');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer variable is not declared.');
      expect(
        result.banglaExplanation,
        'ptr পয়েন্টার ভেরিয়েবলটি dereference করার আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 5);
    });
  });

  group('PointerChecker - address operator', () {
    test('accepts address operator with declared variable', () {
      final code = _program('''
  int number = 10;
  printf("%p", &number);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects address operator with undeclared variable', () {
      final code = _program('  printf("%p", &number);');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Addressed variable is not declared.');
      expect(
        result.banglaExplanation,
        'number ভেরিয়েবলটির ঠিকানা নেওয়ার আগে ভেরিয়েবলটি ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 5);
    });
  });

  group('PointerChecker - scanf with pointer', () {
    test('accepts scanf using address of ordinary variable', () {
      final code = _program('''
  int number;
  scanf("%d", &number);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('accepts scanf using an int pointer directly', () {
      final code = _program('''
  int number;
  int *ptr = &number;
  scanf("%d", ptr);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('rejects ampersand before pointer in scanf', () {
      final code = _program('''
  int number;
  int *ptr = &number;
  scanf("%d", &ptr);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Do not use & before a pointer in scanf.');
      expect(
        result.banglaExplanation,
        'ptr নিজেই একটি ঠিকানা সংরক্ষণ করে। scanf() ফাংশনে পয়েন্টার ব্যবহার করলে তার আগে অতিরিক্ত & চিহ্ন দিতে হবে না।',
      );
      expect(result.errorLine, 7);
    });

    test('rejects undeclared pointer argument in scanf', () {
      final code = _program('  scanf("%d", ptr);');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Pointer variable is not declared.');
      expect(
        result.banglaExplanation,
        'ptr পয়েন্টার ভেরিয়েবলটি ব্যবহারের আগে ঘোষণা করতে হবে।',
      );
      expect(result.errorLine, 5);
    });
  });

  group('PointerChecker - valid non-pointer code', () {
    test('ignores normal arithmetic multiplication', () {
      final code = _program('''
  int a = 5;
  int b = 10;
  int result = a * b;
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('ignores scalar char declaration', () {
      final code = _program("  char grade = 'A';");

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('ignores logical AND operator', () {
      final code = _program('''
  int a = 1;
  int b = 1;
  if(a == 1 && b == 1)
  {
    printf("True");
  }
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('ignores ordinary scanf validation handled by other checkers', () {
      final code = _program('''
  float number;
  scanf("%f", &number);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });
  });

  group('PointerChecker - scanf multiple arguments', () {
    test('accepts multiple ordinary variables with address operators', () {
      final code = _program('''
  int a = 0;
  int b = 0;
  scanf("%d %d", &a, &b);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, true);
    });

    test('detects undeclared variable among multiple scanf arguments', () {
      final code = _program('''
  int a = 0;
  scanf("%d %d", &a, &b);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Addressed variable is not declared.');
      expect(result.errorLine, 6);
    });

    test('detects ampersand before pointer among multiple scanf arguments', () {
      final code = _program('''
  int a = 0;
  int *ptr;
  scanf("%d %d", &a, &ptr);
''');

      final result = PointerChecker.check(code);

      expect(result.isSuccess, false);
      expect(result.error, 'Do not use & before a pointer in scanf.');
      expect(result.errorLine, 7);
    });
  });
}
