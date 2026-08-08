import 'dart:math' as math;

class EducationalOutputEngine {
  const EducationalOutputEngine();

  static const int _maximumLoopIterations = 10000;
  static const int _maximumOutputLength = 10000;

  String execute(
    String code, {
    String input = '',
  }) {
    final _EducationalExecutor executor = _EducationalExecutor(
      maximumLoopIterations: _maximumLoopIterations,
      maximumOutputLength: _maximumOutputLength,
      input: input,
    );

    return executor.execute(code);
  }
}

class _EducationalExecutor {
  _EducationalExecutor({
    required this.maximumLoopIterations,
    required this.maximumOutputLength,
    required String input,
  }) : _inputTokens = input.trim().isEmpty
            ? <String>[]
            : input.trim().split(RegExp(r'\s+'));

  final int maximumLoopIterations;
  final int maximumOutputLength;
  final List<String> _inputTokens;

  final Map<String, _VariableValue> _variables = <String, _VariableValue>{};

  final StringBuffer _output = StringBuffer();

  int _inputCursor = 0;

  bool _breakRequested = false;
  bool _continueRequested = false;
  String? _gotoTarget;

  String execute(String code) {
    final String sanitizedCode = _removeComments(code);
    final String executableCode = _extractMainBody(sanitizedCode);

    _executeSource(executableCode);

    int jumpCount = 0;

    while (_gotoTarget != null &&
        jumpCount < maximumLoopIterations &&
        _output.length < maximumOutputLength) {
      final String label = _gotoTarget!;
      _gotoTarget = null;

      final int? labelCursor = _findLabelCursor(executableCode, label);

      if (labelCursor == null) {
        break;
      }

      _executeSource(executableCode, startCursor: labelCursor);
      jumpCount++;
    }

    final String result = _output.toString();

    if (result.length <= maximumOutputLength) {
      return result;
    }

    return result.substring(0, maximumOutputLength);
  }

  int? _findLabelCursor(String source, String label) {
    final RegExp labelPattern = RegExp(
      r'^\s*' + RegExp.escape(label) + r'\s*:',
    );

    int offset = 0;

    for (final String line in source.split('\n')) {
      final RegExpMatch? match = labelPattern.firstMatch(line);

      if (match != null) {
        return offset + match.end;
      }

      offset += line.length + 1;
    }

    return null;
  }

  void _executeSource(String source, {int startCursor = 0}) {
    int cursor = startCursor;

    while (cursor < source.length && _output.length < maximumOutputLength) {
      if (_breakRequested || _continueRequested || _gotoTarget != null) {
        return;
      }

      cursor = _skipWhitespace(source, cursor);

      if (cursor >= source.length) {
        break;
      }

      final RegExpMatch? labelMatch = RegExp(
        r'^([A-Za-z_][A-Za-z0-9_]*)\s*:(?!:)',
      ).firstMatch(source.substring(cursor));

      if (labelMatch != null) {
        cursor += labelMatch.end;
        continue;
      }

      if (_startsWithWord(source, cursor, 'goto')) {
        final int statementEnd = _findStatementEnd(source, cursor);

        if (statementEnd < 0) {
          break;
        }

        final String statement = source.substring(cursor, statementEnd).trim();

        final RegExpMatch? gotoMatch = RegExp(
          r'^goto\s+([A-Za-z_][A-Za-z0-9_]*)$',
        ).firstMatch(statement);

        if (gotoMatch != null) {
          _gotoTarget = gotoMatch.group(1);
        }

        return;
      }

      if (_startsWithWord(source, cursor, 'if')) {
        cursor = _executeIf(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'do')) {
        cursor = _executeDoWhile(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'for')) {
        cursor = _executeFor(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'while')) {
        cursor = _executeWhile(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'printf')) {
        cursor = _executePrintf(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'scanf')) {
        cursor = _executeScanf(source, cursor);
        continue;
      }

      if (_isDeclarationStart(source, cursor)) {
        cursor = _executeVariableDeclaration(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'return')) {
        cursor = _skipToStatementEnd(source, cursor);
        continue;
      }

      if (_startsWithWord(source, cursor, 'break')) {
        _breakRequested = true;
        return;
      }

      if (_startsWithWord(source, cursor, 'continue')) {
        _continueRequested = true;
        return;
      }

      if (source[cursor] == '{') {
        final int closingBrace = _findMatchingDelimiter(
          source,
          cursor,
          '{',
          '}',
        );

        if (closingBrace < 0) {
          break;
        }

        _executeSource(
          source.substring(cursor + 1, closingBrace),
        );

        cursor = closingBrace + 1;
        continue;
      }

      final int statementEnd = _findStatementEnd(
        source,
        cursor,
      );

      if (statementEnd < 0) {
        break;
      }

      final String statement = source.substring(cursor, statementEnd).trim();

      _executeSimpleStatement(statement);
      cursor = statementEnd + 1;
    }
  }

  bool _isDeclarationStart(
    String source,
    int cursor,
  ) {
    const List<String> types = <String>[
      'int',
      'float',
      'double',
      'char',
      'long',
      'short',
    ];

    for (final String type in types) {
      if (_startsWithWord(source, cursor, type)) {
        return true;
      }
    }

    return false;
  }

  int _executeIf(String source, int ifStart) {
    int cursor = ifStart;
    bool branchExecuted = false;

    while (true) {
      final int conditionStart = _skipWhitespace(source, cursor + 2);

      if (conditionStart >= source.length || source[conditionStart] != '(') {
        return cursor + 2;
      }

      final int conditionEnd = _findMatchingDelimiter(
        source,
        conditionStart,
        '(',
        ')',
      );

      if (conditionEnd < 0) {
        return source.length;
      }

      final String condition = source.substring(
        conditionStart + 1,
        conditionEnd,
      );

      final _StatementBody body = _readStatementBody(
        source,
        conditionEnd + 1,
      );

      if (!body.isValid) {
        return conditionEnd + 1;
      }

      if (!branchExecuted && _evaluateCondition(condition)) {
        _executeSource(body.source);
        branchExecuted = true;
      }

      final int afterBody = _skipWhitespace(source, body.endIndex);

      if (_startsWithWord(
        source,
        afterBody,
        'else',
      )) {
        final int afterElse = _skipWhitespace(source, afterBody + 4);

        if (_startsWithWord(
          source,
          afterElse,
          'if',
        )) {
          cursor = afterElse;
          continue;
        }

        final _StatementBody elseBody = _readStatementBody(
          source,
          afterBody + 4,
        );

        if (!elseBody.isValid) {
          return afterBody + 4;
        }

        if (!branchExecuted) {
          _executeSource(elseBody.source);
        }

        return elseBody.endIndex;
      }

      return afterBody;
    }
  }

