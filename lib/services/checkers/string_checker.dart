import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class StringChecker {
  static CompilerResult check(String code) {
    final List<String> lines = _sanitizeCode(code);

    final CompilerResult? declarationResult = _checkStringDeclarations(lines);

    if (declarationResult != null) {
      return declarationResult;
    }

    final Map<String, _StringSymbol> stringSymbols =
        _collectStringSymbols(lines);

    final Set<String> nonStringVariables =
        _collectNonStringVariables(lines, stringSymbols);

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      final int lineNumber = i + 1;

      if (line.isEmpty) {
        continue;
      }

      final List<CompilerResult? Function()> checks = [
        () => _checkWholeStringAssignment(
              line,
              lineNumber,
              stringSymbols,
            ),
        () => _checkScanf(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkGets(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkPuts(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkPrintf(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkStrlen(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkStrcpy(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkStrcat(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
        () => _checkStrcmp(
              line,
              lineNumber,
              stringSymbols,
              nonStringVariables,
            ),
      ];

      for (final check in checks) {
        final CompilerResult? result = check();

        if (result != null) {
          return result;
        }
      }
    }

    return CompilerResult.success(
      output: '',
    );
  }

  static CompilerResult? _checkStringDeclarations(
    List<String> lines,
  ) {
    final RegExp declarationPattern = RegExp(
      r'^\s*char\s+([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'\[\s*([^\]]*)\s*\]\s*'
      r'(?:=\s*(.+?))?\s*;\s*$',
    );

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      final Match? match = declarationPattern.firstMatch(line);

      if (match == null) {
        continue;
      }

      final String sizeText = (match.group(2) ?? '').trim();
      final String? initializerText = match.group(3)?.trim();
      final int lineNumber = i + 1;

      if (sizeText.isEmpty && initializerText == null) {
        return CompilerResult.failure(
          error: 'Array size is missing.',
          explanation: 'স্ট্রিং ঘোষণার সময় অ্যারের সাইজ উল্লেখ করতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (sizeText == '0') {
        return CompilerResult.failure(
          error: 'Array size cannot be zero.',
          explanation: 'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ শূন্য হতে পারে না।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^-\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'Array size cannot be negative.',
          explanation: 'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ ঋণাত্মক হতে পারে না।',
          errorLine: lineNumber,
        );
      }

      if (RegExp(r'^\d+\.\d+$').hasMatch(sizeText)) {
        return CompilerResult.failure(
          error: 'Array size must be an integer.',
          explanation:
              'স্ট্রিং ঘোষণার জন্য অ্যারের সাইজ অবশ্যই পূর্ণসংখ্যা হতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (initializerText == null) {
        continue;
      }

      if (_isSingleQuotedValue(initializerText)) {
        return CompilerResult.failure(
          error: 'String literal must use double quotes.',
          explanation: 'স্ট্রিং লেখার জন্য ডাবল কোট ব্যবহার করতে হবে। '
              'সিঙ্গেল কোট শুধু একটি ক্যারেক্টারের জন্য ব্যবহৃত হয়।',
          errorLine: lineNumber,
        );
      }

      if (!_isStringLiteral(initializerText)) {
        return CompilerResult.failure(
          error: 'Invalid string initializer.',
          explanation: 'স্ট্রিংয়ের মান ডাবল কোটের মধ্যে লিখতে হবে।',
          errorLine: lineNumber,
        );
      }

      if (sizeText.isEmpty) {
        continue;
      }

      final int? declaredSize = int.tryParse(sizeText);

      if (declaredSize == null) {
        continue;
      }

      final int stringLength = _getStringLiteralLength(initializerText);

      final int requiredSize = stringLength + 1;

      if (requiredSize > declaredSize) {
        return CompilerResult.failure(
          error: 'String initializer exceeds array size.',
          explanation: 'স্ট্রিংটি সংরক্ষণ করতে নাল ক্যারেক্টারসহ কমপক্ষে '
              '${_toBanglaNumber(requiredSize)} ঘর প্রয়োজন, '
              'কিন্তু অ্যারের সাইজ '
              '${_toBanglaNumber(declaredSize)}।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  static Map<String, _StringSymbol> _collectStringSymbols(
    List<String> lines,
  ) {
    final Map<String, _StringSymbol> symbols = {};

    final RegExp declarationPattern = RegExp(
      r'^\s*char\s+(.+?)\s*;\s*$',
    );

    final RegExp declaratorPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'\[\s*([^\]]*)\s*\]\s*'
      r'(?:=\s*(.+))?$',
    );

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();

      final Match? declarationMatch = declarationPattern.firstMatch(line);

      if (declarationMatch == null) {
        continue;
      }

      final String declarationBody = declarationMatch.group(1)!.trim();

      final List<String> declarators = [];
      final StringBuffer buffer = StringBuffer();

      bool insideDoubleQuote = false;
      bool escaped = false;

      for (int index = 0; index < declarationBody.length; index++) {
        final String character = declarationBody[index];

        if (escaped) {
          buffer.write(character);
          escaped = false;
          continue;
        }

        if (insideDoubleQuote && character == r'\') {
          buffer.write(character);
          escaped = true;
          continue;
        }

        if (character == '"') {
          insideDoubleQuote = !insideDoubleQuote;
          buffer.write(character);
          continue;
        }

        if (character == ',' && !insideDoubleQuote) {
          declarators.add(buffer.toString().trim());
          buffer.clear();
          continue;
        }

        buffer.write(character);
      }

      if (buffer.isNotEmpty) {
        declarators.add(buffer.toString().trim());
      }

      for (final String declarator in declarators) {
        final Match? match = declaratorPattern.firstMatch(declarator);

        if (match == null) {
          continue;
        }

        final String name = match.group(1)!;
        final String sizeText = (match.group(2) ?? '').trim();

        final String? initializerText = match.group(3)?.trim();

        int? size;
        int? knownLength;

        if (sizeText.isNotEmpty) {
          size = int.tryParse(sizeText);
        }

        if (initializerText != null && _isStringLiteral(initializerText)) {
          knownLength = _getStringLiteralLength(initializerText);

          if (sizeText.isEmpty) {
            size = knownLength + 1;
          }
        }

        symbols[name] = _StringSymbol(
          name: name,
          size: size,
          declarationLine: i + 1,
          knownLength: knownLength,
        );
      }
    }

    return symbols;
  }

  static Set<String> _collectNonStringVariables(
    List<String> lines,
    Map<String, _StringSymbol> stringSymbols,
  ) {
    final Set<String> variables = {};

    final RegExp declarationPattern = RegExp(
      r'^\s*(?:int|float|double|long|short|char)\s+'
      r'([A-Za-z_][A-Za-z0-9_]*)\b',
    );

    for (final String line in lines) {
      final Match? match = declarationPattern.firstMatch(line.trim());

      if (match == null) {
        continue;
      }

      final String name = match.group(1)!;

      if (!stringSymbols.containsKey(name)) {
        variables.add(name);
      }
    }

    return variables;
  }

  static CompilerResult? _checkWholeStringAssignment(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
  ) {
    if (RegExp(r'^\s*char\b').hasMatch(line)) {
      return null;
    }

    final RegExp assignmentPattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*;\s*$',
    );

    final Match? match = assignmentPattern.firstMatch(line);

    if (match == null) {
      return null;
    }

    final String leftSide = match.group(1)!;

    if (!stringSymbols.containsKey(leftSide)) {
      return null;
    }

    return CompilerResult.failure(
      error: 'A string array cannot be assigned with = after declaration.',
      explanation:
          'ঘোষণার পরে = চিহ্ন দিয়ে পুরো স্ট্রিং অ্যারেতে মান বসানো যায় না। '
          'এ ক্ষেত্রে strcpy() ব্যবহার করতে হবে।',
      errorLine: lineNumber,
    );
  }

  static CompilerResult? _checkScanf(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final RegExp pattern = RegExp(
      r'scanf\s*\(\s*"([^"]*)"\s*,\s*([^)]+?)\s*\)',
    );

    final Match? match = pattern.firstMatch(line);

    if (match == null) {
      return null;
    }

    final String format = match.group(1)!;

    if (!format.contains('%s')) {
      return null;
    }

    final String argument = match.group(2)!.trim();

    if (argument.startsWith('&')) {
      final String variableName = argument.substring(1).trim();

      if (stringSymbols.containsKey(variableName)) {
        return CompilerResult.failure(
          error: 'Do not use & with a string array.',
          explanation: 'scanf() দিয়ে স্ট্রিং ইনপুট নেওয়ার সময় '
              'অ্যারের নামের আগে & চিহ্ন দিতে হয় না।',
          errorLine: lineNumber,
        );
      }
    }

    return _validateStringVariableArgument(
      argument: argument,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: '%s ফরম্যাট স্পেসিফায়ারের সঙ্গে একটি char অ্যারে '
          'বা স্ট্রিং ভেরিয়েবল ব্যবহার করতে হবে।',
    );
  }

  static CompilerResult? _checkGets(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bgets\s*\(\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: match.group(1)!.trim(),
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: 'gets() ফাংশনের আর্গুমেন্ট হিসেবে একটি char অ্যারে '
          'বা স্ট্রিং ভেরিয়েবল দিতে হবে।',
    );
  }

  static CompilerResult? _checkPuts(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bputs\s*\(\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String argument = match.group(1)!.trim();

    if (_isStringLiteral(argument)) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: argument,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation:
          'puts() ফাংশনের আর্গুমেন্ট হিসেবে একটি স্ট্রিং ভেরিয়েবল '
          'বা ডাবল কোটের স্ট্রিং দিতে হবে।',
    );
  }

  static CompilerResult? _checkPrintf(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'printf\s*\(\s*"([^"]*)"\s*,\s*(.+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String format = match.group(1)!;

    if (!format.contains('%s')) {
      return null;
    }

    final String argument = match.group(2)!.trim();

    if (_isStringLiteral(argument)) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: argument,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation:
          '%s ফরম্যাট স্পেসিফায়ারের সঙ্গে একটি স্ট্রিং ভেরিয়েবল '
          'বা ডাবল কোটের স্ট্রিং ব্যবহার করতে হবে।',
    );
  }

  static CompilerResult? _checkStrlen(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bstrlen\s*\(\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String argument = match.group(1)!.trim();

    if (_isStringLiteral(argument)) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: argument,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation:
          'strlen() ফাংশনের আর্গুমেন্ট হিসেবে একটি স্ট্রিং দিতে হবে।',
    );
  }

  static CompilerResult? _checkStrcpy(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bstrcpy\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String destination = match.group(1)!.trim();
    final String source = match.group(2)!.trim();

    final CompilerResult? destinationResult = _validateStringVariableArgument(
      argument: destination,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: 'strcpy() ফাংশনের destination আর্গুমেন্ট হিসেবে '
          'একটি স্ট্রিং ভেরিয়েবল দিতে হবে।',
    );

    if (destinationResult != null) {
      return destinationResult;
    }

    if (!_isStringLiteral(source)) {
      final CompilerResult? sourceResult = _validateStringVariableArgument(
        argument: source,
        lineNumber: lineNumber,
        stringSymbols: stringSymbols,
        nonStringVariables: nonStringVariables,
        nonStringExplanation: 'strcpy() ফাংশনের source আর্গুমেন্ট হিসেবে '
            'একটি স্ট্রিং দিতে হবে।',
      );

      if (sourceResult != null) {
        return sourceResult;
      }
    }

    if (_isStringLiteral(source)) {
      final int sourceLength = _getStringLiteralLength(source);

      final int requiredSize = sourceLength + 1;
      final int? destinationSize = stringSymbols[destination]?.size;

      if (destinationSize != null && requiredSize > destinationSize) {
        return CompilerResult.failure(
          error: 'Source string exceeds destination size.',
          explanation: 'উৎস স্ট্রিংটি সংরক্ষণ করতে নাল ক্যারেক্টারসহ '
              'কমপক্ষে ${_toBanglaNumber(requiredSize)} ঘর প্রয়োজন, '
              'কিন্তু destination অ্যারের সাইজ '
              '${_toBanglaNumber(destinationSize)}।',
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  static CompilerResult? _checkStrcat(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bstrcat\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String destination = match.group(1)!.trim();
    final String source = match.group(2)!.trim();

    final CompilerResult? destinationResult = _validateStringVariableArgument(
      argument: destination,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: 'strcat() ফাংশনের destination আর্গুমেন্ট হিসেবে '
          'একটি স্ট্রিং ভেরিয়েবল দিতে হবে।',
    );

    if (destinationResult != null) {
      return destinationResult;
    }

    if (_isStringLiteral(source)) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: source,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: 'strcat() ফাংশনের source আর্গুমেন্ট হিসেবে '
          'একটি স্ট্রিং দিতে হবে।',
    );
  }

  static CompilerResult? _checkStrcmp(
    String line,
    int lineNumber,
    Map<String, _StringSymbol> stringSymbols,
    Set<String> nonStringVariables,
  ) {
    final Match? match = RegExp(
      r'\bstrcmp\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    final String first = match.group(1)!.trim();
    final String second = match.group(2)!.trim();

    final CompilerResult? firstResult = _validateStringValueArgument(
      argument: first,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation:
          'strcmp() ফাংশনের উভয় আর্গুমেন্ট অবশ্যই স্ট্রিং হতে হবে।',
    );

    if (firstResult != null) {
      return firstResult;
    }

    return _validateStringValueArgument(
      argument: second,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation:
          'strcmp() ফাংশনের উভয় আর্গুমেন্ট অবশ্যই স্ট্রিং হতে হবে।',
    );
  }

  static CompilerResult? _validateStringValueArgument({
    required String argument,
    required int lineNumber,
    required Map<String, _StringSymbol> stringSymbols,
    required Set<String> nonStringVariables,
    required String nonStringExplanation,
  }) {
    if (_isStringLiteral(argument)) {
      return null;
    }

    return _validateStringVariableArgument(
      argument: argument,
      lineNumber: lineNumber,
      stringSymbols: stringSymbols,
      nonStringVariables: nonStringVariables,
      nonStringExplanation: nonStringExplanation,
    );
  }

  static CompilerResult? _validateStringVariableArgument({
    required String argument,
    required int lineNumber,
    required Map<String, _StringSymbol> stringSymbols,
    required Set<String> nonStringVariables,
    required String nonStringExplanation,
  }) {
    final String variableName = argument.trim();

    if (stringSymbols.containsKey(variableName)) {
      return null;
    }

    if (nonStringVariables.contains(variableName)) {
      return CompilerResult.failure(
        error: 'Argument must be a string variable.',
        explanation: nonStringExplanation,
        errorLine: lineNumber,
      );
    }

    return CompilerResult.failure(
      error: 'String variable is not declared.',
      explanation:
          '$variableName নামের স্ট্রিং ভেরিয়েবলটি আগে ঘোষণা করতে হবে।',
      errorLine: lineNumber,
    );
  }

  static bool _isStringLiteral(String value) {
    return RegExp(
      r'^"(?:\\.|[^"\\])*"$',
    ).hasMatch(value.trim());
  }

  static bool _isSingleQuotedValue(String value) {
    return RegExp(
      r"^'(?:\\.|[^'\\])*'$",
    ).hasMatch(value.trim());
  }

  static int _getStringLiteralLength(String literal) {
    if (!_isStringLiteral(literal)) {
      return 0;
    }

    final String content = literal.substring(1, literal.length - 1);

    int length = 0;
    int i = 0;

    while (i < content.length) {
      if (content[i] == r'\' && i + 1 < content.length) {
        length++;
        i += 2;
      } else {
        length++;
        i++;
      }
    }

    return length;
  }

  static List<String> _sanitizeCode(String code) {
    final List<String> sanitizedLines = [];
    bool insideBlockComment = false;

    for (final String originalLine in code.split('\n')) {
      final StringBuffer buffer = StringBuffer();
      int i = 0;

      while (i < originalLine.length) {
        if (insideBlockComment) {
          final int commentEnd = originalLine.indexOf('*/', i);

          if (commentEnd == -1) {
            i = originalLine.length;
            continue;
          }

          insideBlockComment = false;
          i = commentEnd + 2;
          continue;
        }

        if (i + 1 < originalLine.length &&
            originalLine[i] == '/' &&
            originalLine[i + 1] == '*') {
          insideBlockComment = true;
          i += 2;
          continue;
        }

        if (i + 1 < originalLine.length &&
            originalLine[i] == '/' &&
            originalLine[i + 1] == '/') {
          break;
        }

        buffer.write(originalLine[i]);
        i++;
      }

      sanitizedLines.add(buffer.toString());
    }

    return sanitizedLines;
  }

  static String _toBanglaNumber(int number) {
    const String english = '0123456789';
    const String bangla = '০১২৩৪৫৬৭৮৯';

    return number
        .toString()
        .split('')
        .map((digit) => bangla[english.indexOf(digit)])
        .join();
  }

  static CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

class _StringSymbol {
  final String name;
  final int? size;
  final int declarationLine;
  final int? knownLength;

  const _StringSymbol({
    required this.name,
    required this.size,
    required this.declarationLine,
    this.knownLength,
  });
}
