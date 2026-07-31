class CompilerResult {
  final bool isSuccess;
  final String output;
  final String error;
  final String banglaExplanation;
  final int? errorLine;

  const CompilerResult({
    required this.isSuccess,
    required this.output,
    required this.error,
    required this.banglaExplanation,
    this.errorLine,
  });

  factory CompilerResult.success({
    required String output,
    String explanation = "Program executed successfully.",
  }) {
    return CompilerResult(
      isSuccess: true,
      output: output,
      error: '',
      banglaExplanation: explanation,
    );
  }

  factory CompilerResult.failure({
    required String error,
    required String explanation,
    int? errorLine,
  }) {
    return CompilerResult(
      isSuccess: false,
      output: '',
      error: error,
      banglaExplanation: explanation,
      errorLine: errorLine,
    );
  }

  String get displayText {
    if (isSuccess) return output;

    if (errorLine != null) {
      return 'Line $errorLine\n$error';
    }

    return error;
  }
}