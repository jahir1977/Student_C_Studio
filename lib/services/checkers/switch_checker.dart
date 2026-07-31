import '../../models/compiler_result.dart';

class SwitchChecker {
  CompilerResult check(String code) {
    final List<String> lines = code.split('\n');
    final List<_SwitchBlock> switchBlocks = <_SwitchBlock>[];

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final String trimmedLine = lines[lineIndex].trim();

      if (!RegExp(r'^switch\b').hasMatch(trimmedLine)) {
        continue;
      }

      final int switchLineNumber = lineIndex + 1;
      final RegExpMatch switchMatch =
          RegExp(r'^switch\b').firstMatch(trimmedLine)!;

      final String afterSwitch =
          trimmedLine.substring(switchMatch.end).trimLeft();

      if (!afterSwitch.startsWith('(')) {
        return CompilerResult.failure(
          error: 'Missing opening parenthesis in switch statement.',
          explanation:
              'switch-এর expression শুরু করার আগে "(" দিতে হবে।',
          errorLine: switchLineNumber,
        );
      }

      final int openingParenthesisIndex =
          lines[lineIndex].indexOf('(', lines[lineIndex].indexOf('switch'));

      final _ParenthesisResult parenthesisResult =
          _extractSwitchExpression(
        lines: lines,
        startLineIndex: lineIndex,
        openingParenthesisIndex: openingParenthesisIndex,
      );

      if (!parenthesisResult.isComplete) {
        return CompilerResult.failure(
          error: 'Missing closing parenthesis in switch statement.',
          explanation:
              'switch-এর expression শেষ করার পরে ")" দিতে হবে।',
          errorLine: switchLineNumber,
        );
      }

      if (parenthesisResult.expression.trim().isEmpty) {
        return CompilerResult.failure(
          error: 'Switch expression cannot be empty.',
          explanation:
              'switch-এর বন্ধনীর ভেতরে একটি ভেরিয়েবল বা expression লিখতে হবে।',
          errorLine: switchLineNumber,
        );
      }

      final _BraceLocation? openingBrace =
          _findOpeningBraceAfterSwitch(
        lines: lines,
        closingParenthesisLineIndex:
            parenthesisResult.closingLineIndex,
        closingParenthesisCharacterIndex:
            parenthesisResult.closingCharacterIndex,
      );

      if (openingBrace == null) {
        return CompilerResult.failure(
          error: 'Missing opening brace after switch statement.',
          explanation:
              'switch statement-এর caseগুলো লেখার আগে "{" দিতে হবে।',
          errorLine: switchLineNumber,
        );
      }

      final _BraceLocation? closingBrace = _findClosingBrace(
        lines: lines,
        openingBrace: openingBrace,
      );

      if (closingBrace == null) {
        continue;
      }

      final _SwitchBlock switchBlock = _SwitchBlock(
        switchLineIndex: lineIndex,
        openingBraceLineIndex: openingBrace.lineIndex,
        openingBraceCharacterIndex: openingBrace.characterIndex,
        closingBraceLineIndex: closingBrace.lineIndex,
        closingBraceCharacterIndex: closingBrace.characterIndex,
      );

      final CompilerResult blockResult =
          _validateSwitchBlock(lines, switchBlock);

      if (!blockResult.isSuccess) {
        return blockResult;
      }

      switchBlocks.add(switchBlock);
    }

    final CompilerResult outsideLabelResult =
        _checkLabelsOutsideSwitch(
      lines: lines,
      switchBlocks: switchBlocks,
    );

