import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';
import 'compiler_checker.dart';

class HeaderChecker implements CompilerChecker {
  CompilerResult check(String sourceCode) {
    final List<String> lines = sourceCode.split('\n');

    final bool hasStdio = _hasHeader(sourceCode, 'stdio.h');
    final bool hasMath = _hasHeader(sourceCode, 'math.h');
    final bool hasString = _hasHeader(sourceCode, 'string.h');
    final bool hasConio = _hasHeader(sourceCode, 'conio.h');

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];

      // --------------------------------------------------
      // stdio.h
      // --------------------------------------------------
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

      // --------------------------------------------------
      // math.h
      // --------------------------------------------------
      if (_containsFunction(line, 'pow') ||
          _containsFunction(line, 'sqrt') ||
          _containsFunction(line, 'fabs')) {
        if (!hasMath) {
          return CompilerResult.failure(
            error: "Missing header file 'math.h'.",
            explanation:
                "pow(), sqrt() অথবা fabs() ব্যবহারের জন্য #include<math.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      // --------------------------------------------------
      // string.h
      // --------------------------------------------------
      if (_containsFunction(line, 'strlen') ||
          _containsFunction(line, 'strcmp') ||
          _containsFunction(line, 'strcpy') ||
          _containsFunction(line, 'strcat')) {
        if (!hasString) {
          return CompilerResult.failure(
            error: "Missing header file 'string.h'.",
            explanation:
                "strlen(), strcmp(), strcpy() অথবা strcat() ব্যবহারের জন্য "
                "#include<string.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      // --------------------------------------------------
      // conio.h
      // --------------------------------------------------
      if (_containsFunction(line, 'getch')) {
        if (!hasConio) {
          return CompilerResult.failure(
            error: "Missing header file 'conio.h'.",
            explanation: "getch() ব্যবহারের জন্য #include<conio.h> লিখতে হবে।",
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

  bool _hasHeader(
    String sourceCode,
    String headerName,
  ) {
    final String escapedHeader = RegExp.escape(headerName);

    return RegExp(
      '#include\\s*<\\s*$escapedHeader\\s*>',
    ).hasMatch(sourceCode);
  }

  bool _containsFunction(
    String line,
    String functionName,
  ) {
    return RegExp(
      '\\b${RegExp.escape(functionName)}\\s*\\(',
    ).hasMatch(line);
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    final bool hasStdio = context.includedHeaders.contains('stdio.h');

    final bool hasMath = context.includedHeaders.contains('math.h');

    final bool hasString = context.includedHeaders.contains('string.h');

    final bool hasConio = context.includedHeaders.contains('conio.h');

    final List<String> lines = context.sanitizedLines;

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];

      // --------------------------------------------------
      // stdio.h
      // --------------------------------------------------
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

      // --------------------------------------------------
      // math.h
      // --------------------------------------------------
      if (_containsFunction(line, 'pow') ||
          _containsFunction(line, 'sqrt') ||
          _containsFunction(line, 'fabs')) {
        if (!hasMath) {
          return CompilerResult.failure(
            error: "Missing header file 'math.h'.",
            explanation:
                "pow(), sqrt() অথবা fabs() ব্যবহারের জন্য #include<math.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      // --------------------------------------------------
      // string.h
      // --------------------------------------------------
      if (_containsFunction(line, 'strlen') ||
          _containsFunction(line, 'strcmp') ||
          _containsFunction(line, 'strcpy') ||
          _containsFunction(line, 'strcat')) {
        if (!hasString) {
          return CompilerResult.failure(
            error: "Missing header file 'string.h'.",
            explanation:
                "strlen(), strcmp(), strcpy() অথবা strcat() ব্যবহারের জন্য "
                "#include<string.h> লিখতে হবে।",
            errorLine: i + 1,
          );
        }
      }

      // --------------------------------------------------
      // conio.h
      // --------------------------------------------------
      if (_containsFunction(line, 'getch')) {
        if (!hasConio) {
          return CompilerResult.failure(
            error: "Missing header file 'conio.h'.",
            explanation: "getch() ব্যবহারের জন্য #include<conio.h> লিখতে হবে।",
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
