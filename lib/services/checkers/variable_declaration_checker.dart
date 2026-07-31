class VariableCheckResult {
  final bool isValid;
  final String error;
  final String explanation;
  final int? line;

  const VariableCheckResult._({
    required this.isValid,
    required this.error,
    required this.explanation,
    this.line,
  });

  const VariableCheckResult.valid()
      : this._(
          isValid: true,
          error: '',
          explanation: '',
        );

  const VariableCheckResult.invalid({
    required String error,
    required String explanation,
    required int line,
  }) : this._(
          isValid: false,
          error: error,
          explanation: explanation,
          line: line,
        );
}

class VariableDeclarationChecker {
  const VariableDeclarationChecker._();

  static const Set<String> _typeWords = <String>{
    'char',
    'double',
    'float',
    'int',
    'long',
    'short',
    'signed',
    'unsigned',
  };

  static const Set<String> _reservedWords = <String>{
    'auto',
    'break',
    'case',
    'char',
    'const',
    'continue',
    'default',
    'do',
    'double',
    'else',
    'enum',
    'extern',
    'float',
    'for',
    'goto',
    'if',
    'inline',
    'int',
    'long',
    'register',
    'restrict',
    'return',
    'short',
    'signed',
    'sizeof',
    'static',
    'struct',
    'switch',
    'typedef',
    'union',
    'unsigned',
    'void',
    'volatile',
    'while',
  };

  static VariableCheckResult check(String code) {
    final List<String> lines = code.split('\n');

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index].trim();

      if (!_looksLikeVariableDeclaration(line)) {
        continue;
      }

      final VariableCheckResult? error =
          _checkDeclarationLine(line, index + 1);

