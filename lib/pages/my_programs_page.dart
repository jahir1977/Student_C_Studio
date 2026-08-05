import 'package:flutter/material.dart';

import '../models/saved_program.dart';
import '../services/program_storage_service.dart';

class MyProgramsPage extends StatefulWidget {
  const MyProgramsPage({
    super.key,
    this.storageService = const ProgramStorageService(),
  });

  final ProgramStorageService storageService;

  @override
  State<MyProgramsPage> createState() => _MyProgramsPageState();
}

class _MyProgramsPageState extends State<MyProgramsPage> {
  List<SavedProgram> _programs = <SavedProgram>[];

  SavedProgram? _selectedProgram;

  bool _isLoading = true;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final List<SavedProgram> programs =
        await widget.storageService.loadPrograms();

    if (!mounted) {
      return;
    }

    SavedProgram? selectedProgram = _selectedProgram;

    if (selectedProgram != null) {
      final int selectedIndex = programs.indexWhere(
        (SavedProgram program) => program.id == selectedProgram!.id,
      );

      selectedProgram = selectedIndex >= 0 ? programs[selectedIndex] : null;
    }

    setState(() {
      _programs = programs;
      _selectedProgram = selectedProgram;
      _isLoading = false;
    });
  }

  void _selectProgram(SavedProgram program) {
    setState(() {
      _selectedProgram = program;
    });
  }

  void _openSelectedProgram() {
    final SavedProgram? selectedProgram = _selectedProgram;

    if (selectedProgram == null) {
      return;
    }

    Navigator.of(context).pop(selectedProgram);
  }

  Future<void> _deleteSelectedProgram() async {
    final SavedProgram? selectedProgram = _selectedProgram;

    if (selectedProgram == null || _isDeleting) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Program'),
          content: Text(
            '${selectedProgram.displayName} মুছে ফেলবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    await widget.storageService.deleteProgram(
      selectedProgram,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedProgram = null;
      _isDeleting = false;
    });

    await _loadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('My Programs'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCounter(),
            const Divider(height: 1),
            Expanded(
              child: _buildProgramList(),
            ),
            const Divider(height: 1),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Text(
        '${_programs.length} / '
        '${ProgramStorageService.maximumPrograms}',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildProgramList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_programs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'এখনো কোনো Program তৈরি করা হয়নি।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _programs.length,
      separatorBuilder: (
        BuildContext context,
        int index,
      ) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final SavedProgram program = _programs[index];

        final bool isSelected = _selectedProgram?.id == program.id;

        return Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _selectProgram(program);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade500,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      program.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final bool hasSelection = _selectedProgram != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed:
                  hasSelection && !_isDeleting ? _openSelectedProgram : null,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  hasSelection && !_isDeleting ? _deleteSelectedProgram : null,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