  int _executeWhile(String source, int whileStart) {
    final int conditionStart = _skipWhitespace(source, whileStart + 5);

    if (conditionStart >= source.length || source[conditionStart] != '(') {
      return whileStart + 5;
    }

    final int conditionEnd = _findMatchingDelimiter(
      source,
      conditionStart,
      '(',
      ')',
    );

    if (conditionEnd < 0) {
      return source.length;
    }

    final String condition = source.substring(
      conditionStart + 1,
      conditionEnd,
    );

    final _StatementBody body = _readStatementBody(
      source,
      conditionEnd + 1,
    );

    if (!body.isValid) {
      return conditionEnd + 1;
    }

    int iterationCount = 0;

    while (_evaluateCondition(condition) &&
        iterationCount < maximumLoopIterations &&
        _output.length < maximumOutputLength) {
      _executeSource(body.source);

      if (_gotoTarget != null) {
        break;
      }

      if (_breakRequested) {
        _breakRequested = false;
        break;
      }

      if (_continueRequested) {
        _continueRequested = false;
      }

      iterationCount++;
    }

    return body.endIndex;
  }

  int _executeDoWhile(String source, int doStart) {
    final _StatementBody body = _readStatementBody(
      source,
      doStart + 2,
    );

    if (!body.isValid) {
      return doStart + 2;
    }

    final int whileStart = _skipWhitespace(source, body.endIndex);

    if (!_startsWithWord(
      source,
      whileStart,
      'while',
    )) {
      return body.endIndex;
    }

    final int conditionStart = _skipWhitespace(source, whileStart + 5);

    if (conditionStart >= source.length || source[conditionStart] != '(') {
      return whileStart + 5;
    }

    final int conditionEnd = _findMatchingDelimiter(
      source,
      conditionStart,
      '(',
      ')',
    );

    if (conditionEnd < 0) {
      return source.length;
    }

    final String condition = source.substring(
      conditionStart + 1,
      conditionEnd,
    );

    int completeEnd = conditionEnd + 1;
    completeEnd = _skipWhitespace(
      source,
      completeEnd,
    );

    if (completeEnd < source.length && source[completeEnd] == ';') {
      completeEnd++;
    }

    int iterationCount = 0;

    do {
      _executeSource(body.source);

      if (_gotoTarget != null) {
        break;
      }

      if (_breakRequested) {
        _breakRequested = false;
        break;
      }

      if (_continueRequested) {
        _continueRequested = false;
      }

      iterationCount++;

      if (iterationCount >= maximumLoopIterations ||
          _output.length >= maximumOutputLength) {
        break;
      }
    } while (_evaluateCondition(condition));

    return completeEnd;
  }

  int _executeFor(String source, int forStart) {
    final int headerStart = _skipWhitespace(source, forStart + 3);

    if (headerStart >= source.length || source[headerStart] != '(') {
      return forStart + 3;
    }

    final int headerEnd = _findMatchingDelimiter(
      source,
      headerStart,
      '(',
      ')',
    );

    if (headerEnd < 0) {
      return source.length;
    }

    final List<String> sections = _splitForHeader(
      source.substring(
        headerStart + 1,
        headerEnd,
      ),
    );

    if (sections.length != 3) {
      return headerEnd + 1;
    }

    final _StatementBody body = _readStatementBody(
      source,
      headerEnd + 1,
    );

    if (!body.isValid) {
      return headerEnd + 1;
    }

    _executeForInitialization(sections[0]);

    int iterationCount = 0;

    while ((sections[1].trim().isEmpty || _evaluateCondition(sections[1])) &&
        iterationCount < maximumLoopIterations &&
        _output.length < maximumOutputLength) {
      _executeSource(body.source);

      if (_gotoTarget != null) {
        break;
      }

      if (_breakRequested) {
        _breakRequested = false;
        break;
      }

      if (_continueRequested) {
        _continueRequested = false;
      }

      _executeForUpdate(sections[2]);
      iterationCount++;
    }

    return body.endIndex;
  }

  void _executeForInitialization(
    String initialization,
  ) {
    final String normalized = initialization.trim();

    if (normalized.isEmpty) {
      return;
    }

    if (_isDeclarationStart(normalized, 0)) {
      _executeDeclarationText(normalized);
      return;
    }

    _executeSimpleStatement(normalized);
  }

  void _executeForUpdate(String update) {
    final String normalized = update.trim();

    if (normalized.isEmpty) {
      return;
    }

    _executeSimpleStatement(normalized);
  }

  List<String> _splitForHeader(String header) {
    final List<String> sections = <String>[];

    int start = 0;
    int parenthesisDepth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool escaped = false;

    for (int index = 0; index < header.length; index++) {
      final String character = header[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        continue;
      }

      if (insideSingleQuote || insideDoubleQuote) {
        continue;
      }

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        parenthesisDepth--;
      } else if (character == ';' && parenthesisDepth == 0) {
        sections.add(
          header.substring(start, index).trim(),
        );

        start = index + 1;
      }
    }