      if (error != null) {
        return error;
      }
    }

    return const VariableCheckResult.valid();
  }

  static bool _looksLikeVariableDeclaration(String line) {
    if (line.isEmpty ||
        line.startsWith('#') ||
        line.startsWith('//') ||
        line.startsWith('/*')) {
      return false;
    }

    // Function declaration/definition এই checker-এর কাজ নয়।
    if (line.contains('(')) {
      return false;
    }

    final RegExp startPattern = RegExp(
      r'^(?:(?:const|volatile|static|extern|register|auto)\s+)*'
      r'(?:signed\s+|unsigned\s+)?'
      r'(?:short\s+|long\s+|long\s+long\s+)?'
      r'(?:char|int|float|double)\b',
    );

    return startPattern.hasMatch(line);
  }

  static VariableCheckResult? _checkDeclarationLine(
    String line,
    int lineNumber,
  ) {
    if (!line.endsWith(';')) {
      // Missing semicolon checker এটি আলাদাভাবে ধরবে।
      return null;
    }

    final String withoutSemicolon =
        line.substring(0, line.length - 1).trim();

    final RegExp prefixPattern = RegExp(
      r'^(?:(?:const|volatile|static|extern|register|auto)\s+)*'
      r'(?:(?:signed|unsigned)\s+)?'
      r'(?:(?:short|long|long\s+long)\s+)?'
      r'(char|int|float|double)\b\s*(.*)$',
    );

    final RegExpMatch? prefixMatch =
        prefixPattern.firstMatch(withoutSemicolon);

    if (prefixMatch == null) {
      return null;
    }

    final String declarations = (prefixMatch.group(2) ?? '').trim();

    if (declarations.isEmpty) {
      return VariableCheckResult.invalid(
        error: 'variable name expected',
        explanation: 'ডেটা টাইপের পরে একটি বৈধ চলকের নাম লিখতে হবে।',
        line: lineNumber,
      );
    }

    final List<String> items = _splitByTopLevelComma(declarations);

    if (items.any((String item) => item.trim().isEmpty)) {
      return VariableCheckResult.invalid(
        error: 'invalid variable declaration',
        explanation:
            'চলক ঘোষণায় অতিরিক্ত বা পাশাপাশি কমা ব্যবহার করা হয়েছে।',
        line: lineNumber,
      );
    }

    for (final String rawItem in items) {
      final String item = rawItem.trim();
      final int equalsIndex = _findTopLevelEquals(item);

      final String leftSide = equalsIndex == -1
          ? item
          : item.substring(0, equalsIndex).trim();

      final String initializer = equalsIndex == -1
          ? ''
          : item.substring(equalsIndex + 1).trim();

      if (equalsIndex != -1 && initializer.isEmpty) {
        return VariableCheckResult.invalid(
          error: "expression expected after '='",
          explanation:
              "'=' চিহ্নের পরে একটি মান, চলক বা বৈধ expression লিখতে হবে।",
          line: lineNumber,
        );
      }

      final String identifier = _extractIdentifier(leftSide);

      if (identifier.isEmpty) {
        return VariableCheckResult.invalid(
          error: 'variable name expected',
          explanation: 'ডেটা টাইপের পরে চলকের নাম পাওয়া যায়নি।',
          line: lineNumber,
        );
      }

      if (!_isValidIdentifier(identifier)) {
        return VariableCheckResult.invalid(
          error: "invalid variable name '$identifier'",
          explanation:
              "চলকের নাম অক্ষর বা underscore দিয়ে শুরু হবে; পরে অক্ষর, সংখ্যা বা underscore থাকতে পারে।",
          line: lineNumber,
        );
      }

      if (_reservedWords.contains(identifier) ||
          _typeWords.contains(identifier)) {
        return VariableCheckResult.invalid(
          error: "reserved word '$identifier' cannot be a variable name",
          explanation:
              "'$identifier' C ভাষার সংরক্ষিত শব্দ, তাই এটি চলকের নাম হিসেবে ব্যবহার করা যাবে না।",
          line: lineNumber,
        );
      }

      if (!_hasValidDeclaratorShape(leftSide, identifier)) {
        return VariableCheckResult.invalid(
          error: 'invalid variable declaration',
          explanation:
              'চলকের declaration-এর গঠন সঠিক নয়। নাম, pointer বা array অংশটি পরীক্ষা করুন।',
          line: lineNumber,
        );
      }
    }

    return null;
  }

  static List<String> _splitByTopLevelComma(String text) {
    final List<String> parts = <String>[];
    final StringBuffer current = StringBuffer();

    int bracketDepth = 0;
    int parenthesisDepth = 0;
    int braceDepth = 0;
    bool insideString = false;
    bool insideCharacter = false;
    bool escaped = false;

    for (int index = 0; index < text.length; index++) {
      final String character = text[index];

      if (escaped) {
        current.write(character);
        escaped = false;
        continue;
      }

      if ((insideString || insideCharacter) && character == r'\') {
        current.write(character);
        escaped = true;
        continue;
      }

      if (character == '"' && !insideCharacter) {
        insideString = !insideString;
        current.write(character);
        continue;
      }

      if (character == "'" && !insideString) {
        insideCharacter = !insideCharacter;
        current.write(character);
        continue;
      }

      if (!insideString && !insideCharacter) {
        if (character == '[') bracketDepth++;
        if (character == ']') bracketDepth--;
        if (character == '(') parenthesisDepth++;
        if (character == ')') parenthesisDepth--;
        if (character == '{') braceDepth++;
        if (character == '}') braceDepth--;

        if (character == ',' &&
            bracketDepth == 0 &&
            parenthesisDepth == 0 &&
            braceDepth == 0) {
          parts.add(current.toString());
          current.clear();
          continue;
        }
      }

      current.write(character);
    }

    parts.add(current.toString());
    return parts;
  }

  static int _findTopLevelEquals(String text) {
    int bracketDepth = 0;
    int parenthesisDepth = 0;
    int braceDepth = 0;
    bool insideString = false;
    bool insideCharacter = false;
    bool escaped = false;

    for (int index = 0; index < text.length; index++) {
      final String character = text[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideString || insideCharacter) && character == r'\') {
        escaped = true;
        continue;
      }

      if (character == '"' && !insideCharacter) {
        insideString = !insideString;
        continue;
      }

      if (character == "'" && !insideString) {
        insideCharacter = !insideCharacter;
        continue;
      }

      if (insideString || insideCharacter) {
        continue;
      }

      if (character == '[') bracketDepth++;
      if (character == ']') bracketDepth--;
      if (character == '(') parenthesisDepth++;
      if (character == ')') parenthesisDepth--;
      if (character == '{') braceDepth++;
      if (character == '}') braceDepth--;

      if (character == '=' &&
          bracketDepth == 0 &&
          parenthesisDepth == 0 &&
          braceDepth == 0) {
        final String? previous =
            index > 0 ? text[index - 1] : null;
        final String? next =
            index + 1 < text.length ? text[index + 1] : null;

        if (previous != '=' &&
            previous != '!' &&
            previous != '<' &&
            previous != '>' &&
            next != '=') {
          return index;
        }
      }
    }

    return -1;
  }

  static String _extractIdentifier(String declarator) {
  return declarator
      .replaceAll(RegExp(r'^\*+\s*'), '')
      .replaceAll(RegExp(r'(?:\[[^\]]*\]\s*)+$'), '')
      .trim();
}

  static bool _isValidIdentifier(String identifier) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$')
        .hasMatch(identifier);
  }

  static bool _hasValidDeclaratorShape(
    String declarator,
    String identifier,
  ) {
    final String escapedIdentifier = RegExp.escape(identifier);

    final RegExp shapePattern = RegExp(
      '^\\s*\\**\\s*$escapedIdentifier'
      r'\s*(?:\[[^\]]*\]\s*)*$',
    );

    return shapePattern.hasMatch(declarator);
  }
}
