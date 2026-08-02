import 'package:flutter/material.dart';

import '../data/sample_programs.dart';
import '../models/sample_program.dart';

class SampleProgramPage extends StatelessWidget {
  const SampleProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<SampleProgram>> groupedPrograms =
        _groupProgramsByTopic();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Programs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: groupedPrograms.entries.map(
          (MapEntry<String, List<SampleProgram>> entry) {
            return _TopicSection(
              topic: entry.key,
              programs: entry.value,
            );
          },
        ).toList(),
      ),
    );
  }

  Map<String, List<SampleProgram>> _groupProgramsByTopic() {
    final Map<String, List<SampleProgram>> groupedPrograms =
        <String, List<SampleProgram>>{};

    for (final SampleProgram program in sampleProgramLibrary) {
      groupedPrograms
          .putIfAbsent(
            program.topicTagBn,
            () => <SampleProgram>[],
          )
          .add(program);
    }

    return groupedPrograms;
  }
}

class _TopicSection extends StatelessWidget {
  const _TopicSection({
    required this.topic,
    required this.programs,
  });

  final String topic;
  final List<SampleProgram> programs;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.folder_open_outlined),
        ),
        title: Text(
          topic,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${programs.length}টি প্রোগ্রাম',
        ),
        children: programs.map(
          (SampleProgram program) {
            return ListTile(
              leading: const Icon(Icons.code),
              title: Text(program.titleBn),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop(program.code);
              },
            );
          },
        ).toList(),
      ),
    );
  }
}
