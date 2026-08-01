import '../../models/compiler_result.dart';
import '../../models/compiler_context.dart';

class FunctionChecker {
  static const Set<String> _knownFunctions = {
    'main',
    'printf',
    'scanf',
    'pow',
    'sqrt',
    'strlen',
    'strcmp',
    'getch',
  };

  CompilerResult check(String sourceCode) {
    final lines = sourceCode.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final matches = RegExp(r'\b([A-Za-z_]\w*)\s*\(').allMatches(line);

      for (final match in matches) {
        final functionName = match.group(1)!;

        if (_knownFunctions.contains(functionName)) {
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
• strlen()
• strcmp()
• getch()
""",
          errorLine: i + 1,
        );
      }
    }

    return CompilerResult.success(
      output: '',
      explanation: 'Function usage is valid.',
    );
  }
  CompilerResult checkContext(
  CompilerContext context,
) {
  return check(context.sanitizedSource);
}
}