import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';
import 'compiler_checker.dart';

class FunctionChecker implements CompilerChecker {
  static const Set<String> _knownFunctions = {
    'main',
    'printf',
    'scanf',
    'pow',
    'sqrt',
    'fabs',
    'strlen',
    'strcmp',
    'strcpy',
    'strcat',
    'getch',
  };

  static const Set<String> _controlKeywords = {
    'if',
    'for',
    'while',
    'switch',
  };

  static final RegExp _functionDefinitionPattern = RegExp(
    r'\b'
    r'(?:(?:signed|unsigned)\s+)?'
    r'(?:(?:short|long\s+long|long)\s+)?'
    r'(?:void|char|int|float|double)'
    r'\s+'
    r'(?:\*+\s*)?'
    r'([A-Za-z_]\w*)'
    r'\s*\('
    r'[^;{}]*'
    r'\)'
    r'\s*\{',
    multiLine: true,
    dotAll: true,
  );

  static final RegExp _functionCallPattern = RegExp(
    r'\b([A-Za-z_]\w*)\s*\(',
  );

  CompilerResult check(String sourceCode) {
    final Set<String> declaredFunctions = _extractDeclaredFunctions(sourceCode);

    final List<String> lines = sourceCode.split('\n');

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];

      final Iterable<RegExpMatch> matches =
          _functionCallPattern.allMatches(line);

      for (final RegExpMatch match in matches) {
        final String functionName = match.group(1)!;

        if (_knownFunctions.contains(functionName) ||
            _controlKeywords.contains(functionName) ||
            declaredFunctions.contains(functionName)) {
          continue;
        }

        return CompilerResult.failure(
          error: "Unknown function '$functionName'.",
          explanation: """
'$functionName()' C ভাষার বৈধ Function নয়।

বৈধ Function:
• main()
• printf()
• scanf()
• pow()
• sqrt()
• fabs()
• strlen()
• strcmp()
• strcpy()
• strcat()
• getch()
""",
          errorLine: index + 1,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Function usage is valid.',
    );
  }

  Set<String> _extractDeclaredFunctions(String sourceCode) {
    final Set<String> declaredFunctions = <String>{};

    final Iterable<RegExpMatch> matches =
        _functionDefinitionPattern.allMatches(sourceCode);

    for (final RegExpMatch match in matches) {
      final String? functionName = match.group(1);

      if (functionName != null && functionName.isNotEmpty) {
        declaredFunctions.add(functionName);
      }
    }

    return declaredFunctions;
  }

  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return check(context.sanitizedSource);
  }
}
