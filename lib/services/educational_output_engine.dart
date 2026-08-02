class EducationalOutputEngine {
  const EducationalOutputEngine();

  String execute(String code) {
    final Map<String, int> integerVariables = _collectIntegerVariables(code);

    final RegExp printfPattern = RegExp(
      r'printf\s*\(\s*"((?:\\.|[^"\\])*)"'
      r'(?:\s*,\s*([^;]+?))?\s*\)\s*;',
      multiLine: true,
    );

    final Iterable<RegExpMatch> matches = printfPattern.allMatches(code);

    if (matches.isEmpty) {
      return 'Program executed successfully.';
    }

    final StringBuffer output = StringBuffer();

    for (final RegExpMatch match in matches) {
      String text = match.group(1) ?? '';
      final String? argument = match.group(2)?.trim();

      text = _convertEscapeSequences(text);

      if (argument != null && argument.isNotEmpty && text.contains('%d')) {
        final int? outputValue = _evaluateIntegerExpression(
          argument,
          integerVariables,
        );

        if (outputValue != null) {
          text = text.replaceFirst(
            '%d',
            outputValue.toString(),
          );
        }
      }

      output.write(text);
    }

    return output.toString();
  }

  Map<String, int> _collectIntegerVariables(String code) {
    final Map<String, int> integerVariables = <String, int>{};

    final RegExp integerDeclarationPattern = RegExp(
      r'\bint\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(-?\d+)\s*;',
    );

    for (final RegExpMatch match
        in integerDeclarationPattern.allMatches(code)) {
      final String variableName = match.group(1)!;
      final int variableValue = int.parse(match.group(2)!);

      integerVariables[variableName] = variableValue;
    }

    return integerVariables;
  }

  int? _evaluateIntegerExpression(
    String expression,
    Map<String, int> variables,
  ) {
    final String normalized = expression.trim();

    final int? literalValue = int.tryParse(normalized);

    if (literalValue != null) {
      return literalValue;
    }

    if (variables.containsKey(normalized)) {
      return variables[normalized];
    }

    final RegExp expressionPattern = RegExp(
      r'^([A-Za-z_][A-Za-z0-9_]*|-?\d+)\s*([+\-*/%])\s*'
      r'([A-Za-z_][A-Za-z0-9_]*|-?\d+)$',
    );

    final RegExpMatch? match = expressionPattern.firstMatch(normalized);

    if (match == null) {
      return null;
    }

    final int? leftValue = _resolveIntegerOperand(
      match.group(1)!,
      variables,
    );

    final int? rightValue = _resolveIntegerOperand(
      match.group(3)!,
      variables,
    );

    if (leftValue == null || rightValue == null) {
      return null;
    }

    final String operator = match.group(2)!;

    switch (operator) {
      case '+':
        return leftValue + rightValue;
      case '-':
        return leftValue - rightValue;
      case '*':
        return leftValue * rightValue;
      case '/':
        return rightValue == 0 ? null : leftValue ~/ rightValue;
      case '%':
        return rightValue == 0 ? null : leftValue % rightValue;
      default:
        return null;
    }
  }

  int? _resolveIntegerOperand(
    String operand,
    Map<String, int> variables,
  ) {
    return int.tryParse(operand) ?? variables[operand];
  }

  String _convertEscapeSequences(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\\', '\\');
  }
}
