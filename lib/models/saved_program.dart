class SavedProgram {
  const SavedProgram({
    required this.id,
    required this.programNumber,
    required this.sourceCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int programNumber;
  final String sourceCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => 'Program $programNumber';

  SavedProgram copyWith({
    String? id,
    int? programNumber,
    String? sourceCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedProgram(
      id: id ?? this.id,
      programNumber: programNumber ?? this.programNumber,
      sourceCode: sourceCode ?? this.sourceCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'programNumber': programNumber,
      'sourceCode': sourceCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedProgram.fromJson(
    Map<String, Object?> json,
  ) {
    return SavedProgram(
      id: json['id'] as String? ?? '',
      programNumber: json['programNumber'] as int? ?? 0,
      sourceCode: json['sourceCode'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(
            json['updatedAt'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
