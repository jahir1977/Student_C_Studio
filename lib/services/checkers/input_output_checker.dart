import '../../models/compiler_result.dart';

class InputOutputChecker {
  CompilerResult check(String sourceCode) {
    final variableTypes = _collectVariableTypes(sourceCode);
    final lines = sourceCode.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final functionName = _findFunctionName(line);

      if (functionName == null) {
        continue;
      }

      // দুটি Single Quote ('')-কে Double Quote (") হিসেবে ব্যবহার করা হয়েছে।
      if (_usesTwoSingleQuotes(line, functionName)) {
        return CompilerResult.failure(
          error: 'Invalid quotation mark in $functionName().',
          explanation:
              '$functionName()-এর Format String লেখার জন্য একটি Double Quote (") '
              'ব্যবহার করতে হবে।\n'
              'দুটি Single Quote (\'\') কখনো Double Quote (") নয়।',
          errorLine: i + 1,
        );
      }

      // একটি Single Quote দিয়ে Format String লেখা হয়েছে।
      if (_usesSingleQuotes(line, functionName)) {
        return CompilerResult.failure(
          error: 'Invalid quotation mark in $functionName().',
          explanation:
              '$functionName()-এর Format String অবশ্যই Double Quote (")-এর মধ্যে লিখতে হবে।\n'
              "Single Quote (') ব্যবহার করা যাবে না।",
          errorLine: i + 1,
        );
      }

      final functionCall = _extractFunctionCall(line, functionName);

      if (functionCall == null) {
        continue;
      }

      final trailingText = functionCall.trailingText.trim();

      // Format String-এর পরে কিছু নেই।
      if (trailingText.isEmpty) {
        continue;
      }

      // Format String-এর পরে Variable আছে, কিন্তু কমা নেই।
      if (!trailingText.startsWith(',')) {
        return CompilerResult.failure(
          error: 'Missing comma after $functionName format string.',
          explanation:
              '$functionName()-এর Format String এবং Variable-এর মাঝে কমা (,) দিতে হবে।',
          errorLine: i + 1,
        );
      }

      final argumentsText = trailingText.substring(1).trim();
      final arguments = _splitArguments(argumentsText);

      if (functionName == 'printf') {
        final result = _checkPrintfArguments(
          arguments: arguments,
          lineNumber: i + 1,
        );

        if (result != null) {
          return result;
        }
      }

      if (functionName == 'scanf') {
        final result = _checkScanfArguments(
          arguments: arguments,
          variableTypes: variableTypes,
          lineNumber: i + 1,
        );

        if (result != null) {
          return result;
        }
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Input and output syntax is valid.',
    );
  }

  String? _findFunctionName(String line) {
    final match = RegExp(
      r'\b(printf|scanf)\s*\(',
    ).firstMatch(line);

    return match?.group(1);
  }

  bool _usesTwoSingleQuotes(String line, String functionName) {
    final pattern = RegExp(
      '\\b$functionName\\s*\\(\\s*\'\'',
    );

    return pattern.hasMatch(line);
  }

  bool _usesSingleQuotes(String line, String functionName) {
    final pattern = RegExp(
      '\\b$functionName\\s*\\(\\s*\'',
    );

    return pattern.hasMatch(line);
  }

  _InputOutputCall? _extractFunctionCall(
    String line,
    String functionName,
  ) {
    final pattern = RegExp(
      '\\b$functionName\\s*\\(\\s*"([^"]*)"\\s*(.*?)\\)\\s*;?',
    );

    final match = pattern.firstMatch(line);

    if (match == null) {
      return null;
    }

    return _InputOutputCall(
      formatString: match.group(1) ?? '',
      trailingText: match.group(2) ?? '',
    );
  }

  CompilerResult? _checkPrintfArguments({
    required List<String> arguments,
    required int lineNumber,
  }) {
    for (final argument in arguments) {
      final trimmedArgument = argument.trim();

      if (!trimmedArgument.startsWith('&')) {
        continue;
      }

      final variableName = _normalizeVariableName(trimmedArgument);

      return CompilerResult.failure(
        error:
            "Address operator is not allowed before '$variableName' in printf().",
        explanation:
            "printf()-এ '$variableName' ভ্যারিয়েবলের আগে Address Operator (&) "
            'ব্যবহার করা যাবে না।',
        errorLine: lineNumber,
      );
    }

    return null;
  }

