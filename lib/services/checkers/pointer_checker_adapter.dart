import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';
import 'compiler_checker.dart';
import 'pointer_checker.dart';

class PointerCheckerAdapter implements CompilerChecker {
  @override
  CompilerResult checkContext(
    CompilerContext context,
  ) {
    return PointerChecker.checkContext(context);
  }
}
