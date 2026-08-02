import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';
import 'compiler_checker.dart';
import 'string_checker.dart';

class StringCheckerAdapter implements CompilerChecker {
  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return StringChecker.checkContext(context);
  }
}