  CompilerResult? _checkScanfArguments({
    required List<String> arguments,
    required Map<String, String> variableTypes,
    required int lineNumber,
  }) {
    for (final argument in arguments) {
      final trimmedArgument = argument.trim();

      if (trimmedArgument.isEmpty) {
        continue;
      }

      final hasAddressOperator = trimmedArgument.startsWith('&');
      final variableName = _normalizeVariableName(trimmedArgument);
      final variableType = variableTypes[variableName];

      if (variableType == 'string') {
        if (hasAddressOperator) {
          return CompilerResult.failure(
            error:
                "Unnecessary address operator before string '$variableName'.",
            explanation:
                "String Input নেওয়ার সময় '$variableName'-এর আগে Address Operator (&) "
                'দিতে হবে না।',
            errorLine: lineNumber,
          );
        }

        continue;
      }

      if (!hasAddressOperator) {
        return CompilerResult.failure(
          error:
              "Missing address operator before variable '$variableName'.",
          explanation:
              "scanf()-এ '$variableName' ভ্যারিয়েবলের আগে Address Operator (&) দিতে হবে।",
          errorLine: lineNumber,
        );
      }
    }

    return null;
  }

  Map<String, String> _collectVariableTypes(String sourceCode) {
    final variableTypes = <String, String>{};
    final lines = sourceCode.split('\n');

    final declarationPattern = RegExp(
      r'^\s*(int|float|double|char)\s+([^;]+)\s*;\s*$',
    );

    for (final line in lines) {
      final match = declarationPattern.firstMatch(line);

      if (match == null) {
        continue;
      }

      final declaredType = match.group(1)!;
      final declarationBody = match.group(2)!.trim();

      // int main() যেন Variable Declaration হিসেবে ধরা না হয়।
      if (declarationBody.contains('(')) {
        continue;
      }

      final declarations = _splitArguments(declarationBody);

      for (final declaration in declarations) {
        var cleanDeclaration = declaration.trim();

        // Initial Value বাদ দেওয়া হয়।
        // যেমন: int number = 10;
        if (cleanDeclaration.contains('=')) {
          cleanDeclaration =
              cleanDeclaration.split('=').first.trim();
        }

        final variableMatch = RegExp(
          r'^([A-Za-z_][A-Za-z0-9_]*)\s*(\[\s*\d*\s*\])?$',
        ).firstMatch(cleanDeclaration);

        if (variableMatch == null) {
          continue;
        }

        final variableName = variableMatch.group(1)!;
        final isArray = variableMatch.group(2) != null;

        if (declaredType == 'char' && isArray) {
          variableTypes[variableName] = 'string';
        } else {
          variableTypes[variableName] = declaredType;
        }
      }
    }

    return variableTypes;
  }

  List<String> _splitArguments(String text) {
    if (text.trim().isEmpty) {
      return [];
    }

    final arguments = <String>[];
    final buffer = StringBuffer();

    int parenthesisDepth = 0;
    int bracketDepth = 0;

    for (int i = 0; i < text.length; i++) {
      final character = text[i];

      if (character == '(') {
        parenthesisDepth++;
      } else if (character == ')') {
        parenthesisDepth--;
      } else if (character == '[') {
        bracketDepth++;
      } else if (character == ']') {
        bracketDepth--;
      }

      if (character == ',' &&
          parenthesisDepth == 0 &&
          bracketDepth == 0) {
        arguments.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }

    if (buffer.isNotEmpty) {
      arguments.add(buffer.toString().trim());
    }

    return arguments
        .where((argument) => argument.isNotEmpty)
        .toList();
  }

  String _normalizeVariableName(String argument) {
    var value = argument.trim();

    while (value.startsWith('&')) {
      value = value.substring(1).trim();
    }

    final match = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*)',
    ).firstMatch(value);

    return match?.group(1) ?? value;
  }
}

class _InputOutputCall {
  final String formatString;
  final String trailingText;

  const _InputOutputCall({
    required this.formatString,
    required this.trailingText,
  });
}