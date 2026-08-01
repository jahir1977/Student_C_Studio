import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class GotoChecker {
  CompilerResult check(String code) {
    final String cleanedCode = _removeCommentsAndStrings(code);

    final Map<String, int> declaredLabels = <String, int>{};

    final CompilerResult? labelError =
        _collectAndValidateLabels(cleanedCode, declaredLabels);

    if (labelError != null) {
      return labelError;
    }

    final List<_GotoReference> gotoReferences = <_GotoReference>[];

    final CompilerResult? gotoError =
        _collectAndValidateGotoStatements(
      cleanedCode,
      gotoReferences,
    );

    if (gotoError != null) {
      return gotoError;
    }

    for (final _GotoReference reference in gotoReferences) {
      if (!declaredLabels.containsKey(reference.labelName)) {
        return CompilerResult.failure(
          error: 'Undefined label: ${reference.labelName}.',
          explanation:
              '"${reference.labelName}" নামে কোনো label পাওয়া যায়নি।',
          errorLine: reference.lineNumber,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All goto statements and labels are valid.',
    );
  }

  CompilerResult? _collectAndValidateLabels(
    String code,
    Map<String, int> declaredLabels,
  ) {
    final List<String> lines = code.split('\n');

    final RegExp invalidNumberLabelPattern = RegExp(
      r'^\s*([0-9][A-Za-z0-9_]*)\s*:',
    );

    final RegExp validLabelPattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:',
    );

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      final int lineNumber = index + 1;

      final RegExpMatch? invalidMatch =
          invalidNumberLabelPattern.firstMatch(line);

      if (invalidMatch != null) {
        final String invalidLabel = invalidMatch.group(1)!;

        return CompilerResult.failure(
          error: 'Invalid label name: $invalidLabel.',
          explanation:
              'Label-এর নাম সংখ্যা দিয়ে শুরু করা যাবে না।',
          errorLine: lineNumber,
        );
      }

      final RegExpMatch? validMatch =
          validLabelPattern.firstMatch(line);

      if (validMatch == null) {
        continue;
      }

      final String labelName = validMatch.group(1)!;

      // switch-এর case এবং default সাধারণ goto label নয়।
      if (labelName == 'case' || labelName == 'default') {
        continue;
      }

      if (declaredLabels.containsKey(labelName)) {
        return CompilerResult.failure(
          error: 'Duplicate label: $labelName.',
          explanation:
              '"$labelName" label একাধিকবার লেখা হয়েছে। প্রতিটি label-এর নাম আলাদা হতে হবে।',
          errorLine: lineNumber,
        );
      }

      declaredLabels[labelName] = lineNumber;
    }

    return null;
  }

  CompilerResult? _collectAndValidateGotoStatements(
    String code,
    List<_GotoReference> references,
  ) {
    int index = 0;

    while (index < code.length) {
      if (!_isIdentifierStart(code[index])) {
        index++;
        continue;
      }

      final int wordStart = index;

      index++;

      while (index < code.length &&
          _isIdentifierCharacter(code[index])) {
        index++;
      }

      final String word = code.substring(wordStart, index);

      if (word != 'goto') {
        continue;
      }

      final int gotoLine = _lineNumberAt(code, wordStart);

      index = _skipWhitespace(code, index);

      if (index >= code.length || code[index] == ';') {
        return CompilerResult.failure(
          error: 'Label name is missing after goto.',
          explanation:
              'goto-এর পরে একটি বৈধ label-এর নাম লিখতে হবে।',
          errorLine: gotoLine,
        );
      }

      if (_isDigit(code[index])) {
        while (index < code.length &&
            _isIdentifierCharacter(code[index])) {
          index++;
        }

        return CompilerResult.failure(
          error: 'Invalid label name after goto.',
          explanation:
              'Label-এর নাম সংখ্যা দিয়ে শুরু করা যাবে না।',
          errorLine: gotoLine,
        );
      }

      if (!_isIdentifierStart(code[index])) {
        return CompilerResult.failure(
          error: 'Invalid label name after goto.',
          explanation:
              'goto-এর পরে একটি বৈধ label-এর নাম লিখতে হবে।',
          errorLine: gotoLine,
        );
      }

      final int labelStart = index;

      index++;

      while (index < code.length &&
          _isIdentifierCharacter(code[index])) {
        index++;
      }

      final String labelName =
          code.substring(labelStart, index);

      index = _skipWhitespace(code, index);

      if (index >= code.length || code[index] != ';') {
        return CompilerResult.failure(
          error: 'Missing semicolon after goto statement.',
          explanation:
              'goto statement-এর শেষে semicolon (;) দিতে হবে।',
          errorLine: gotoLine,
        );
      }

      references.add(
        _GotoReference(
          labelName: labelName,
          lineNumber: gotoLine,
        ),
      );

      index++;
    }

    return null;
  }

  int _skipWhitespace(String text, int startIndex) {
    int index = startIndex;

    while (index < text.length &&
        RegExp(r'\s').hasMatch(text[index])) {
      index++;
    }

    return index;
  }

  bool _isIdentifierStart(String character) {
    return RegExp(r'[A-Za-z_]').hasMatch(character);
  }

  bool _isIdentifierCharacter(String character) {
    return RegExp(r'[A-Za-z0-9_]').hasMatch(character);
  }

  bool _isDigit(String character) {
    return RegExp(r'[0-9]').hasMatch(character);
  }

  int _lineNumberAt(String text, int position) {
    int lineNumber = 1;

    for (int index = 0;
        index < position && index < text.length;
        index++) {
      if (text[index] == '\n') {
        lineNumber++;
      }
    }

    return lineNumber;
  }

  String _removeCommentsAndStrings(String code) {
    final StringBuffer cleaned = StringBuffer();

    bool inLineComment = false;
    bool inBlockComment = false;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < code.length; index++) {
      final String character = code[index];

      final String nextCharacter =
          index + 1 < code.length ? code[index + 1] : '';

      if (inLineComment) {
        if (character == '\n') {
          inLineComment = false;
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        continue;
      }

      if (inBlockComment) {
        if (character == '*' && nextCharacter == '/') {
          cleaned.write(' ');
          cleaned.write(' ');
          inBlockComment = false;
          index++;
        } else if (character == '\n') {
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        continue;
      }

      if (inDoubleQuote || inSingleQuote) {
        if (character == '\n') {
          cleaned.write('\n');
        } else {
          cleaned.write(' ');
        }

        if (escaped) {
          escaped = false;
          continue;
        }

        if (character == r'\') {
          escaped = true;
          continue;
        }

        if (inDoubleQuote && character == '"') {
          inDoubleQuote = false;
        } else if (inSingleQuote && character == "'") {
          inSingleQuote = false;
        }

        continue;
      }

      if (character == '/' && nextCharacter == '/') {
        cleaned.write(' ');
        cleaned.write(' ');
        inLineComment = true;
        index++;
        continue;
      }

      if (character == '/' && nextCharacter == '*') {
        cleaned.write(' ');
        cleaned.write(' ');
        inBlockComment = true;
        index++;
        continue;
      }

      if (character == '"') {
        cleaned.write(' ');
        inDoubleQuote = true;
        continue;
      }

      if (character == "'") {
        cleaned.write(' ');
        inSingleQuote = true;
        continue;
      }

      cleaned.write(character);
    }

    return cleaned.toString();
  }
  CompilerResult checkContext(
  CompilerContext context,
) {
  return check(context.sanitizedSource);
}
}

class _GotoReference {
  final String labelName;
  final int lineNumber;

  const _GotoReference({
    required this.labelName,
    required this.lineNumber,
  });
}