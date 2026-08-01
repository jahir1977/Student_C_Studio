import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class LoopChecker {
  CompilerResult check(String code) {
    final lines = code.split('\n');

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      final forMatch = RegExp(r'\bfor\s*\(').firstMatch(line);

      if (forMatch == null) {
        continue;
      }

      final lineNumber = lineIndex + 1;
      final openingParenthesisIndex = line.indexOf('(', forMatch.start);

      final extractionResult = _extractForContent(
        lines: lines,
        startLineIndex: lineIndex,
        openingParenthesisIndex: openingParenthesisIndex,
      );

      if (!extractionResult.isComplete) {
        return CompilerResult.failure(
          error: 'Missing closing parenthesis in for loop.',
          explanation:
              'for লুপের শুরুতে "(" দেওয়া হয়েছে, কিন্তু মিলযুক্ত ")" পাওয়া যায়নি।',
          errorLine: lineNumber,
        );
      }

      final content = extractionResult.content;

      if (_hasExtraClosingParenthesis(
        lines: lines,
        closingLineIndex: extractionResult.closingLineIndex,
        closingCharacterIndex: extractionResult.closingCharacterIndex,
      )) {
        return CompilerResult.failure(
          error: 'Extra closing parenthesis in for loop.',
          explanation:
              'for লুপের শেষে প্রয়োজনের চেয়ে অতিরিক্ত ")" ব্যবহার করা হয়েছে।',
          errorLine: lineNumber,
        );
      }

      final parts = _splitTopLevelSections(content);

      if (parts.length != 3) {
        return CompilerResult.failure(
          error: 'A for loop must contain exactly two semicolons.',
          explanation:
              'for লুপের বন্ধনীর ভেতরে initialization, condition এবং update—এই তিনটি অংশ আলাদা করার জন্য ঠিক দুটি সেমিকোলন দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      final initialization = parts[0].trim();
      final condition = parts[1].trim();
      final update = parts[2].trim();

      if (!_isValidInitialization(initialization)) {
        return CompilerResult.failure(
          error: 'Invalid for loop initialization.',
          explanation:
              'for লুপের initialization অংশটি খালি রাখো অথবা একটি বৈধ variable declaration কিংবা assignment ব্যবহার করো।',
          errorLine: lineNumber,
        );
      }

      if (!_isValidCondition(condition)) {
        return CompilerResult.failure(
          error: 'Invalid for loop condition.',
          explanation:
              'for লুপের condition অংশটি খালি রাখো অথবা একটি সম্পূর্ণ ও বৈধ expression ব্যবহার করো।',
          errorLine: lineNumber,
        );
      }

      if (!_isValidUpdate(update)) {
        return CompilerResult.failure(
          error: 'Invalid for loop update.',
          explanation:
              'for লুপের update অংশে বৈধ increment, decrement, assignment অথবা compound assignment ব্যবহার করো।',
          errorLine: lineNumber,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'All for loops are valid.',
    );
  }

  _ForExtractionResult _extractForContent({
    required List<String> lines,
    required int startLineIndex,
    required int openingParenthesisIndex,
  }) {
    final buffer = StringBuffer();

    int parenthesisDepth = 1;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool inBlockComment = false;
    bool escaped = false;

    for (int lineIndex = startLineIndex;
        lineIndex < lines.length;
        lineIndex++) {
      final line = lines[lineIndex];

      final startCharacterIndex =
          lineIndex == startLineIndex ? openingParenthesisIndex + 1 : 0;

      bool inLineComment = false;

      for (int characterIndex = startCharacterIndex;
          characterIndex < line.length;
          characterIndex++) {
        final character = line[characterIndex];
        final nextCharacter = characterIndex + 1 < line.length
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
          buffer.write(character);
          escaped = false;
          continue;
        }

        if ((inDoubleQuote || inSingleQuote) && character == r'\') {
          buffer.write(character);
          escaped = true;
          continue;
        }

        if (!inSingleQuote && character == '"') {
          inDoubleQuote = !inDoubleQuote;
          buffer.write(character);
          continue;
        }

        if (!inDoubleQuote && character == "'") {
          inSingleQuote = !inSingleQuote;
          buffer.write(character);
          continue;
        }

        if (!inDoubleQuote && !inSingleQuote) {
          if (character == '(') {
            parenthesisDepth++;
            buffer.write(character);
            continue;
          }

          if (character == ')') {
            parenthesisDepth--;

            if (parenthesisDepth == 0) {
              return _ForExtractionResult(
                isComplete: true,
                content: buffer.toString(),
                closingLineIndex: lineIndex,
                closingCharacterIndex: characterIndex,
              );
            }

            buffer.write(character);
            continue;
          }
        }

        buffer.write(character);
      }

      if (lineIndex < lines.length - 1) {
        buffer.write('\n');
      }
    }

    return _ForExtractionResult(
      isComplete: false,
      content: buffer.toString(),
      closingLineIndex: startLineIndex,
      closingCharacterIndex: openingParenthesisIndex,
    );
  }

  bool _hasExtraClosingParenthesis({
    required List<String> lines,
    required int closingLineIndex,
    required int closingCharacterIndex,
  }) {
    final closingLine = lines[closingLineIndex];

    for (int index = closingCharacterIndex + 1;
        index < closingLine.length;
        index++) {
      final character = closingLine[index];

      if (character.trim().isEmpty) {
        continue;
      }

      return character == ')';
    }

    return false;
  }

  List<String> _splitTopLevelSections(String content) {
    final parts = <String>[];
    final currentPart = StringBuffer();

    int parenthesisDepth = 0;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < content.length; index++) {
      final character = content[index];

      if (escaped) {
        currentPart.write(character);
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) && character == r'\') {
        currentPart.write(character);
        escaped = true;
        continue;
      }

      if (!inSingleQuote && character == '"') {
        inDoubleQuote = !inDoubleQuote;
        currentPart.write(character);
        continue;
      }

      if (!inDoubleQuote && character == "'") {
        inSingleQuote = !inSingleQuote;
        currentPart.write(character);
        continue;
      }

      if (!inDoubleQuote && !inSingleQuote) {
        if (character == '(') {
          parenthesisDepth++;
          currentPart.write(character);
          continue;
        }

        if (character == ')') {
          parenthesisDepth--;
          currentPart.write(character);
          continue;
        }

        if (character == ';' && parenthesisDepth == 0) {
          parts.add(currentPart.toString());
          currentPart.clear();
          continue;
        }
      }

      currentPart.write(character);
    }

    parts.add(currentPart.toString());

    return parts;
  }

  bool _isValidInitialization(String initialization) {
    if (initialization.isEmpty) {
      return true;
    }

    final declarationMatch = RegExp(
      r'^(int|float|double|char|long|short)\s+'
      r'[A-Za-z_][A-Za-z0-9_]*'
      r'(?:\s*=\s*(.+))?$',
      dotAll: true,
    ).firstMatch(initialization);

    if (declarationMatch != null) {
      final assignedExpression = declarationMatch.group(2);

      if (assignedExpression == null) {
        return true;
      }

      return _isValidExpression(assignedExpression);
    }

    final assignmentMatch = RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*\s*=\s*(.+)$',
      dotAll: true,
    ).firstMatch(initialization);

    if (assignmentMatch == null) {
      return false;
    }

    final rightSide = assignmentMatch.group(1)?.trim() ?? '';

    return _isValidExpression(rightSide);
  }

  bool _isValidCondition(String condition) {
    if (condition.isEmpty) {
      return true;
    }

    return _isValidExpression(condition);
  }

  bool _isValidUpdate(String update) {
    if (update.isEmpty) {
      return true;
    }

    final incrementOrDecrement = RegExp(
      r'^(?:'
      r'[A-Za-z_][A-Za-z0-9_]*\s*(?:\+\+|--)'
      r'|'
      r'(?:\+\+|--)\s*[A-Za-z_][A-Za-z0-9_]*'
      r')$',
    );

    if (incrementOrDecrement.hasMatch(update)) {
      return true;
    }

    final assignmentMatch = RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*\s*'
      r'(=|\+=|-=|\*=|/=|%=)\s*'
      r'(.+)$',
      dotAll: true,
    ).firstMatch(update);

    if (assignmentMatch == null) {
      return false;
    }

    final rightSide = assignmentMatch.group(2)?.trim() ?? '';

    return _isValidExpression(rightSide);
  }

  bool _isValidExpression(String expression) {
    final value = expression.trim();

    if (value.isEmpty) {
      return false;
    }

    if (!_hasBalancedParentheses(value)) {
      return false;
    }

    if (!_hasValidTernaryStructure(value)) {
      return false;
    }

    if (RegExp(r'^(?:\*|/|%|<|>|<=|>=|==|!=|&&|\|\|)').hasMatch(value)) {
      return false;
    }

    if (RegExp(
      r'(?:\+|-|\*|/|%|<|>|<=|>=|==|!=|&&|\|\||=)\s*$',
    ).hasMatch(value)) {
      return false;
    }

    if (RegExp(r'^\s*(?:<=|>=|==|!=|&&|\|\|)').hasMatch(value)) {
      return false;
    }

    if (RegExp(r'^\s*[+\-*/%]\s*$').hasMatch(value)) {
      return false;
    }

    if (_containsInvalidConsecutiveOperators(value)) {
      return false;
    }

    return true;
  }

  bool _hasBalancedParentheses(String expression) {
    int depth = 0;
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < expression.length; index++) {
      final character = expression[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) && character == r'\') {
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

      if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;

        if (depth < 0) {
          return false;
        }
      }
    }

    return depth == 0;
  }

  bool _hasValidTernaryStructure(String expression) {
    int questionMarkCount = 0;
    int colonCount = 0;

    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int index = 0; index < expression.length; index++) {
      final character = expression[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((inDoubleQuote || inSingleQuote) && character == r'\') {
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

      if (character == '?') {
        questionMarkCount++;
      } else if (character == ':') {
        colonCount++;
      }
    }

    if (questionMarkCount != colonCount) {
      return false;
    }

    if (questionMarkCount > 0) {
      if (RegExp(r'\?\s*:').hasMatch(expression)) {
        return false;
      }

      if (RegExp(r'\?\s*$').hasMatch(expression)) {
        return false;
      }

      if (RegExp(r':\s*$').hasMatch(expression)) {
        return false;
      }
    }

    return true;
  }

  bool _containsInvalidConsecutiveOperators(String expression) {
    final compact = expression.replaceAll(RegExp(r'\s+'), '');

    const validDoubleOperators = <String>{
      '++',
      '--',
      '+=',
      '-=',
      '*=',
      '/=',
      '%=',
      '<=',
      '>=',
      '==',
      '!=',
      '&&',
      '||',
    };

    const operatorCharacters = '+-*/%<>=!&|';

    for (int index = 0; index < compact.length - 1; index++) {
      final first = compact[index];
      final second = compact[index + 1];

      if (!operatorCharacters.contains(first) ||
          !operatorCharacters.contains(second)) {
        continue;
      }

      final pair = '$first$second';

      if (validDoubleOperators.contains(pair)) {
        continue;
      }

      if ((first == '+' || first == '-') &&
          (second == '+' || second == '-') &&
          index == 0) {
        continue;
      }

      return true;
    }

    return false;
  }
  CompilerResult checkContext(
  CompilerContext context,
  ) {
  return check(context.sanitizedSource);
}
}

class _ForExtractionResult {
  final bool isComplete;
  final String content;
  final int closingLineIndex;
  final int closingCharacterIndex;

  const _ForExtractionResult({
    required this.isComplete,
    required this.content,
    required this.closingLineIndex,
    required this.closingCharacterIndex,
  });
  
}