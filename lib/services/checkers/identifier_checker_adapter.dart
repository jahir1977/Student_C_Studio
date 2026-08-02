import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';
import 'compiler_checker.dart';
import 'identifier_checker.dart';

class IdentifierCheckerAdapter implements CompilerChecker {
  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    final CompilerResult? result = IdentifierChecker.checkContext(context);

    return result ??
        CompilerResult.success(
          output: '',
          explanation: 'Identifier usage is valid.',
        );
  }
}
