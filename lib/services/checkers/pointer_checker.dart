import '../../models/compiler_result.dart';

class PointerChecker {
  static CompilerResult check(String code) {
    final List<String> lines = _sanitizeCode(code);

    final Map<String, _VariableSymbol> variables = {};
    final Map<String, _PointerSymbol> pointers = {};

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      final int lineNumber = i + 1;

      if (line.isEmpty) {
        continue;
      }

      final CompilerResult? declarationResult =
          _checkPointerDeclaration(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      if (declarationResult != null) {
        return declarationResult;
      }

      if (_isValidPointerDeclaration(line)) {
        _collectPointerDeclaration(
          line: line,
          lineNumber: lineNumber,
          variables: variables,
          pointers: pointers,
        );

        continue;
      }

      _collectOrdinaryVariable(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      final CompilerResult? scanfResult = _checkScanf(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      if (scanfResult != null) {
        return scanfResult;
      }

      final CompilerResult? pointerAssignmentResult =
          _checkPointerAssignment(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      if (pointerAssignmentResult != null) {
        return pointerAssignmentResult;
      }

      final CompilerResult? dereferenceResult =
          _checkDereference(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      if (dereferenceResult != null) {
        return dereferenceResult;
      }

      final CompilerResult? addressResult =
          _checkAddressOperator(
        line: line,
        lineNumber: lineNumber,
        variables: variables,
        pointers: pointers,
      );

      if (addressResult != null) {
        return addressResult;
      }
    }

    return CompilerResult.success(
      output: '',
    );
  }

  static CompilerResult? _checkPointerDeclaration({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    final RegExp multiplePointerPattern = RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*{2,}',
    );

    if (multiplePointerPattern.hasMatch(line)) {
      return CompilerResult.failure(
        error: 'Multiple-level pointer is not supported.',
        explanation:
            'Student C Studio-এর বর্তমান HSC পর্যায়ে শুধু এক স্তরের '
            'পয়েন্টার সমর্থিত। একটি * চিহ্ন ব্যবহার করো।',
        errorLine: lineNumber,
      );
    }

    final RegExp missingNamePattern = RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*\s*;\s*$',
    );

    if (missingNamePattern.hasMatch(line)) {
      return CompilerResult.failure(
        error: 'Pointer variable name is missing.',
        explanation:
            'পয়েন্টার ঘোষণার সময় * চিহ্নের পরে একটি বৈধ '
            'ভেরিয়েবলের নাম দিতে হবে।',
        errorLine: lineNumber,
      );
    }

    final RegExp invalidNamePattern = RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*\s*'
      r'([^A-Za-z_\s][A-Za-z0-9_]*)',
    );

    if (invalidNamePattern.hasMatch(line)) {
      return CompilerResult.failure(
        error: 'Invalid pointer variable name.',
        explanation:
            'পয়েন্টার ভেরিয়েবলের নাম সংখ্যা দিয়ে শুরু করা যায় না।',
        errorLine: lineNumber,
      );
    }

    final RegExp declarationPattern = RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*\s*'
      r'([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'(?:=\s*(.+?))?\s*;\s*$',
    );

    final Match? match = declarationPattern.firstMatch(line);

    if (match == null) {
      return null;
    }

    final String pointerType = match.group(1)!;
    final String? initializer = match.group(3)?.trim();

    if (initializer == null) {
      return null;
    }

    if (initializer == 'NULL') {
      return null;
    }

    if (initializer.startsWith('&')) {
      final String addressedValue =
          initializer.substring(1).trim();

      if (_isLiteralValue(addressedValue)) {
        return CompilerResult.failure(
          error: 'Cannot take address of a literal value.',
          explanation:
              'সরাসরি কোনো সংখ্যার ঠিকানা নেওয়া যায় না। '
              '& চিহ্নের পরে ঘোষিত ভেরিয়েবলের নাম দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (!_isValidIdentifier(addressedValue) ||
          !variables.containsKey(addressedValue)) {
        return CompilerResult.failure(
          error: 'Addressed variable is not declared.',
          explanation:
              '$addressedValue ভেরিয়েবলটির ঠিকানা নেওয়ার আগে '
              'ভেরিয়েবলটি ঘোষণা করতে হবে।',
          errorLine: lineNumber,
        );
      }

      final String variableType =
          variables[addressedValue]!.type;

      if (pointerType != variableType) {
        return _pointerVariableTypeMismatch(
          pointerType: pointerType,
          variableType: variableType,
          lineNumber: lineNumber,
        );
      }

      return null;
    }

    if (_isValidIdentifier(initializer) &&
        pointers.containsKey(initializer)) {
      final String sourcePointerType =
          pointers[initializer]!.baseType;

      if (pointerType != sourcePointerType) {
        return CompilerResult.failure(
          error: 'Pointer types do not match.',
          explanation:
              '$pointerType পয়েন্টারে $sourcePointerType পয়েন্টারের '
              'ঠিকানা রাখা যায় না। উভয় পয়েন্টারের ডেটা টাইপ '
              'একই হতে হবে।',
          errorLine: lineNumber,
        );
      }

      return null;
    }

    return CompilerResult.failure(
      error: 'Pointer must store an address.',
      explanation:
          'পয়েন্টার ভেরিয়েবলে সাধারণ মান রাখা যায় না। '
          'ভেরিয়েবলের ঠিকানা দিতে & চিহ্ন ব্যবহার করো।',
      errorLine: lineNumber,
    );
  }

  static bool _isValidPointerDeclaration(String line) {
    return RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*\s*'
      r'[A-Za-z_][A-Za-z0-9_]*\s*'
      r'(?:=\s*(.+?))?\s*;\s*$',
    ).hasMatch(line);
  }

  static void _collectPointerDeclaration({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    final Match? match = RegExp(
      r'^\s*(int|float|double|char|long|short)\s*\*\s*'
      r'([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'(?:=\s*(.+?))?\s*;\s*$',
    ).firstMatch(line);

    if (match == null) {
      return;
    }

    final String type = match.group(1)!;
    final String name = match.group(2)!;

    pointers[name] = _PointerSymbol(
      name: name,
      baseType: type,
      declarationLine: lineNumber,
    );

    variables.remove(name);
  }

  static void _collectOrdinaryVariable({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    if (line.contains('*')) {
      final bool multiplicationExpression = RegExp(
        r'[A-Za-z0-9_)]\s*\*\s*[A-Za-z0-9_(]',
      ).hasMatch(line);

      if (!multiplicationExpression) {
        return;
      }
    }

    final Match? match = RegExp(
      r'^\s*(int|float|double|char|long|short)\s+'
      r'([A-Za-z_][A-Za-z0-9_]*)\b',
    ).firstMatch(line);

    if (match == null) {
      return;
    }

    final String type = match.group(1)!;
    final String name = match.group(2)!;

    if (pointers.containsKey(name)) {
      return;
    }

    variables[name] = _VariableSymbol(
      name: name,
      type: type,
      declarationLine: lineNumber,
    );
  }

  static CompilerResult? _checkPointerAssignment({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    if (RegExp(
      r'^\s*(int|float|double|char|long|short)\b',
    ).hasMatch(line)) {
      return null;
    }

    final Match? match = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*;\s*$',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String leftSide = match.group(1)!;
    final String rightSide = match.group(2)!.trim();

    if (!pointers.containsKey(leftSide)) {
      if (rightSide.startsWith('&') &&
          !variables.containsKey(leftSide)) {
        return CompilerResult.failure(
          error: 'Pointer variable is not declared.',
          explanation:
              '$leftSide পয়েন্টার ভেরিয়েবলটি ব্যবহারের আগে '
              'ঘোষণা করতে হবে।',
          errorLine: lineNumber,
        );
      }

      return null;
    }

    if (rightSide == 'NULL') {
      return null;
    }

    final String destinationType =
        pointers[leftSide]!.baseType;

    if (rightSide.startsWith('&')) {
      final String addressedValue =
          rightSide.substring(1).trim();

      if (_isLiteralValue(addressedValue)) {
        return CompilerResult.failure(
          error: 'Cannot take address of a literal value.',
          explanation:
              'সরাসরি কোনো সংখ্যার ঠিকানা নেওয়া যায় না। '
              '& চিহ্নের পরে ঘোষিত ভেরিয়েবলের নাম দিতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (!variables.containsKey(addressedValue)) {
        return CompilerResult.failure(
          error: 'Addressed variable is not declared.',
          explanation:
              '$addressedValue ভেরিয়েবলটির ঠিকানা নেওয়ার আগে '
              'ভেরিয়েবলটি ঘোষণা করতে হবে।',
          errorLine: lineNumber,
        );
      }

      final String variableType =
          variables[addressedValue]!.type;

      if (destinationType != variableType) {
        return _pointerVariableTypeMismatch(
          pointerType: destinationType,
          variableType: variableType,
          lineNumber: lineNumber,
        );
      }

      return null;
    }

    if (pointers.containsKey(rightSide)) {
      final String sourceType =
          pointers[rightSide]!.baseType;

      if (destinationType != sourceType) {
        return CompilerResult.failure(
          error: 'Pointer types do not match.',
          explanation:
              '$destinationType পয়েন্টারে $sourceType পয়েন্টারের '
              'ঠিকানা রাখা যায় না। উভয় পয়েন্টারের ডেটা টাইপ '
              'একই হতে হবে।',
          errorLine: lineNumber,
        );
      }

      return null;
    }

    return CompilerResult.failure(
      error: 'Pointer must store an address.',
      explanation:
          'পয়েন্টার ভেরিয়েবলে সাধারণ মান রাখা যায় না। '
          'ভেরিয়েবলের ঠিকানা অথবা NULL দিতে হবে।',
      errorLine: lineNumber,
    );
  }

  static CompilerResult? _checkDereference({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    if (_isValidPointerDeclaration(line)) {
      return null;
    }

    final Set<String> dereferencedNames = {};

    final Match? leftSideMatch = RegExp(
      r'^\s*\*\s*([A-Za-z_][A-Za-z0-9_]*)\s*=',
    ).firstMatch(line);

    if (leftSideMatch != null) {
      dereferencedNames.add(leftSideMatch.group(1)!);
    }

    final Iterable<Match> rightSideMatches = RegExp(
      r'=\s*\*\s*([A-Za-z_][A-Za-z0-9_]*)\b',
    ).allMatches(line);

    for (final Match match in rightSideMatches) {
      dereferencedNames.add(match.group(1)!);
    }

    for (final String name in dereferencedNames) {
      if (pointers.containsKey(name)) {
        continue;
      }

      if (variables.containsKey(name)) {
        return CompilerResult.failure(
          error: 'Only a pointer can be dereferenced.',
          explanation:
              '$name একটি সাধারণ ভেরিয়েবল। * চিহ্ন দিয়ে শুধু '
              'পয়েন্টার ভেরিয়েবলের সংরক্ষিত ঠিকানার মান পাওয়া যায়।',
          errorLine: lineNumber,
        );
      }

      return CompilerResult.failure(
        error: 'Pointer variable is not declared.',
        explanation:
            '$name পয়েন্টার ভেরিয়েবলটি dereference করার আগে '
            'ঘোষণা করতে হবে।',
        errorLine: lineNumber,
      );
    }

    return null;
  }

  static CompilerResult? _checkAddressOperator({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    final String withoutLogicalAnd =
        line.replaceAll('&&', '');

    final Iterable<Match> matches = RegExp(
      r'&\s*([A-Za-z_][A-Za-z0-9_]*)',
    ).allMatches(withoutLogicalAnd);

    for (final Match match in matches) {
      final String name = match.group(1)!;

      if (variables.containsKey(name) ||
          pointers.containsKey(name)) {
        continue;
      }

      return CompilerResult.failure(
        error: 'Addressed variable is not declared.',
        explanation:
            '$name ভেরিয়েবলটির ঠিকানা নেওয়ার আগে '
            'ভেরিয়েবলটি ঘোষণা করতে হবে।',
        errorLine: lineNumber,
      );
    }

    return null;
  }

  static CompilerResult? _checkScanf({
    required String line,
    required int lineNumber,
    required Map<String, _VariableSymbol> variables,
    required Map<String, _PointerSymbol> pointers,
  }) {
    final Match? match = RegExp(
      r'\bscanf\s*\(\s*"[^"]*"\s*,\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String argument = match.group(1)!.trim();

    if (argument.startsWith('&')) {
      final String name = argument.substring(1).trim();

      if (pointers.containsKey(name)) {
        return CompilerResult.failure(
          error: 'Do not use & before a pointer in scanf.',
          explanation:
              '$name নিজেই একটি ঠিকানা সংরক্ষণ করে। scanf() ফাংশনে '
              'পয়েন্টার ব্যবহার করলে তার আগে অতিরিক্ত & চিহ্ন '
              'দিতে হবে না।',
          errorLine: lineNumber,
        );
      }

      if (!variables.containsKey(name)) {
        return CompilerResult.failure(
          error: 'Addressed variable is not declared.',
          explanation:
              '$name ভেরিয়েবলটির ঠিকানা নেওয়ার আগে '
              'ভেরিয়েবলটি ঘোষণা করতে হবে।',
          errorLine: lineNumber,
        );
      }

      return null;
    }

    if (pointers.containsKey(argument)) {
      return null;
    }

    if (_isValidIdentifier(argument) &&
        !variables.containsKey(argument)) {
      return CompilerResult.failure(
        error: 'Pointer variable is not declared.',
        explanation:
            '$argument পয়েন্টার ভেরিয়েবলটি ব্যবহারের আগে '
            'ঘোষণা করতে হবে।',
        errorLine: lineNumber,
      );
    }

    return null;
  }

  static CompilerResult _pointerVariableTypeMismatch({
    required String pointerType,
    required String variableType,
    required int lineNumber,
  }) {
    return CompilerResult.failure(
      error: 'Pointer type does not match variable type.',
      explanation:
          '$pointerType পয়েন্টারে $variableType ভেরিয়েবলের ঠিকানা '
          'রাখা যায় না। পয়েন্টার ও ভেরিয়েবলের ডেটা টাইপ '
          'একই হতে হবে।',
      errorLine: lineNumber,
    );
  }

  static bool _isValidIdentifier(String value) {
    return RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*$',
    ).hasMatch(value.trim());
  }

  static bool _isLiteralValue(String value) {
    final String trimmedValue = value.trim();

    return RegExp(
      r'^[-+]?\d+(?:\.\d+)?$',
    ).hasMatch(trimmedValue) ||
        RegExp(
          r"^'(?:\\.|[^'\\])'$",
        ).hasMatch(trimmedValue) ||
        RegExp(
          r'^"(?:\\.|[^"\\])*"$',
        ).hasMatch(trimmedValue);
  }

  static List<String> _sanitizeCode(String code) {
    final List<String> sanitizedLines = [];
    bool insideBlockComment = false;

    for (final String originalLine in code.split('\n')) {
      final StringBuffer buffer = StringBuffer();
      bool insideDoubleQuote = false;
      bool insideSingleQuote = false;
      int i = 0;

      while (i < originalLine.length) {
        if (insideBlockComment) {
          final int commentEnd =
              originalLine.indexOf('*/', i);

          if (commentEnd == -1) {
            i = originalLine.length;
            continue;
          }

          insideBlockComment = false;
          i = commentEnd + 2;
          continue;
        }

        final String current = originalLine[i];
        final String? next = i + 1 < originalLine.length
            ? originalLine[i + 1]
            : null;

        if (!insideSingleQuote &&
            current == '"' &&
            !_isEscaped(originalLine, i)) {
          insideDoubleQuote = !insideDoubleQuote;
          buffer.write(current);
          i++;
          continue;
        }

        if (!insideDoubleQuote &&
            current == "'" &&
            !_isEscaped(originalLine, i)) {
          insideSingleQuote = !insideSingleQuote;
          buffer.write(current);
          i++;
          continue;
        }

        if (!insideDoubleQuote && !insideSingleQuote) {
          if (current == '/' && next == '*') {
            insideBlockComment = true;
            i += 2;
            continue;
          }

          if (current == '/' && next == '/') {
            break;
          }
        }

        buffer.write(current);
        i++;
      }

      sanitizedLines.add(buffer.toString());
    }

    return sanitizedLines;
  }

  static bool _isEscaped(String text, int index) {
    int slashCount = 0;
    int i = index - 1;

    while (i >= 0 && text[i] == r'\') {
      slashCount++;
      i--;
    }

    return slashCount.isOdd;
  }
}

class _VariableSymbol {
  final String name;
  final String type;
  final int declarationLine;

  const _VariableSymbol({
    required this.name,
    required this.type,
    required this.declarationLine,
  });
}

class _PointerSymbol {
  final String name;
  final String baseType;
  final int declarationLine;

  const _PointerSymbol({
    required this.name,
    required this.baseType,
    required this.declarationLine,
  });
}