    sections.add(header.substring(start).trim());
    return sections;
  }

  int _executePrintf(String source, int printfStart) {
    final int statementEnd = _findStatementEnd(
      source,
      printfStart,
    );

    if (statementEnd < 0) {
      return source.length;
    }

    final String statement = source.substring(
      printfStart,
      statementEnd + 1,
    );

    final RegExp printfPattern = RegExp(
      r'^printf\s*\(\s*"((?:\\.|[^"\\])*)"'
      r'(?:\s*,\s*(.+?))?\s*\)\s*;$',
      multiLine: true,
      dotAll: true,
    );

    final RegExpMatch? match = printfPattern.firstMatch(statement.trim());

    if (match != null) {
      final String format = _convertEscapeSequences(match.group(1) ?? '');

      final String? argumentSource = match.group(2)?.trim();

      final String text = _formatPrintfOutput(
        format,
        argumentSource,
      );

      _writeOutput(text);
    }

    return statementEnd + 1;
  }

  String _formatPrintfOutput(
    String format,
    String? argumentSource,
  ) {
    if (argumentSource == null || argumentSource.isEmpty) {
      return format.replaceAll('%%', '%');
    }

    final List<String> arguments = _splitTopLevelArguments(argumentSource);

    final StringBuffer result = StringBuffer();

    int argumentIndex = 0;
    int index = 0;

    while (index < format.length) {
      if (format[index] != '%') {
        result.write(format[index]);
        index++;
        continue;
      }

      if (index + 1 < format.length && format[index + 1] == '%') {
        result.write('%');
        index += 2;
        continue;
      }

      final _FormatSpecifier? specifier = _readFormatSpecifier(format, index);

      if (specifier == null) {
        result.write(format[index]);
        index++;
        continue;
      }

      if (argumentIndex >= arguments.length) {
        result.write(
          format.substring(
            index,
            specifier.endIndex,
          ),
        );

        index = specifier.endIndex;
        continue;
      }

      final String argument = arguments[argumentIndex].trim();

      argumentIndex++;

      result.write(
        _formatArgument(
          specifier,
          argument,
        ),
      );

      index = specifier.endIndex;
    }

    return result.toString();
  }

  String _formatArgument(
    _FormatSpecifier specifier,
    String argument,
  ) {
    final Object? value = _evaluateValue(argument);

    switch (specifier.kind) {
      case _FormatKind.integer:
        final num? numericValue = _asNumber(value);

        if (numericValue == null) {
          return '0';
        }

        return numericValue.toInt().toString();

      case _FormatKind.unsignedInteger:
        final num? numericValue = _asNumber(value);

        if (numericValue == null) {
          return '0';
        }

        return numericValue.toInt().abs().toString();

      case _FormatKind.floatValue:
      case _FormatKind.doubleValue:
        final num? numericValue = _asNumber(value);

        if (numericValue == null) {
          return '0.000000';
        }

        final int precision = specifier.precision ?? 6;

        return numericValue.toDouble().toStringAsFixed(precision);

      case _FormatKind.character:
        if (value is String && value.isNotEmpty) {
          return String.fromCharCode(value.runes.first);
        }

        final num? numericValue = _asNumber(value);

        if (numericValue != null) {
          return String.fromCharCode(
            numericValue.toInt(),
          );
        }

        return '';

      case _FormatKind.stringValue:
        if (value == null) {
          return '';
        }

        return value.toString();
    }
  }

  int _executeScanf(String source, int scanfStart) {
    final int statementEnd = _findStatementEnd(
      source,
      scanfStart,
    );

    if (statementEnd < 0) {
      return source.length;
    }

    final String statement = source.substring(
      scanfStart,
      statementEnd + 1,
    );

    final RegExp scanfPattern = RegExp(
      r'^scanf\s*\(\s*"((?:\\.|[^"\\])*)"\s*,\s*(.+?)\s*\)\s*;$',
      multiLine: true,
      dotAll: true,
    );

    final RegExpMatch? match = scanfPattern.firstMatch(statement.trim());

    if (match == null) {
      return statementEnd + 1;
    }

    final String format = match.group(1) ?? '';
    final String argumentSource = match.group(2) ?? '';

    final List<String> arguments = _splitTopLevelArguments(argumentSource);

    final List<_FormatSpecifier> specifiers = _readAllFormatSpecifiers(format);

    final int count = specifiers.length < arguments.length
        ? specifiers.length
        : arguments.length;

    for (int index = 0; index < count; index++) {
      if (_inputCursor >= _inputTokens.length) {
        break;
      }

      String variableName = arguments[index].trim();

      if (variableName.startsWith('&')) {
        variableName = variableName.substring(1).trim();
      }

      final String token = _inputTokens[_inputCursor];
      _inputCursor++;

      final RegExpMatch? arrayMatch = RegExp(
        r'^([A-Za-z_][A-Za-z0-9_]*)\s*\[(.+)\]$',
      ).firstMatch(variableName);

      if (arrayMatch != null) {
        final String arrayName = arrayMatch.group(1)!;
        final String indexExpression = arrayMatch.group(2)!.trim();

        _assignScanfArrayValue(
          arrayName,
          indexExpression,
          specifiers[index],
          token,
        );

        continue;
      }

      if (!RegExp(
        r'^[A-Za-z_][A-Za-z0-9_]*$',
      ).hasMatch(variableName)) {
        continue;
      }

      _assignScanfValue(
        variableName,
        specifiers[index],
        token,
      );
    }

    return statementEnd + 1;
  }

  void _assignScanfArrayValue(
    String arrayName,
    String indexExpression,
    _FormatSpecifier specifier,
    String token,
  ) {
    final _VariableValue? arrayVariable = _variables[arrayName];

    if (arrayVariable == null || arrayVariable.value is! List<Object?>) {
      return;
    }

    final num? evaluatedIndex = _evaluateNumericExpression(indexExpression);

    if (evaluatedIndex == null) {
      return;
    }

    final int arrayIndex = evaluatedIndex.toInt();

    final List<Object?> values = arrayVariable.value as List<Object?>;

    if (arrayIndex < 0 || arrayIndex >= values.length) {
      return;
    }

    Object? value;

    switch (specifier.kind) {
      case _FormatKind.integer:
        value = int.tryParse(token);
        break;

      case _FormatKind.unsignedInteger:
        final int? parsed = int.tryParse(token);
        if (parsed != null && parsed >= 0) {
          value = parsed;
        }
        break;

      case _FormatKind.floatValue:
      case _FormatKind.doubleValue:
        value = double.tryParse(token);
        break;

      case _FormatKind.character:
        if (token.isNotEmpty) {
          value = String.fromCharCode(
            token.runes.first,
          );
        }
        break;

      case _FormatKind.stringValue:
        value = token;
        break;
    }

    if (value == null) {
      return;
    }

    values[arrayIndex] = _coerceValue(
      value,
      arrayVariable.type,
      fallback: _defaultValueForType(
        arrayVariable.type,
      ),
    );
  }

  void _assignScanfValue(
    String variableName,
    _FormatSpecifier specifier,
    String token,
  ) {
    switch (specifier.kind) {
      case _FormatKind.integer:
        final int? value = int.tryParse(token);

        if (value != null) {
          _setVariable(
            variableName,
            _CValueType.integer,
            value,
          );
        }
        return;

      case _FormatKind.unsignedInteger:
        final int? value = int.tryParse(token);

        if (value != null && value >= 0) {
          _setVariable(
            variableName,
            _CValueType.unsignedInteger,
            value,
          );
        }
        return;

      case _FormatKind.floatValue:
        final double? value = double.tryParse(token);

        if (value != null) {
          _setVariable(
            variableName,
            _CValueType.floatValue,
            value,
          );
        }
        return;

      case _FormatKind.doubleValue:
        final double? value = double.tryParse(token);

        if (value != null) {
          _setVariable(
            variableName,
            _CValueType.doubleValue,
            value,
          );
        }
        return;

      case _FormatKind.character:
        if (token.isNotEmpty) {
          _setVariable(
            variableName,
            _CValueType.character,
            String.fromCharCode(
              token.runes.first,
            ),
          );
        }
        return;

      case _FormatKind.stringValue:
        _setVariable(
          variableName,
          _CValueType.stringValue,
          token,
        );
        return;
    }
  }

  int _executeVariableDeclaration(
    String source,
    int declarationStart,
  ) {
    final int statementEnd = _findStatementEnd(
      source,
      declarationStart,
    );

    if (statementEnd < 0) {
      return source.length;
    }

    final String statement =
        source.substring(declarationStart, statementEnd).trim();

    _executeDeclarationText(statement);

    return statementEnd + 1;
  }

  void _executeDeclarationText(String declaration) {
    final RegExp declarationPattern = RegExp(
      r'^(int|float|double|char|long|short)\s+(.+)$',
      dotAll: true,
    );

    final RegExpMatch? declarationMatch = declarationPattern.firstMatch(
      declaration.trim(),
    );

    if (declarationMatch == null) {
      return;
    }

    final String typeName = declarationMatch.group(1)!;

    final String declaratorSource = declarationMatch.group(2)!.trim();

    final List<String> declarators = _splitTopLevelArguments(
      declaratorSource,
    );

    for (final String rawDeclarator in declarators) {
      _executeSingleDeclarator(
        typeName,
        rawDeclarator.trim(),
      );
    }
  }

  void _executeSingleDeclarator(
    String typeName,
    String declarator,
  ) {
    if (declarator.isEmpty) {
      return;
    }
    final RegExp arrayPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)'
      r'\s*\[\s*([^\]]*)\s*\]'
      r'(?:\s*=\s*(.+))?$',
      dotAll: true,
    );

    final RegExpMatch? arrayMatch = arrayPattern.firstMatch(declarator);

    if (arrayMatch != null) {
      final String name = arrayMatch.group(1)!;
      final String sizeExpression = arrayMatch.group(2)?.trim() ?? '';
      final String? initializer = arrayMatch.group(3)?.trim();

      if (typeName == 'char') {
        String value = '';

        if (initializer != null) {
          value = _stripStringLiteral(initializer) ?? initializer;
        }

        _variables[name] = _VariableValue(
          type: _CValueType.stringValue,
          value: value,
        );

        return;
      }

      final _CValueType elementType = _typeFromDeclaration(typeName);
      final Object defaultValue = _defaultValueForType(elementType);

      int declaredSize = 0;

      if (sizeExpression.isNotEmpty) {
        final num? evaluatedSize = _evaluateNumericExpression(sizeExpression);

        if (evaluatedSize != null && evaluatedSize > 0) {
          declaredSize = evaluatedSize.toInt();
        }
      }

      final List<Object?> initializerValues = <Object?>[];

      if (initializer != null &&
          initializer.startsWith('{') &&
          initializer.endsWith('}')) {
        final String initializerBody =
            initializer.substring(1, initializer.length - 1).trim();

        if (initializerBody.isNotEmpty) {
          final List<String> values = _splitTopLevelArguments(initializerBody);

          for (final String expression in values) {
            initializerValues.add(
              _coerceValue(
                _evaluateValue(expression),
                elementType,
                fallback: defaultValue,
              ),
            );
          }
        }
      }

      if (declaredSize == 0 && initializerValues.isNotEmpty) {
        declaredSize = initializerValues.length;
      }

      final List<Object?> arrayValues = List<Object?>.filled(
        declaredSize,
        defaultValue,
        growable: false,
      );

      final int copyCount = initializerValues.length < arrayValues.length
          ? initializerValues.length
          : arrayValues.length;

      for (int index = 0; index < copyCount; index++) {
        arrayValues[index] = initializerValues[index];
      }

      _variables[name] = _VariableValue(
        type: elementType,
        value: arrayValues,
      );

      return;
    }

    final RegExp declaratorPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)'
      r'(?:\s*=\s*(.+))?$',
      dotAll: true,
    );

    final RegExpMatch? match = declaratorPattern.firstMatch(declarator);

    if (match == null) {
      return;
    }

    final String variableName = match.group(1)!;
    final String? initializer = match.group(2)?.trim();

    final _CValueType type = _typeFromDeclaration(typeName);

    final Object defaultValue = _defaultValueForType(type);

    Object value = defaultValue;

    if (initializer != null) {
      value = _coerceValue(
        _evaluateValue(initializer),
        type,
        fallback: defaultValue,
      );
    }

    _variables[variableName] = _VariableValue(
      type: type,
      value: value,
    );
  }

  _CValueType _typeFromDeclaration(
    String typeName,
  ) {
    switch (typeName) {
      case 'float':
        return _CValueType.floatValue;
      case 'double':
        return _CValueType.doubleValue;
      case 'char':
        return _CValueType.character;
      case 'int':
      case 'long':
      case 'short':
        return _CValueType.integer;
    }

    return _CValueType.integer;
  }

  Object _defaultValueForType(_CValueType type) {
    switch (type) {
      case _CValueType.integer:
      case _CValueType.unsignedInteger:
        return 0;
      case _CValueType.floatValue:
      case _CValueType.doubleValue:
        return 0.0;
      case _CValueType.character:
      case _CValueType.stringValue:
        return '';
    }
  }

  void _setVariable(
    String name,
    _CValueType preferredType,
    Object value,
  ) {
    final _VariableValue? existing = _variables[name];

    final _CValueType targetType = existing?.type ?? preferredType;

    _variables[name] = _VariableValue(
      type: targetType,
      value: _coerceValue(
        value,
        targetType,
        fallback: _defaultValueForType(
          targetType,
        ),
      ),
    );
  }

  Object _coerceValue(
    Object? value,
    _CValueType type, {
    required Object fallback,
  }) {
    switch (type) {
      case _CValueType.integer:
        final num? numericValue = _asNumber(value);
        return numericValue?.toInt() ?? fallback;

      case _CValueType.unsignedInteger:
        final num? numericValue = _asNumber(value);

        if (numericValue == null) {
          return fallback;
        }

        return numericValue.toInt().abs();

      case _CValueType.floatValue:
      case _CValueType.doubleValue:
        final num? numericValue = _asNumber(value);
        return numericValue?.toDouble() ?? fallback;

      case _CValueType.character:
        if (value is String && value.isNotEmpty) {
          return String.fromCharCode(
            value.runes.first,
          );
        }

        final num? numericValue = _asNumber(value);

        if (numericValue != null) {
          return String.fromCharCode(
            numericValue.toInt(),
          );
        }

        return fallback;

      case _CValueType.stringValue:
        if (value == null) {
          return fallback;
        }

        return value.toString();
    }
  }

  void _executeSimpleStatement(String statement) {
    final String normalized = statement.trim();

    if (normalized.isEmpty) {
      return;
    }

    final RegExp postfixPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)\s*(\+\+|--)$',
    );

    final RegExpMatch? postfixMatch = postfixPattern.firstMatch(normalized);

    if (postfixMatch != null) {
      final String variableName = postfixMatch.group(1)!;

      final String operator = postfixMatch.group(2)!;

      final _VariableValue? variable = _variables[variableName];

      final num currentValue = _asNumber(variable?.value) ?? 0;

      final num updatedValue =
          operator == '++' ? currentValue + 1 : currentValue - 1;

      _setVariable(
        variableName,
        variable?.type ?? _CValueType.integer,
        updatedValue,
      );

      return;
    }

    final RegExp prefixPattern = RegExp(
      r'^(\+\+|--)\s*([A-Za-z_][A-Za-z0-9_]*)$',
    );

    final RegExpMatch? prefixMatch = prefixPattern.firstMatch(normalized);

    if (prefixMatch != null) {
      final String operator = prefixMatch.group(1)!;

      final String variableName = prefixMatch.group(2)!;

      final _VariableValue? variable = _variables[variableName];

      final num currentValue = _asNumber(variable?.value) ?? 0;

      final num updatedValue =
          operator == '++' ? currentValue + 1 : currentValue - 1;

      _setVariable(
        variableName,
        variable?.type ?? _CValueType.integer,
        updatedValue,
      );

      return;
    }

    final RegExp compoundPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)\s*([+\-*/%])=\s*(.+)$',
      dotAll: true,
    );

    final RegExpMatch? compoundMatch = compoundPattern.firstMatch(normalized);

    if (compoundMatch != null) {
      final String variableName = compoundMatch.group(1)!;

      final String operator = compoundMatch.group(2)!;

      final String expression = compoundMatch.group(3)!.trim();

      final _VariableValue? variable = _variables[variableName];

      final num? currentValue = _asNumber(variable?.value);

      final num? rightValue = _evaluateNumericExpression(expression);

      if (currentValue == null || rightValue == null) {
        return;
      }

      num? result;

      switch (operator) {
        case '+':
          result = currentValue + rightValue;
          break;
        case '-':
          result = currentValue - rightValue;
          break;
        case '*':
          result = currentValue * rightValue;
          break;
        case '/':
          if (rightValue == 0) {
            return;
          }

          if (_isIntegerType(
                variable?.type ?? _CValueType.integer,
              ) &&
              rightValue is int) {
            result = currentValue.toInt() ~/ rightValue.toInt();
          } else {
            result = currentValue / rightValue;
          }
          break;
        case '%':
          if (rightValue == 0) {
            return;
          }

          result = currentValue % rightValue;
          break;
      }

      if (result != null) {
        _setVariable(
          variableName,
          variable?.type ?? _CValueType.integer,
          result,
        );
      }

      return;
    }
    final RegExp arrayAssignmentPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)'
      r'\s*\[(.+)\]\s*=\s*(.+)$',
      dotAll: true,
    );

    final RegExpMatch? arrayAssignmentMatch =
        arrayAssignmentPattern.firstMatch(normalized);

    if (arrayAssignmentMatch != null) {
      final String arrayName = arrayAssignmentMatch.group(1)!;
      final String indexExpression = arrayAssignmentMatch.group(2)!.trim();
      final String valueExpression = arrayAssignmentMatch.group(3)!.trim();

      final _VariableValue? arrayVariable = _variables[arrayName];

      if (arrayVariable == null || arrayVariable.value is! List<Object?>) {
        return;
      }

      final num? evaluatedIndex = _evaluateNumericExpression(indexExpression);

      if (evaluatedIndex == null) {
        return;
      }

      final int arrayIndex = evaluatedIndex.toInt();

      final List<Object?> values = arrayVariable.value as List<Object?>;

      if (arrayIndex < 0 || arrayIndex >= values.length) {
        return;
      }

      final Object? value = _evaluateValue(valueExpression);

      if (value == null) {
        return;
      }

      values[arrayIndex] = _coerceValue(
        value,
        arrayVariable.type,
        fallback: _defaultValueForType(
          arrayVariable.type,
        ),
      );

      return;
    }
    final RegExp assignmentPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$',
      dotAll: true,
    );

    final RegExpMatch? assignmentMatch =
        assignmentPattern.firstMatch(normalized);

    if (assignmentMatch != null) {
      final String variableName = assignmentMatch.group(1)!;

      final String expression = assignmentMatch.group(2)!.trim();

      final Object? value = _evaluateValue(expression);

      if (value == null) {
        return;
      }

      final _VariableValue? existing = _variables[variableName];

      _setVariable(
        variableName,
        existing?.type ?? _inferType(value),
        value,
      );
    }
  }

  _CValueType _inferType(Object value) {
    if (value is int) {
      return _CValueType.integer;
    }

    if (value is double) {
      return _CValueType.doubleValue;
    }

    if (value is String && value.runes.length == 1) {
      return _CValueType.character;
    }

    return _CValueType.stringValue;
  }

  bool _isIntegerType(_CValueType type) {
    return type == _CValueType.integer || type == _CValueType.unsignedInteger;
  }

  bool _evaluateCondition(String expression) {
    final String normalized = _removeOuterParentheses(
      expression.trim(),
    );

    if (normalized.isEmpty) {
      return false;
    }

    final int orIndex = _findTopLevelOperator(normalized, '||');

    if (orIndex >= 0) {
      return _evaluateCondition(
            normalized.substring(0, orIndex),
          ) ||
          _evaluateCondition(
            normalized.substring(orIndex + 2),
          );
    }

    final int andIndex = _findTopLevelOperator(normalized, '&&');

    if (andIndex >= 0) {
      return _evaluateCondition(
            normalized.substring(0, andIndex),
          ) &&
          _evaluateCondition(
            normalized.substring(andIndex + 2),
          );
    }

    if (normalized.startsWith('!') && !normalized.startsWith('!=')) {
      return !_evaluateCondition(
        normalized.substring(1),
      );
    }

    const List<String> comparisonOperators = <String>[
      '==',
      '!=',
      '>=',
      '<=',
      '>',
      '<',
    ];

    for (final String operator in comparisonOperators) {
      final int operatorIndex = _findTopLevelOperator(
        normalized,
        operator,
      );

      if (operatorIndex < 0) {
        continue;
      }

      final Object? leftValue = _evaluateValue(
        normalized.substring(
          0,
          operatorIndex,
        ),
      );

      final Object? rightValue = _evaluateValue(
        normalized.substring(
          operatorIndex + operator.length,
        ),
      );

      if (leftValue == null || rightValue == null) {
        return false;
      }

      final num? leftNumber = _asNumber(leftValue);

      final num? rightNumber = _asNumber(rightValue);

      if (leftNumber != null && rightNumber != null) {
        switch (operator) {
          case '==':
            return leftNumber == rightNumber;
          case '!=':
            return leftNumber != rightNumber;
          case '>=':
            return leftNumber >= rightNumber;
          case '<=':
            return leftNumber <= rightNumber;
          case '>':
            return leftNumber > rightNumber;
          case '<':
            return leftNumber < rightNumber;
        }
      }

      final String leftText = leftValue.toString();

      final String rightText = rightValue.toString();

      switch (operator) {
        case '==':
          return leftText == rightText;
        case '!=':
          return leftText != rightText;
        case '>=':
          return leftText.compareTo(rightText) >= 0;
        case '<=':
          return leftText.compareTo(rightText) <= 0;
        case '>':
          return leftText.compareTo(rightText) > 0;
        case '<':
          return leftText.compareTo(rightText) < 0;
      }
    }

    final Object? value = _evaluateValue(normalized);

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return value.isNotEmpty;
    }

    return false;
  }

  Object? _evaluateValue(String expression) {
    final String normalized = _removeOuterParentheses(
      expression.trim(),
    );

    if (normalized.isEmpty) {
      return null;
    }

    final String? stringLiteral = _stripStringLiteral(normalized);

    if (stringLiteral != null) {
      return stringLiteral;
    }

    final String? characterLiteral = _stripCharacterLiteral(normalized);

    if (characterLiteral != null) {
      return characterLiteral;
    }

// এখানে strlen function বসবে
    final RegExpMatch? strlenMatch = RegExp(
      r'^strlen\s*\(\s*(.+)\s*\)$',
    ).firstMatch(normalized);

    if (strlenMatch != null) {
      final String argumentExpression = strlenMatch.group(1)!.trim();
      final Object? argumentValue = _evaluateValue(argumentExpression);

      if (argumentValue is String) {
        return argumentValue.runes.length;
      }

      return null;
    }

    final RegExpMatch? arrayMatch = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)\s*\[(.+)\]$',
    ).firstMatch(normalized);

    if (arrayMatch != null) {
      final String arrayName = arrayMatch.group(1)!;
      final String indexExpression = arrayMatch.group(2)!.trim();

      final _VariableValue? arrayVariable = _variables[arrayName];

      final num? evaluatedIndex = _evaluateNumericExpression(indexExpression);

      if (arrayVariable == null || evaluatedIndex == null) {
        return null;
      }

      final int arrayIndex = evaluatedIndex.toInt();

      if (arrayVariable.value is List<Object?>) {
        final List<Object?> values = arrayVariable.value as List<Object?>;

        if (arrayIndex >= 0 && arrayIndex < values.length) {
          return values[arrayIndex];
        }

        return null;
      }

      // char array / C string support
      if (arrayVariable.value is String) {
        final String text = arrayVariable.value as String;
        final List<int> runes = text.runes.toList();

        if (arrayIndex >= 0 && arrayIndex < runes.length) {
          return String.fromCharCode(runes[arrayIndex]);
        }

        // C string-এর শেষে implicit null terminator
        if (arrayIndex == runes.length) {
          return '\x00';
        }
      }

      return null;
    }

    final _VariableValue? variable = _variables[normalized];

    if (variable != null) {
      return variable.value;
    }

    return _evaluateNumericExpression(normalized);
  }

  num? _evaluateNumericExpression(
    String expression,
  ) {
    final _NumericExpressionParser parser = _NumericExpressionParser(
      expression,
      _variables,
    );

    return parser.parse();
  }

  num? _asNumber(Object? value) {
    if (value is num) {
      return value;
    }

    if (value is String && value.runes.length == 1) {
      return value.runes.first;
    }

    return null;
  }

  String? _stripStringLiteral(String value) {
    final String trimmed = value.trim();

    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      return _convertEscapeSequences(
        trimmed.substring(
          1,
          trimmed.length - 1,
        ),
      );
    }

    return null;
  }

  String? _stripCharacterLiteral(String value) {
    final String trimmed = value.trim();

    if (trimmed.length >= 3 &&
        trimmed.startsWith("'") &&
        trimmed.endsWith("'")) {
      final String content = trimmed.substring(
        1,
        trimmed.length - 1,
      );

      final String converted = _convertEscapeSequences(content);

      if (converted.isEmpty) {
        return null;
      }

      return String.fromCharCode(
        converted.runes.first,
      );
    }

    return null;
  }

  List<_FormatSpecifier> _readAllFormatSpecifiers(
    String format,
  ) {
    final List<_FormatSpecifier> specifiers = <_FormatSpecifier>[];

    int index = 0;

    while (index < format.length) {
      if (format[index] != '%') {
        index++;
        continue;
      }

      if (index + 1 < format.length && format[index + 1] == '%') {
        index += 2;
        continue;
      }

      final _FormatSpecifier? specifier = _readFormatSpecifier(format, index);

      if (specifier == null) {
        index++;
        continue;
      }

      specifiers.add(specifier);
      index = specifier.endIndex;
    }

    return specifiers;
  }

  _FormatSpecifier? _readFormatSpecifier(
    String format,
    int percentIndex,
  ) {
    int index = percentIndex + 1;
    int? precision;

    while (index < format.length &&
        RegExp(r'[-+ #0-9*]').hasMatch(format[index])) {
      index++;
    }

    if (index < format.length && format[index] == '.') {
      index++;
      final int precisionStart = index;

      while (
          index < format.length && RegExp(r'[0-9]').hasMatch(format[index])) {
        index++;
      }

      if (index > precisionStart) {
        precision = int.tryParse(
          format.substring(
            precisionStart,
            index,
          ),
        );
      }
    }

    if (index >= format.length) {
      return null;
    }

    if (format.startsWith('lf', index)) {
      return _FormatSpecifier(
        kind: _FormatKind.doubleValue,
        endIndex: index + 2,
        precision: precision,
      );
    }

    final String type = format[index];

    final _FormatKind? kind;

    switch (type) {
      case 'd':
      case 'i':
        kind = _FormatKind.integer;
        break;
      case 'u':
        kind = _FormatKind.unsignedInteger;
        break;
      case 'f':
        kind = _FormatKind.floatValue;
        break;
      case 'c':
        kind = _FormatKind.character;
        break;
      case 's':
        kind = _FormatKind.stringValue;
        break;
      default:
        kind = null;
    }

    if (kind == null) {
      return null;
    }

    return _FormatSpecifier(
      kind: kind,
      endIndex: index + 1,
      precision: precision,
    );
  }

  List<String> _splitTopLevelArguments(
    String source,
  ) {
    final List<String> arguments = <String>[];

    int start = 0;
    int parenthesisDepth = 0;
    int bracketDepth = 0;
    int braceDepth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool escaped = false;

    for (int index = 0; index < source.length; index++) {
      final String character = source[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        continue;
      }

      if (insideSingleQuote || insideDoubleQuote) {
        continue;
      }

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        parenthesisDepth--;
      } else if (character == '[') {
        bracketDepth++;
      } else if (character == ']') {
        bracketDepth--;
      } else if (character == '{') {
        braceDepth++;
      } else if (character == '}') {
        braceDepth--;
      } else if (character == ',' &&
          parenthesisDepth == 0 &&
          bracketDepth == 0 &&
          braceDepth == 0) {
        arguments.add(
          source.substring(start, index).trim(),
        );

        start = index + 1;
      }
    }

    arguments.add(source.substring(start).trim());
    return arguments;
  }

  _StatementBody _readStatementBody(
    String source,
    int startIndex,
  ) {
    final int bodyStart = _skipWhitespace(source, startIndex);

    if (bodyStart >= source.length) {
      return const _StatementBody.invalid();
    }

    if (source[bodyStart] == '{') {
      final int bodyEnd = _findMatchingDelimiter(
        source,
        bodyStart,
        '{',
        '}',
      );

      if (bodyEnd < 0) {
        return const _StatementBody.invalid();
      }

      return _StatementBody(
        source: source.substring(
          bodyStart + 1,
          bodyEnd,
        ),
        endIndex: bodyEnd + 1,
      );
    }

    final int statementEnd = _findStatementEnd(
      source,
      bodyStart,
    );

    if (statementEnd < 0) {
      return const _StatementBody.invalid();
    }

    return _StatementBody(
      source: source.substring(
        bodyStart,
        statementEnd + 1,
      ),
      endIndex: statementEnd + 1,
    );
  }

  String _extractMainBody(String source) {
    final RegExp mainPattern = RegExp(
      r'\b(?:int|void)\s+main\s*\([^)]*\)\s*\{',
      multiLine: true,
    );

    final RegExpMatch? match = mainPattern.firstMatch(source);

    if (match == null) {
      return source;
    }

    final int openingBrace = source.indexOf('{', match.start);

    final int closingBrace = _findMatchingDelimiter(
      source,
      openingBrace,
      '{',
      '}',
    );

    if (closingBrace < 0) {
      return source.substring(openingBrace + 1);
    }

    return source.substring(
      openingBrace + 1,
      closingBrace,
    );
  }

  String _removeComments(String source) {
    final StringBuffer result = StringBuffer();

    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool insideLineComment = false;
    bool insideBlockComment = false;
    bool escaped = false;

    int index = 0;

    while (index < source.length) {
      final String character = source[index];

      final String nextCharacter =
          index + 1 < source.length ? source[index + 1] : '';

      if (insideLineComment) {
        if (character == '\n') {
          insideLineComment = false;
          result.write('\n');
        }

        index++;
        continue;
      }

      if (insideBlockComment) {
        if (character == '*' && nextCharacter == '/') {
          insideBlockComment = false;
          index += 2;
          continue;
        }

        if (character == '\n') {
          result.write('\n');
        }

        index++;
        continue;
      }

      if (escaped) {
        result.write(character);
        escaped = false;
        index++;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        result.write(character);
        escaped = true;
        index++;
        continue;
      }

      if (!insideSingleQuote &&
          !insideDoubleQuote &&
          character == '/' &&
          nextCharacter == '/') {
        insideLineComment = true;
        index += 2;
        continue;
      }

      if (!insideSingleQuote &&
          !insideDoubleQuote &&
          character == '/' &&
          nextCharacter == '*') {
        insideBlockComment = true;
        index += 2;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
      } else if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
      }

      result.write(character);
      index++;
    }

    return result.toString();
  }

  int _findStatementEnd(
    String source,
    int startIndex,
  ) {
    int parenthesisDepth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool escaped = false;

    for (int index = startIndex; index < source.length; index++) {
      final String character = source[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        continue;
      }

      if (insideSingleQuote || insideDoubleQuote) {
        continue;
      }

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        parenthesisDepth--;
      } else if (character == ';' && parenthesisDepth == 0) {
        return index;
      }
    }

    return -1;
  }

  int _skipToStatementEnd(
    String source,
    int startIndex,
  ) {
    final int statementEnd = _findStatementEnd(source, startIndex);

    return statementEnd < 0 ? source.length : statementEnd + 1;
  }

  int _findMatchingDelimiter(
    String source,
    int openingIndex,
    String openingCharacter,
    String closingCharacter,
  ) {
    int depth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool escaped = false;

    for (int index = openingIndex; index < source.length; index++) {
      final String character = source[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        continue;
      }

      if (insideSingleQuote || insideDoubleQuote) {
        continue;
      }

      if (character == openingCharacter) {
        depth++;
      } else if (character == closingCharacter) {
        depth--;

        if (depth == 0) {
          return index;
        }
      }
    }

    return -1;
  }

  int _skipWhitespace(
    String source,
    int startIndex,
  ) {
    int index = startIndex;

    while (index < source.length && RegExp(r'\s').hasMatch(source[index])) {
      index++;
    }

    return index;
  }

  bool _startsWithWord(
    String source,
    int index,
    String word,
  ) {
    if (index < 0 || index + word.length > source.length) {
      return false;
    }

    if (source.substring(
          index,
          index + word.length,
        ) !=
        word) {
      return false;
    }

    final int beforeIndex = index - 1;
    final int afterIndex = index + word.length;

    if (beforeIndex >= 0 &&
        _isIdentifierCharacter(
          source[beforeIndex],
        )) {
      return false;
    }

    if (afterIndex < source.length &&
        _isIdentifierCharacter(
          source[afterIndex],
        )) {
      return false;
    }

    return true;
  }

  bool _isIdentifierCharacter(String character) {
    return RegExp(
      r'[A-Za-z0-9_]',
    ).hasMatch(character);
  }

  String _removeOuterParentheses(
    String expression,
  ) {
    String result = expression.trim();

    while (
        result.length >= 2 && result.startsWith('(') && result.endsWith(')')) {
      final int closingIndex = _findMatchingDelimiter(
        result,
        0,
        '(',
        ')',
      );

      if (closingIndex != result.length - 1) {
        break;
      }

      result = result
          .substring(
            1,
            result.length - 1,
          )
          .trim();
    }

    return result;
  }

  int _findTopLevelOperator(
    String expression,
    String operator,
  ) {
    int parenthesisDepth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;
    bool escaped = false;

    for (int index = 0; index <= expression.length - operator.length; index++) {
      final String character = expression[index];

      if (escaped) {
        escaped = false;
        continue;
      }

      if ((insideSingleQuote || insideDoubleQuote) && character == r'\') {
        escaped = true;
        continue;
      }

      if (!insideDoubleQuote && character == "'") {
        insideSingleQuote = !insideSingleQuote;
        continue;
      }

      if (!insideSingleQuote && character == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        continue;
      }

      if (insideSingleQuote || insideDoubleQuote) {
        continue;
      }

      if (character == '(') {
        parenthesisDepth++;
        continue;
      }

      if (character == ')') {
        parenthesisDepth--;
        continue;
      }

      if (parenthesisDepth == 0 &&
          expression.startsWith(
            operator,
            index,
          )) {
        return index;
      }
    }

    return -1;
  }

  void _writeOutput(String text) {
    if (_output.length >= maximumOutputLength) {
      return;
    }

    final int remainingLength = maximumOutputLength - _output.length;

    if (text.length <= remainingLength) {
      _output.write(text);
    } else {
      _output.write(
        text.substring(0, remainingLength),
      );
    }
  }

  String _convertEscapeSequences(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\0', '\u0000')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\', '\\');
  }
}

