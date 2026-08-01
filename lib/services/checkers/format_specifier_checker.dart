import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class FormatSpecifierChecker implements CompilerChecker {
  static const Map<String, String> _expectedTypeBySpecifier = {
    '%c': 'char',
    '%d': 'int',
    '%f': 'float',
    '%lf': 'double',
    '%s': 'string',
  };

  CompilerResult check(String sourceCode) {
    final variableTypes = _collectVariableTypes(sourceCode);
    final lines = sourceCode.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final functionCall = _extractInputOutputCall(line);

      if (functionCall == null) {
        continue;
      }

      final formatSpecifiers =
          _extractFormatSpecifiers(functionCall.formatString);

      for (final specifier in formatSpecifiers) {
        if (!_expectedTypeBySpecifier.containsKey(specifier)) {
          return CompilerResult.failure(
            error: "Unsupported format specifier '$specifier'.",
            explanation:
                "'$specifier' HSC পাঠ্যবইয়ের অনুমোদিত Format Specifier নয়।\n\n"
                "বৈধ Format Specifier:\n"
                "• %c — char\n"
                "• %d — int\n"
                "• %f — float\n"
                "• %lf — double\n"
                "• %s — string",
            errorLine: i + 1,
          );
        }
      }

      final arguments = _extractArguments(functionCall.arguments);

      if (formatSpecifiers.length != arguments.length) {
        return CompilerResult.failure(
          error: 'Format specifier count does not match variable count.',
          explanation:
              '${_toBanglaNumber(formatSpecifiers.length)}টি Format Specifier ব্যবহার করা হয়েছে, '
              'কিন্তু ${_toBanglaNumber(arguments.length)}টি Variable দেওয়া হয়েছে।',
          errorLine: i + 1,
        );
      }

      for (int j = 0; j < formatSpecifiers.length; j++) {
        final specifier = formatSpecifiers[j];
        final variableName = _normalizeVariableName(arguments[j]);

        final actualType = variableTypes[variableName];

        if (actualType == null) {
          continue;
        }

        final expectedType = _expectedTypeBySpecifier[specifier]!;

        if (expectedType != actualType) {
          return CompilerResult.failure(
            error:
                "Format specifier '$specifier' does not match variable '$variableName'.",
            explanation:
                "'$specifier' $expectedType টাইপ ডাটার জন্য ব্যবহৃত হয়।\n"
                "'$variableName' হলো $actualType টাইপ ভ্যারিয়েবল।",
            errorLine: i + 1,
          );
        }
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Format specifier usage is valid.',
    );
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

      final variables = _splitArguments(declarationBody);

      for (final variablePart in variables) {
        var cleanPart = variablePart.trim();

        // Initial value বাদ দেয়।
        // যেমন: int a = 10;
        if (cleanPart.contains('=')) {
          cleanPart = cleanPart.split('=').first.trim();
        }

        final nameMatch = RegExp(
          r'^([A-Za-z_][A-Za-z0-9_]*)\s*(\[\s*\d*\s*\])?$',
        ).firstMatch(cleanPart);

        if (nameMatch == null) {
          continue;
        }

        final variableName = nameMatch.group(1)!;
        final isArray = nameMatch.group(2) != null;

        if (declaredType == 'char' && isArray) {
          variableTypes[variableName] = 'string';
        } else {
          variableTypes[variableName] = declaredType;
        }
      }
    }

    return variableTypes;
  }

  _FunctionCall? _extractInputOutputCall(String line) {
    final match = RegExp(
      r'\b(printf|scanf)\s*\(\s*"([^"]*)"\s*(?:,\s*(.*?))?\)\s*;?',
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    return _FunctionCall(
      formatString: match.group(2) ?? '',
      arguments: match.group(3) ?? '',
    );
  }

  List<String> _extractFormatSpecifiers(String formatString) {
    return RegExp(r'%(?:lf|[A-Za-z])')
        .allMatches(formatString)
        .map((match) => match.group(0)!)
        .toList();
  }

  List<String> _extractArguments(String argumentsText) {
    if (argumentsText.trim().isEmpty) {
      return [];
    }

    return _splitArguments(argumentsText)
        .map((argument) => argument.trim())
        .where((argument) => argument.isNotEmpty)
        .toList();
  }

  List<String> _splitArguments(String text) {
    final parts = <String>[];
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

      if (character == ',' && parenthesisDepth == 0 && bracketDepth == 0) {
        parts.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
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

  String _toBanglaNumber(int number) {
    const englishDigits = '0123456789';
    const banglaDigits = '০১২৩৪৫৬৭৮৯';

    return number.toString().split('').map((digit) {
      final index = englishDigits.indexOf(digit);

      if (index == -1) {
        return digit;
      }

      return banglaDigits[index];
    }).join();
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}

class _FunctionCall {
  final String formatString;
  final String arguments;

  const _FunctionCall({
    required this.formatString,
    required this.arguments,
  });
}
