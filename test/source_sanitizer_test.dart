import 'package:flutter_test/flutter_test.dart';
import 'package:student_c_studio/services/source_sanitizer.dart';

void main() {
  test('keeps source unchanged when there are no comments', () {
    const source = '''
int main()
{
  return 0;
}
''';

    final result = SourceSanitizer.sanitize(source);

    expect(result, source);
  });
  test('removes single-line comments', () {
  const source = '''
int main()
{
  int a = 10; // this is a comment
  return 0;
}
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result.contains('//'), isFalse);
});
test('removes block comments', () {
  const source = '''
int main()
{
  /* comment */
  return 0;
}
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result.contains('comment'), isFalse);
});
test('preserves line count inside block comments', () {
  const source = '''
int main()
{
/*
line1
line2
*/
return 0;
}
''';

  final result = SourceSanitizer.sanitize(source);

  expect(
    '\n'.allMatches(result).length,
    '\n'.allMatches(source).length,
  );
});
test('does not remove // inside string literal', () {
  const source = '''
printf("https://example.com");
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result, source);
});
test('does not remove /* */ inside string literal', () {
  const source = '''
printf("Use /* text */ here");
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result, source);
});
test('does not treat character literal as comment', () {
  const source = '''
char c='/';
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result, source);
});
test('supports escaped quotes', () {
  const source = r'''
printf("He said \"Hello\"");
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result, source);
});
test('handles string and comment together', () {
  const source = '''
printf("https://google.com"); // comment
''';

  final result = SourceSanitizer.sanitize(source);

  expect(result.contains('// comment'), isFalse);

  expect(
    result.contains('https://google.com'),
    isTrue,
  );
});

}