class _StatementBody {
  const _StatementBody({
    required this.source,
    required this.endIndex,
  }) : isValid = true;

  const _StatementBody.invalid()
      : source = '',
        endIndex = -1,
        isValid = false;

  final String source;
  final int endIndex;
  final bool isValid;
}

class _VariableValue {
  const _VariableValue({
    required this.type,
    required this.value,
  });

  final _CValueType type;
  final Object value;
}

enum _CValueType {
  integer,
  unsignedInteger,
  floatValue,
  doubleValue,
  character,
  stringValue,
}

enum _FormatKind {
  integer,
  unsignedInteger,
  floatValue,
  doubleValue,
  character,
  stringValue,
}

class _FormatSpecifier {
  const _FormatSpecifier({
    required this.kind,
    required this.endIndex,
    this.precision,
  });

  final _FormatKind kind;
  final int endIndex;
  final int? precision;
}

class _NumericExpressionParser {
  _NumericExpressionParser(
    this.source,
    this.variables,
  );

  final String source;
  final Map<String, _VariableValue> variables;

  int _cursor = 0;

  num? parse() {
    final num? value = _parseAdditionSubtraction();

    _skipWhitespace();

    if (_cursor != source.length) {
      return null;
    }

    return value;
  }

  num? _parseAdditionSubtraction() {
    final num? initialValue = _parseMultiplicationDivision();

    if (initialValue == null) {
      return null;
    }

    num value = initialValue;

    while (true) {
      _skipWhitespace();

      if (_match('+')) {
        final num? rightValue = _parseMultiplicationDivision();

        if (rightValue == null) {
          return null;
        }

        value = value + rightValue;
        continue;
      }

      if (_match('-')) {
        final num? rightValue = _parseMultiplicationDivision();

        if (rightValue == null) {
          return null;
        }

        value = value - rightValue;
        continue;
      }

      return value;
    }
  }

