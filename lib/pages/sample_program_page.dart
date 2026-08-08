import 'package:flutter/material.dart';

import '../data/sample_programs.dart';
import '../models/sample_program.dart';

class SampleProgramPage extends StatelessWidget {
  const SampleProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<ProgramCategory, List<SampleProgram>> groupedByCategory =
        _groupProgramsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Programs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CategorySection(
            title: 'Text Book',
            icon: Icons.menu_book_outlined,
            programs: groupedByCategory[ProgramCategory.textBook] ??
                <SampleProgram>[],
          ),
          _CategorySection(
            title: 'Board Question',
            icon: Icons.school_outlined,
            programs: groupedByCategory[ProgramCategory.boardQuestion] ??
                <SampleProgram>[],
          ),
          _CategorySection(
            title: 'Special Example',
            icon: Icons.star_outline,
            programs: groupedByCategory[ProgramCategory.specialExample] ??
                <SampleProgram>[],
          ),
        ],
      ),
    );
  }

  Map<ProgramCategory, List<SampleProgram>> _groupProgramsByCategory() {
    final Map<ProgramCategory, List<SampleProgram>> groupedPrograms =
        <ProgramCategory, List<SampleProgram>>{};

    for (final SampleProgram program in sampleProgramLibrary) {
      groupedPrograms
          .putIfAbsent(
            program.category,
            () => <SampleProgram>[],
          )
          .add(program);
    }

    return groupedPrograms;
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.icon,
    required this.programs,
  });

  final String title;
  final IconData icon;
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
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${programs.length}টি প্রোগ্রাম',
        ),
        children: programs.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'এখনও কোনো প্রোগ্রাম যোগ করা হয়নি।',
                  ),
                ),
              ]
            : _buildTopicSections(programs),
      ),
    );
  }

  List<Widget> _buildTopicSections(
    List<SampleProgram> programs,
  ) {
    final Map<String, List<SampleProgram>> groupedByTopic =
        <String, List<SampleProgram>>{};

    for (final SampleProgram program in programs) {
      groupedByTopic
          .putIfAbsent(
            program.topicTagBn,
            () => <SampleProgram>[],
          )
          .add(program);
    }

    return groupedByTopic.entries.map(
      (MapEntry<String, List<SampleProgram>> entry) {
        return _TopicSection(
          topic: entry.key,
          programs: entry.value,
        );
      },
    ).toList();
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
    return ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(
        Icons.folder_open_outlined,
      ),
      title: Text(
        topic,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${programs.length}টি প্রোগ্রাম',
      ),
      children: programs.map(
        (SampleProgram program) {
          return ListTile(
            contentPadding: const EdgeInsets.only(
              left: 32,
              right: 16,
            ),
            leading: const Icon(
              Icons.code,
            ),
            title: Text(
              program.titleBn,
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.of(context).pop(program.code);
            },
          );
        },
      ).toList(),
    );
  }
}
