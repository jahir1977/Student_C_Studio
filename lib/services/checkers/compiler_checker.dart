import '../../models/compiler_context.dart';
import '../../models/compiler_result.dart';

/// Base interface for every compiler checker.
///
/// Each checker receives the same CompilerContext
/// and returns a CompilerResult.
abstract class CompilerChecker {
  CompilerResult checkContext(
    CompilerContext context,
  );
}