  num? _parseMultiplicationDivision() {
    final num? initialValue = _parseUnary();

    if (initialValue == null) {
      return null;
    }

    num value = initialValue;

    while (true) {
      _skipWhitespace();

      if (_match('*')) {
        final num? rightValue = _parseUnary();

        if (rightValue == null) {
          return null;
        }

        value = value * rightValue;
        continue;
      }

      if (_match('/')) {
        final num? rightValue = _parseUnary();

        if (rightValue == null || rightValue == 0) {
          return null;
        }

        if (value is int && rightValue is int) {
          value = value ~/ rightValue;
        } else {
          value = value / rightValue;
        }

        continue;
      }

      if (_match('%')) {
        final num? rightValue = _parseUnary();

        if (rightValue == null || rightValue == 0) {
          return null;
        }

        value = value % rightValue;
        continue;
      }

      return value;
    }
  }

  num? _parseUnary() {
    _skipWhitespace();

    if (_match('+')) {
      return _parseUnary();
    }

    if (_match('-')) {
      final num? value = _parseUnary();
      return value == null ? null : -value;
    }

    return _parsePrimary();
  }

  num? _parsePrimary() {
    _skipWhitespace();

    if (_match('(')) {
      final num? value = _parseAdditionSubtraction();

      _skipWhitespace();

      if (!_match(')')) {
        return null;
      }

      return value;
    }

    if (_cursor >= source.length) {
      return null;
    }

    if (RegExp(r'[0-9.]').hasMatch(source[_cursor])) {
      return _parseNumber();
    }

    if (source[_cursor] == "'") {
      return _parseCharacterLiteral();
    }

    if (RegExp(r'[A-Za-z_]').hasMatch(source[_cursor])) {
      final int start = _cursor;

      while (_cursor < source.length &&
          RegExp(r'[A-Za-z0-9_]').hasMatch(source[_cursor])) {
        _cursor++;
      }

      final String variableName = source.substring(start, _cursor);

      _skipWhitespace();

      // Built-in numeric function support.
      if (_cursor < source.length && source[_cursor] == '(') {
        _cursor++;

        final num? firstArgument = _parseAdditionSubtraction();

        if (firstArgument == null) {
          return null;
        }

        _skipWhitespace();

        if (variableName == 'pow') {
          if (!_match(',')) {
            return null;
          }

          final num? secondArgument = _parseAdditionSubtraction();

          _skipWhitespace();

          if (secondArgument == null || !_match(')')) {
            return null;
          }

          return math.pow(
            firstArgument.toDouble(),
            secondArgument.toDouble(),
          );
        }

        if (!_match(')')) {
          return null;
        }

        switch (variableName) {
          case 'sqrt':
            return math.sqrt(firstArgument.toDouble());

          case 'fabs':
            return firstArgument.toDouble().abs();

          default:
            return null;
        }
      }
      // Array element support:
      // arr[0], arr[i], arr[i + 1], arr[2 * i]
      if (_cursor < source.length && source[_cursor] == '[') {
        _cursor++;

        final num? indexValue = _parseAdditionSubtraction();

        _skipWhitespace();

        if (_cursor >= source.length || source[_cursor] != ']') {
          return null;
        }

        _cursor++;

        if (indexValue == null) {
          return null;
        }

        final Object? arrayValue = variables[variableName]?.value;

        if (arrayValue is! List<Object?>) {
          return null;
        }

        final int arrayIndex = indexValue.toInt();

        if (arrayIndex < 0 || arrayIndex >= arrayValue.length) {
          return null;
        }

        final Object? element = arrayValue[arrayIndex];

        if (element is num) {
          return element;
        }

        if (element is String && element.runes.length == 1) {
          return element.runes.first;
        }

        return null;
      }

      final Object? value = variables[variableName]?.value;

      if (value is num) {
        return value;
      }

      if (value is String && value.runes.length == 1) {
        return value.runes.first;
      }

      return null;
    }

    return null;
  }