    if (!outsideLabelResult.isSuccess) {
      return outsideLabelResult;
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All switch statements are valid.',
    );
  }

  CompilerResult _validateSwitchBlock(
    List<String> lines,
    _SwitchBlock block,
  ) {
    final Set<String> caseValues = <String>{};
    bool defaultFound = false;

    for (
      int lineIndex = block.openingBraceLineIndex;
      lineIndex <= block.closingBraceLineIndex;
      lineIndex++
    ) {
      final String line = _removeLineComment(lines[lineIndex]).trim();

      if (line.isEmpty) {
        continue;
      }

      if (RegExp(r'^case\b').hasMatch(line) || line == 'case:') {
        final CompilerResult result = _validateCaseLine(
          line: line,
          lineNumber: lineIndex + 1,
          caseValues: caseValues,
        );

        if (!result.isSuccess) {
          return result;
        }
      }

      if (RegExp(r'^default\b').hasMatch(line)) {
        if (!RegExp(r'^default\s*:').hasMatch(line)) {
          return CompilerResult.failure(
            error: 'Missing colon after default.',
            explanation: 'default-এর পরে ":" দিতে হবে।',
            errorLine: lineIndex + 1,
          );
        }

        if (defaultFound) {
          return CompilerResult.failure(
            error: 'Duplicate default label.',
            explanation:
                'একটি switch statement-এর মধ্যে একটির বেশি default ব্যবহার করা যাবে না।',
            errorLine: lineIndex + 1,
          );
        }

        defaultFound = true;
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Switch block is valid.',
    );
  }

  CompilerResult _validateCaseLine({
    required String line,
    required int lineNumber,
    required Set<String> caseValues,
  }) {
    final String afterCase =
        line.substring('case'.length).trimLeft();

    if (afterCase.isEmpty || afterCase.startsWith(':')) {
      return CompilerResult.failure(
        error: 'Case value cannot be empty.',
        explanation: 'case-এর পরে একটি নির্দিষ্ট মান লিখতে হবে।',
        errorLine: lineNumber,
      );
    }

    final int colonIndex = _findCaseColon(afterCase);

    if (colonIndex == -1) {
      return CompilerResult.failure(
        error: 'Missing colon after case value.',
        explanation: 'case-এর মানের পরে ":" দিতে হবে।',
        errorLine: lineNumber,
      );
    }

    final String caseValue =
        afterCase.substring(0, colonIndex).trim();

    if (caseValue.isEmpty) {
      return CompilerResult.failure(
        error: 'Case value cannot be empty.',
        explanation: 'case-এর পরে একটি নির্দিষ্ট মান লিখতে হবে।',
        errorLine: lineNumber,
      );
    }

    final String normalizedValue =
        caseValue.replaceAll(RegExp(r'\s+'), '');

    if (caseValues.contains(normalizedValue)) {
      return CompilerResult.failure(
        error: 'Duplicate case value: $caseValue.',
        explanation:
            'একই switch statement-এর মধ্যে একই case value একাধিকবার ব্যবহার করা যাবে না।',
        errorLine: lineNumber,
      );
    }

    caseValues.add(normalizedValue);

    return CompilerResult.success(
      output: '',
      explanation: 'Case label is valid.',
    );
  }

  CompilerResult _checkLabelsOutsideSwitch({
    required List<String> lines,
    required List<_SwitchBlock> switchBlocks,
  }) {
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final String line =
          _removeLineComment(lines[lineIndex]).trim();

      if (line.isEmpty) {
        continue;
      }

      final bool insideSwitch = switchBlocks.any(
        (_SwitchBlock block) =>
            lineIndex >= block.openingBraceLineIndex &&
            lineIndex <= block.closingBraceLineIndex,
      );

      if (insideSwitch) {
        continue;
      }

      if (RegExp(r'^case\b').hasMatch(line) || line == 'case:') {
        return CompilerResult.failure(
          error: 'Case label found outside switch statement.',
          explanation:
              'case শুধু switch statement-এর ভেতরে ব্যবহার করা যায়।',
          errorLine: lineIndex + 1,
        );
      }

      if (RegExp(r'^default\b').hasMatch(line)) {
        return CompilerResult.failure(
          error: 'Default label found outside switch statement.',
          explanation:
              'default শুধু switch statement-এর ভেতরে ব্যবহার করা যায়।',
          errorLine: lineIndex + 1,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'No labels found outside switch.',
    );
  }

  _ParenthesisResult _extractSwitchExpression({
    required List<String> lines,
    required int startLineIndex,
    required int openingParenthesisIndex,
  }) {
    final StringBuffer expression = StringBuffer();

    int depth = 1;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool inBlockComment = false;
    bool escaped = false;

    for (
      int lineIndex = startLineIndex;
      lineIndex < lines.length;
      lineIndex++
    ) {
      final String line = lines[lineIndex];

      final int startCharacterIndex = lineIndex == startLineIndex
          ? openingParenthesisIndex + 1
          : 0;

      bool inLineComment = false;

      for (
        int characterIndex = startCharacterIndex;
        characterIndex < line.length;
        characterIndex++
      ) {
        final String character = line[characterIndex];
        final String nextCharacter =
            characterIndex + 1 < line.length
                ? line[characterIndex + 1]
                : '';

        if (inLineComment) {
          break;
        }

        if (inBlockComment) {
          if (character == '*' && nextCharacter == '/') {
            inBlockComment = false;
            characterIndex++;
          }

          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '/' && nextCharacter == '/') {
            inLineComment = true;
            break;
          }

          if (character == '/' && nextCharacter == '*') {
            inBlockComment = true;
            characterIndex++;
            continue;
          }
        }

        if (escaped) {
          expression.write(character);
          escaped = false;
          continue;
        }

        if ((inDoubleQuote || inSingleQuote) &&
            character == r'\') {
          expression.write(character);
          escaped = true;
          continue;
        }

        if (!inSingleQuote && character == '"') {
          inDoubleQuote = !inDoubleQuote;
          expression.write(character);
          continue;
        }

        if (!inDoubleQuote && character == "'") {
          inSingleQuote = !inSingleQuote;
          expression.write(character);
          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '(') {
            depth++;
            expression.write(character);
            continue;
          }

          if (character == ')') {
            depth--;

            if (depth == 0) {
              return _ParenthesisResult(
                isComplete: true,
                expression: expression.toString(),
                closingLineIndex: lineIndex,
                closingCharacterIndex: characterIndex,
              );
            }

            expression.write(character);
            continue;
          }
        }

        expression.write(character);
      }

      if (lineIndex < lines.length - 1) {
        expression.write('\n');
      }
    }

    return _ParenthesisResult(
      isComplete: false,
      expression: expression.toString(),
      closingLineIndex: startLineIndex,
      closingCharacterIndex: openingParenthesisIndex,
    );
  }

  _BraceLocation? _findOpeningBraceAfterSwitch({
    required List<String> lines,
    required int closingParenthesisLineIndex,
    required int closingParenthesisCharacterIndex,
  }) {
    final String closingLine =
        lines[closingParenthesisLineIndex];

    final String remainingText = closingLine.substring(
      closingParenthesisCharacterIndex + 1,
    );

    final int sameLineBraceIndex = remainingText.indexOf('{');

    if (sameLineBraceIndex != -1) {
      return _BraceLocation(
        lineIndex: closingParenthesisLineIndex,
        characterIndex: closingParenthesisCharacterIndex +
            1 +
            sameLineBraceIndex,
      );
    }

    if (_removeLineComment(remainingText).trim().isNotEmpty) {
      return null;
    }

    for (
      int lineIndex = closingParenthesisLineIndex + 1;
      lineIndex < lines.length;
      lineIndex++
    ) {
      final String cleanedLine =
          _removeLineComment(lines[lineIndex]).trim();

      if (cleanedLine.isEmpty) {
        continue;
      }

      if (!cleanedLine.startsWith('{')) {
        return null;
      }

      return _BraceLocation(
        lineIndex: lineIndex,
        characterIndex: lines[lineIndex].indexOf('{'),
      );
    }

    return null;
  }

  _BraceLocation? _findClosingBrace({
    required List<String> lines,
    required _BraceLocation openingBrace,
  }) {
    int depth = 0;

    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool inBlockComment = false;
    bool escaped = false;

    for (
      int lineIndex = openingBrace.lineIndex;
      lineIndex < lines.length;
      lineIndex++
    ) {
      final String line = lines[lineIndex];

      final int startCharacterIndex =
          lineIndex == openingBrace.lineIndex
              ? openingBrace.characterIndex
              : 0;

      bool inLineComment = false;

      for (
        int characterIndex = startCharacterIndex;
        characterIndex < line.length;
        characterIndex++
      ) {
        final String character = line[characterIndex];
        final String nextCharacter =
            characterIndex + 1 < line.length
                ? line[characterIndex + 1]
                : '';

        if (inLineComment) {
          break;
        }

        if (inBlockComment) {
          if (character == '*' && nextCharacter == '/') {
            inBlockComment = false;
            characterIndex++;
          }

          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '/' && nextCharacter == '/') {
            inLineComment = true;
            break;
          }

          if (character == '/' && nextCharacter == '*') {
            inBlockComment = true;
            characterIndex++;
            continue;
          }
        }

        if (escaped) {
          escaped = false;
          continue;
        }

        if ((inDoubleQuote || inSingleQuote) &&
            character == r'\') {
          escaped = true;
          continue;
        }

        if (!inSingleQuote && character == '"') {
          inDoubleQuote = !inDoubleQuote;
          continue;
        }

        if (!inDoubleQuote && character == "'") {
          inSingleQuote = !inSingleQuote;
          continue;
        }

        if (inDoubleQuote || inSingleQuote) {
          continue;
        }

        if (character == '{') {
          depth++;
          continue;
        }

        if (character == '}') {
          depth--;

          if (depth == 0) {
            return _BraceLocation(
              lineIndex: lineIndex,
              characterIndex: characterIndex,
            );
          }
        }
      }
    }

    return null;
  }

  int _findCaseColon(String text) {
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < text.length; index++) {
      final String character = text[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) &&
          character == r'\') {
        escaped = true;
        continue;
      }

      if (!inSingleQuote && character == '"') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (!inDoubleQuote && character == "'") {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (!inDoubleQuote &&
          !inSingleQuote &&
          character == ':') {
        return index;
      }
    }

    return -1;
  }

  String _removeLineComment(String line) {
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < line.length - 1; index++) {
      final String character = line[index];
      final String nextCharacter = line[index + 1];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) &&
          character == r'\') {
        escaped = true;
        continue;
      }

      if (!inSingleQuote && character == '"') {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (!inDoubleQuote && character == "'") {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (!inDoubleQuote &&
          !inSingleQuote &&
          character == '/' &&
          nextCharacter == '/') {
        return line.substring(0, index);
      }
    }

    return line;
  }
}

class _ParenthesisResult {
  final bool isComplete;
  final String expression;
  final int closingLineIndex;
  final int closingCharacterIndex;

  const _ParenthesisResult({
    required this.isComplete,
    required this.expression,
    required this.closingLineIndex,
    required this.closingCharacterIndex,
  });
}

class _BraceLocation {
  final int lineIndex;
  final int characterIndex;

  const _BraceLocation({
    required this.lineIndex,
    required this.characterIndex,
  });
}

class _SwitchBlock {
  final int switchLineIndex;
  final int openingBraceLineIndex;
  final int openingBraceCharacterIndex;
  final int closingBraceLineIndex;
  final int closingBraceCharacterIndex;

  const _SwitchBlock({
    required this.switchLineIndex,
    required this.openingBraceLineIndex,
    required this.openingBraceCharacterIndex,
    required this.closingBraceLineIndex,
    required this.closingBraceCharacterIndex,
  });
}