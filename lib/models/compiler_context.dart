import 'compiler_metadata.dart';

class CompilerContext {
  final String rawSource;
  final String sanitizedSource;

  final List<String> rawLines;
  final List<String> sanitizedLines;

  final CompilerMetadata metadata;

  const CompilerContext({
    required this.rawSource,
    required this.sanitizedSource,
    required this.rawLines,
    required this.sanitizedLines,
    required this.metadata,
  });
}