  num? _parseNumber() {
    final int start = _cursor;

    bool hasDecimalPoint = false;

    while (_cursor < source.length) {
      final String character = source[_cursor];

      if (RegExp(r'[0-9]').hasMatch(character)) {
        _cursor++;
        continue;
      }

      if (character == '.' && !hasDecimalPoint) {
        hasDecimalPoint = true;
        _cursor++;
        continue;
      }

      break;
    }

    final String token = source.substring(start, _cursor);

    if (hasDecimalPoint) {
      return double.tryParse(token);
    }

    return int.tryParse(token);
  }

  num? _parseCharacterLiteral() {
    if (!_match("'")) {
      return null;
    }

    if (_cursor >= source.length) {
      return null;
    }

    String character;

    if (source[_cursor] == r'\') {
      _cursor++;

      if (_cursor >= source.length) {
        return null;
      }

      final String escaped = source[_cursor];

      switch (escaped) {
        case 'n':
          character = '\n';
          break;
        case 't':
          character = '\t';
          break;
        case 'r':
          character = '\r';
          break;
        case '0':
          character = '\u0000';
          break;
        default:
          character = escaped;
      }

      _cursor++;
    } else {
      character = source[_cursor];
      _cursor++;
    }

    if (!_match("'")) {
      return null;
    }

    return character.runes.first;
  }

  void _skipWhitespace() {
    while (_cursor < source.length && RegExp(r'\s').hasMatch(source[_cursor])) {
      _cursor++;
    }
  }

  bool _match(String character) {
    if (_cursor >= source.length || source[_cursor] != character) {
      return false;
    }

    _cursor++;
    return true;
  }
}
