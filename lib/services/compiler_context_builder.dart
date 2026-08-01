import '../models/compiler_context.dart';
import '../models/compiler_metadata.dart';
import 'source_sanitizer.dart';

class CompilerContextBuilder {
  const CompilerContextBuilder._();

  static CompilerContext build(String source) {
    final String sanitizedSource =
        SourceSanitizer.sanitize(source);

    return CompilerContext(
      rawSource: source,
      sanitizedSource: sanitizedSource,
      rawLines: List<String>.unmodifiable(
        source.split('\n'),
      ),
      sanitizedLines: List<String>.unmodifiable(
        sanitizedSource.split('\n'),
      ),
      metadata: CompilerMetadata(
        lineCount: source.split('\n').length,
      ),
    );
  }
}