import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class HeaderChecker {
  CompilerResult check(String sourceCode) {
    final lines = sourceCode.split('\n');

    final hasStdio = _hasHeader(sourceCode, 'stdio.h');
    final hasMath = _hasHeader(sourceCode, 'math.h');
    final hasString = _hasHeader(sourceCode, 'string.h');
    final hasConio = _hasHeader(sourceCode, 'conio.h');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_containsFunction(line, 'printf') ||
          _containsFunction(line, 'scanf')) {
        if (!hasStdio) {
          return CompilerResult.failure(
            error: "Missing header file 'stdio.h'.",
            explanation:
                "printf() অথবা scanf() ব্যবহারের জন্য #include<stdio.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      if (_containsFunction(line, 'pow') ||
          _containsFunction(line, 'sqrt')) {
        if (!hasMath) {
          return CompilerResult.failure(
            error: "Missing header file 'math.h'.",
            explanation:
                "pow() অথবা sqrt() ব্যবহারের জন্য #include<math.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      if (_containsFunction(line, 'strlen') ||
          _containsFunction(line, 'strcmp')) {
        if (!hasString) {
          return CompilerResult.failure(
            error: "Missing header file 'string.h'.",
            explanation:
                "strlen() অথবা strcmp() ব্যবহারের জন্য #include<string.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      if (_containsFunction(line, 'getch')) {
        if (!hasConio) {
          return CompilerResult.failure(
            error: "Missing header file 'conio.h'.",
            explanation:
                "getch() ব্যবহারের জন্য #include<conio.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Header usage is valid.',
    );
  }

  bool _hasHeader(String sourceCode, String headerName) {
    final escapedHeader = RegExp.escape(headerName);

    return RegExp(
      '#include\\s*<\\s*$escapedHeader\\s*>',
    ).hasMatch(sourceCode);
  }

  bool _containsFunction(String line, String functionName) {
    return RegExp(
      '\\b${RegExp.escape(functionName)}\\s*\\(',
    ).hasMatch(line);
  }

 CompilerResult checkContext(
  CompilerContext context,
) {
  final bool hasStdio =
      context.includedHeaders.contains('stdio.h');

  final bool hasMath =
      context.includedHeaders.contains('math.h');

  final bool hasString =
      context.includedHeaders.contains('string.h');

  final bool hasConio =
      context.includedHeaders.contains('conio.h');

  final List<String> lines =
      context.sanitizedLines;

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];

    if (_containsFunction(line, 'printf') ||
        _containsFunction(line, 'scanf')) {
      if (!hasStdio) {
        return CompilerResult.failure(
          error: "Missing header file 'stdio.h'.",
          explanation:
              "printf() অথবা scanf() ব্যবহারের জন্য #include<stdio.h> লিখতে হবে।",
          errorLine: i + 1,
        );
      }
    }

    if (_containsFunction(line, 'pow') ||
        _containsFunction(line, 'sqrt')) {
      if (!hasMath) {
        return CompilerResult.failure(
          error: "Missing header file 'math.h'.",
          explanation:
              "pow() অথবা sqrt() ব্যবহারের জন্য #include<math.h> লিখতে হবে।",
          errorLine: i + 1,
        );
      }
    }

    if (_containsFunction(line, 'strlen') ||
        _containsFunction(line, 'strcmp')) {
      if (!hasString) {
        return CompilerResult.failure(
          error: "Missing header file 'string.h'.",
          explanation:
              "strlen() অথবা strcmp() ব্যবহারের জন্য #include<string.h> লিখতে হবে।",
          errorLine: i + 1,
        );
      }
    }

    if (_containsFunction(line, 'getch')) {
      if (!hasConio) {
        return CompilerResult.failure(
          error: "Missing header file 'conio.h'.",
          explanation:
              "getch() ব্যবহারের জন্য #include<conio.h> লিখতে হবে।",
          errorLine: i + 1,
        );
      }
    }
  }

  return CompilerResult.success(
    output: '',
    explanation: 'Header usage is valid.',
  );
}
}