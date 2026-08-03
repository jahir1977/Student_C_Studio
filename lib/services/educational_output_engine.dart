class EducationalOutputEngine {
  const EducationalOutputEngine();

  String execute(String code) {
    final Map<String, int> integerVariables = _collectIntegerVariables(code);
    _applyIntegerAssignments(
      code,
      integerVariables,
    );
    _applyCompoundAssignments(
      code,
      integerVariables,
    );
    _applyIncrementDecrement(
      code,
      integerVariables,
    );

    code = _filterFalseIfBlocks(
      code,
      integerVariables,
    );

    final RegExp printfPattern = RegExp(
      r'printf\s*\(\s*"((?:\\.|[^"\\])*)"'
      r'(?:\s*,\s*([^;]+?))?\s*\)\s*;',
      multiLine: true,
    );

    final Iterable<RegExpMatch> matches = printfPattern.allMatches(code);

    if (matches.isEmpty) {
      return '';
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

  void _applyIntegerAssignments(
    String code,
    Map<String, int> variables,
  ) {
    final RegExp assignmentPattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+)\s*;',
      multiLine: true,
    );

    for (final RegExpMatch match in assignmentPattern.allMatches(code)) {
      final String variableName = match.group(1)!;
      final String expression = match.group(2)!;

      if (!variables.containsKey(variableName)) {
        continue;
      }

      final int? value = _evaluateIntegerExpression(
        expression,
        variables,
      );

      if (value != null) {
        variables[variableName] = value;
      }
    }
  }

  void _applyCompoundAssignments(
    String code,
    Map<String, int> variables,
  ) {
    final RegExp pattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*([+\-*/%])=\s*([^;]+)\s*;',
      multiLine: true,
    );

    for (final RegExpMatch match in pattern.allMatches(code)) {
      final String variableName = match.group(1)!;
      final String operator = match.group(2)!;
      final String expression = match.group(3)!;

      final int? currentValue = variables[variableName];

      if (currentValue == null) {
        continue;
      }

      final int? value = _evaluateIntegerExpression(
        expression,
        variables,
      );

      if (value == null) {
        continue;
      }

      switch (operator) {
        case '+':
          variables[variableName] = currentValue + value;
          break;
        case '-':
          variables[variableName] = currentValue - value;
          break;
        case '*':
          variables[variableName] = currentValue * value;
          break;
        case '/':
          if (value != 0) {
            variables[variableName] = currentValue ~/ value;
          }
          break;
        case '%':
          if (value != 0) {
            variables[variableName] = currentValue % value;
          }
          break;
      }
    }
  }

  void _applyIncrementDecrement(
    String code,
    Map<String, int> variables,
  ) {
    final RegExp prefixPattern = RegExp(
      r'^\s*(\+\+|--)\s*([A-Za-z_][A-Za-z0-9_]*)\s*;',
      multiLine: true,
    );

    for (final RegExpMatch match in prefixPattern.allMatches(code)) {
      final String operator = match.group(1)!;
      final String variableName = match.group(2)!;

      final int? currentValue = variables[variableName];

      if (currentValue == null) {
        continue;
      }

      variables[variableName] =
          operator == '++' ? currentValue + 1 : currentValue - 1;
    }
    final RegExp postfixPattern = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(\+\+|--)\s*;',
      multiLine: true,
    );

    for (final RegExpMatch match in postfixPattern.allMatches(code)) {
      final String variableName = match.group(1)!;
      final String operator = match.group(2)!;

      final int? currentValue = variables[variableName];

      if (currentValue == null) {
        continue;
      }

      variables[variableName] =
          operator == '++' ? currentValue + 1 : currentValue - 1;
    }
  }

  String _filterFalseIfBlocks(
    String code,
    Map<String, int> variables,
  ) {
    bool evaluateCondition(
      String variable,
      String operator,
      int value,
    ) {
      final int? current = variables[variable];

      if (current == null) {
        return false;
      }

      switch (operator) {
        case '>':
          return current > value;
        case '<':
          return current < value;
        case '>=':
          return current >= value;
        case '<=':
          return current <= value;
        case '==':
          return current == value;
        case '!=':
          return current != value;
        default:
          return false;
      }
    }

    final RegExp ifElsePattern = RegExp(
      r'if\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'(==|!=|>=|<=|>|<)\s*(-?\d+)\s*\)\s*'
      r'\{([^{}]*)\}\s*else\s*\{([^{}]*)\}',
      multiLine: true,
    );

    final RegExp ifPattern = RegExp(
      r'if\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*'
      r'(==|!=|>=|<=|>|<)\s*(-?\d+)\s*\)\s*'
      r'\{([^{}]*)\}',
      multiLine: true,
    );

    String filteredCode = code;

    while (true) {
      bool changed = false;

      filteredCode = filteredCode.replaceAllMapped(
        ifElsePattern,
        (Match match) {
          changed = true;

          final String variable = match.group(1)!;
          final String operator = match.group(2)!;
          final int value = int.parse(match.group(3)!);
          final String trueBody = match.group(4)!;
          final String falseBody = match.group(5)!;

          return evaluateCondition(variable, operator, value)
              ? trueBody
              : falseBody;
        },
      );

      filteredCode = filteredCode.replaceAllMapped(
        ifPattern,
        (Match match) {
          changed = true;

          final String variable = match.group(1)!;
          final String operator = match.group(2)!;
          final int value = int.parse(match.group(3)!);
          final String body = match.group(4)!;

          return evaluateCondition(variable, operator, value) ? body : '';
        },
      );

      if (!changed) {
        break;
      }
    }

    return filteredCode;
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
