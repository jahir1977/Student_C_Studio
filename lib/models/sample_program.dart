enum ProgramCategory {
  textBook,
  boardQuestion,
  specialExample,
}

class SampleProgram {
  final String id;
  final ProgramCategory category;
  final String titleBn;
  final String topicTagBn;
  final String code;

  const SampleProgram({
    required this.id,
    this.category = ProgramCategory.textBook,
    required this.titleBn,
    required this.topicTagBn,
    required this.code,
  });
}
