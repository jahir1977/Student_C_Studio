import '../../models/compiler_result.dart';
import '../models/symbol.dart';
import 'symbol_table.dart';
import '../source_sanitizer.dart';

class IdentifierChecker {
  // Reserved for future IdentifierChecker improvements.
/*
  static const Set<String> _dataTypes = {
    'int',
    'float',
    'double',
    'char',
    'long',
    'short',
  };
*/
  static const Set<String> _reservedWords = {
    'int',
    'float',
    'double',
    'char',
    'long',
    'short',
    'void',
    'return',
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'break',
    'continue',
    'goto',
    'sizeof',
    'printf',
    'scanf',
    'main',
  };

  static CompilerResult? check(String code) {
  final symbolTable = SymbolTable();

  final sanitizedSource = SourceSanitizer.sanitize(code);
  final lines = sanitizedSource.split('\n');

    for (int index = 0; index < lines.length; index++) {
      final lineNumber = index + 1;
      final originalLine = lines[index];

      final line = _removeComments(originalLine).trim();

      if (_shouldIgnoreLine(line)) {
        continue;
      }

      final declarationResult = _checkDeclaration(
        line: line,
        lineNumber: lineNumber,
        symbolTable: symbolTable,
      );

      if (declarationResult.handled) {
        if (declarationResult.error != null) {
          return declarationResult.error;
        }

        continue;
      }

      final identifierError = _checkUsedIdentifiers(
        line: line,
        lineNumber: lineNumber,
        symbolTable: symbolTable,
      );

      if (identifierError != null) {
        return identifierError;
      }
    }

    return null;
  }

  static _DeclarationCheckResult _checkDeclaration({
    required String line,
    required int lineNumber,
    required SymbolTable symbolTable,
  }) {
    final declarationPattern = RegExp(
      r'^(int|float|double|char|long|short)\s+(.+);$',
    );

    final match = declarationPattern.firstMatch(line);

    if (match == null) {
      return const _DeclarationCheckResult(handled: false);
    }

    final type = match.group(1)!;
    final declarationBody = match.group(2)!;

    final declarators = _splitDeclarators(declarationBody);

    for (final declarator in declarators) {
      final name = _extractDeclaredName(declarator);

      if (name == null) {
        continue;
      }

      if (symbolTable.contains(name)) {
        return _DeclarationCheckResult(
          handled: true,
          error: CompilerResult.failure(
            error: "Duplicate declaration of '$name'",
            explanation:
                "একই scope-এর মধ্যে '$name' নামের variable একাধিকবার declaration করা হয়েছে।",
            errorLine: lineNumber,
          ),
        );
      }

      symbolTable.add(
        SymbolInfo(
          name: name,
          type: type,
          declaredLine: lineNumber,
        ),
      );

      final initializer = _extractInitializer(declarator);

      if (initializer != null) {
        final initializerError = _checkExpressionIdentifiers(
          expression: initializer,
          lineNumber: lineNumber,
          symbolTable: symbolTable,
        );

        if (initializerError != null) {
          return _DeclarationCheckResult(
            handled: true,
            error: initializerError,
          );
        }
      }
    }

    return const _DeclarationCheckResult(handled: true);
  }

