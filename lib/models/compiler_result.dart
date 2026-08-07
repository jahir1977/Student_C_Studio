class CompilerResult {
  final bool isSuccess;
  final String output;
  final String error;
  final String banglaExplanation;
  final int? errorLine;

  CompilerResult({
    required this.isSuccess,
    this.output = '',
    this.error = '',
    String? banglaExplanation,
    String? explanation,
    this.errorLine,
  }) : banglaExplanation = (banglaExplanation ?? explanation ?? '')
            .replaceAll('\u200B', '');

  String get displayText {
    if (isSuccess) return output;
    if (errorLine != null) {
      return 'Line $errorLine\n$error';
    }
    return error;
  }

  String get explanation => banglaExplanation;

  factory CompilerResult.success({
    String output = '',
    String explanation = '',
    String banglaExplanation = '',
  }) {
    return CompilerResult(
      isSuccess: true,
      output: output,
      error: '',
      banglaExplanation:
          banglaExplanation.isNotEmpty ? banglaExplanation : explanation,
    );
  }

  factory CompilerResult.failure({
    String error = '',
    String explanation = '',
    String banglaExplanation = '',
    int? errorLine,
  }) {
    return CompilerResult(
      isSuccess: false,
      output: '',
      error: error,
      banglaExplanation:
          banglaExplanation.isNotEmpty ? banglaExplanation : explanation,
      errorLine: errorLine,
    );
  }
}