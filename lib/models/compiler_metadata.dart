class CompilerMetadata {
  const CompilerMetadata({
    required this.lineCount,
    this.checkerVersion = 1,
    this.pipelineVersion = 2,
  });

  final int lineCount;

  final int checkerVersion;

  final int pipelineVersion;
}