  static CompilerResult? _checkUsedIdentifiers({
    required String line,
    required int lineNumber,
    required SymbolTable symbolTable,
  }) {
    final cleanedLine = _removeStringAndCharacterLiterals(line);

    final identifiers = RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b')
        .allMatches(cleanedLine)
        .map((match) => match.group(0)!)
        .toList();

    for (final identifier in identifiers) {
      if (_reservedWords.contains(identifier)) {
        continue;
      }

      if (_isFunctionName(cleanedLine, identifier)) {
        continue;
      }

      if (!symbolTable.contains(identifier)) {
        return CompilerResult.failure(
          error: "Undeclared identifier '$identifier'",
          explanation:
              "'$identifier' variable-টি ব্যবহারের আগে declaration করা হয়নি।",
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  static CompilerResult? _checkExpressionIdentifiers({
    required String expression,
    required int lineNumber,
    required SymbolTable symbolTable,
  }) {
    final cleanedExpression =
        _removeStringAndCharacterLiterals(expression);

    final identifiers = RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b')
        .allMatches(cleanedExpression)
        .map((match) => match.group(0)!)
        .toList();

    for (final identifier in identifiers) {
      if (_reservedWords.contains(identifier)) {
        continue;
      }

      if (!symbolTable.contains(identifier)) {
        return CompilerResult.failure(
          error: "Undeclared identifier '$identifier'",
          explanation:
              "'$identifier' variable-টি ব্যবহারের আগে declaration করা হয়নি।",
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  static List<String> _splitDeclarators(String declarationBody) {
    final parts = <String>[];
    final buffer = StringBuffer();

    int bracketDepth = 0;
    bool insideSingleQuote = false;
    bool insideDoubleQuote = false;

    for (int i = 0; i < declarationBody.length; i++) {
      final char = declarationBody[i];

      if (char == "'" && !insideDoubleQuote) {
        insideSingleQuote = !insideSingleQuote;
      } else if (char == '"' && !insideSingleQuote) {
        insideDoubleQuote = !insideDoubleQuote;
      }

      if (!insideSingleQuote && !insideDoubleQuote) {
        if (char == '[' || char == '(') {
          bracketDepth++;
        } else if (char == ']' || char == ')') {
          bracketDepth--;
        }

        if (char == ',' && bracketDepth == 0) {
          parts.add(buffer.toString().trim());
          buffer.clear();
          continue;
        }
      }

      buffer.write(char);
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }

    return parts;
  }

  static String? _extractDeclaredName(String declarator) {
    final leftSide = declarator.split('=').first.trim();

    final match = RegExp(
      r'^\**\s*([A-Za-z_][A-Za-z0-9_]*)',
    ).firstMatch(leftSide);

    return match?.group(1);
  }

  static String? _extractInitializer(String declarator) {
    final equalsIndex = declarator.indexOf('=');

    if (equalsIndex == -1) {
      return null;
    }

    return declarator.substring(equalsIndex + 1).trim();
  }

  static String _removeComments(String line) {
    final commentIndex = line.indexOf('//');

    if (commentIndex == -1) {
      return line;
    }

    return line.substring(0, commentIndex);
  }

  static String _removeStringAndCharacterLiterals(String line) {
    return line
        .replaceAll(RegExp(r'"(?:\\.|[^"\\])*"'), ' ')
        .replaceAll(RegExp(r"'(?:\\.|[^'\\])*'"), ' ');
  }

  static bool _shouldIgnoreLine(String line) {
    if (line.isEmpty) {
      return true;
    }

    if (line.startsWith('#')) {
      return true;
    }

    if (line == '{' || line == '}') {
      return true;
    }

    if (RegExp(
      r'^(int|float|double|char|long|short|void)\s+'
      r'[A-Za-z_][A-Za-z0-9_]*\s*\([^;]*\)\s*\{?$',
    ).hasMatch(line)) {
      return true;
    }

    if (RegExp(
      r'^(if|else\s+if|for|while|switch)\s*\(',
    ).hasMatch(line)) {
      return true;
    }

    if (line == 'else' || line.startsWith('else {')) {
      return true;
    }

    if (line == 'do' || line.startsWith('do {')) {
      return true;
    }

    if (RegExp(
  r'^[A-Za-z_][A-Za-z0-9_]*\s*:$',
).hasMatch(line)) {
  return true;
}

if (RegExp(
  r'^goto\s+[A-Za-z_][A-Za-z0-9_]*\s*;$',
).hasMatch(line)) {
  return true;
}

return false;
  }

  static bool _isFunctionName(String line, String identifier) {
    return RegExp(
      '\\b${RegExp.escape(identifier)}\\s*\\(',
    ).hasMatch(line);
  }
}

class _DeclarationCheckResult {
  final bool handled;
  final CompilerResult? error;

  const _DeclarationCheckResult({
    required this.handled,
    this.error,
  });
}