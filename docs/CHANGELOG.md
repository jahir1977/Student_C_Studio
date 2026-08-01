# Changelog

All notable changes to Student C Studio are documented in this file.

The project follows a milestone-based development history.

---

# Version 0.3 Stable

Release Status

Stable

---

## Architecture

### Added

- CompilerContext
- CompilerContextBuilder
- CompilerMetadata
- Shared compilation context
- Shared sanitized source
- Shared sanitized lines

### Improved

- MockCompiler migrated to CompilerContext pipeline
- Context-aware checker execution
- Source sanitization performed only once
- Shared metadata for every checker

---

## Compiler

### Improved

- Single pipeline execution
- Better modular architecture
- Cleaner orchestration
- Reduced duplicate processing

---

## Checkers

### Added

- BraceChecker
- FunctionChecker
- CompilerContext support for all checkers

### Improved

- FunctionChecker ignores language keywords
- BraceChecker correctly handles nested blocks
- Better brace matching
- Better line reporting
- Better regression coverage

---

## Performance

Improved

- Single sanitization
- Shared CompilerContext
- Shared line cache
- Less duplicate work

---

## Cleanup

Removed

- Legacy brace fallback
- Obsolete identifier checker code
- Dead helper methods

---

## Quality

Current status

```
flutter analyze

No issues found.

flutter test

419 tests passed.
```

---

# Version 0.2

Major improvements

- ExpressionChecker
- IdentifierChecker
- VariableDeclarationChecker
- FunctionChecker
- SourceSanitizer
- Better compiler pipeline
- Regression tests

---

# Version 0.1

Initial project

Features

- Flutter project setup
- MockCompiler
- Basic editor
- Run button
- Output panel
- Bangla explanation support

---

# Development Philosophy

Every feature follows

```
Write Test

↓

Fail

↓

Implement

↓

Analyze

↓

Regression Test

↓

Git Commit
```

---

# Repository History

Major milestones

```
CompilerContext support

↓

Build CompilerContext once

↓

Cached sanitized lines

↓

FunctionChecker improvements

↓

BraceChecker improvements

↓

Pipeline migration

↓

Brace fallback removal

↓

Identifier cleanup

↓

v0.3 Stable
```

---

# Future

Planned versions

- v0.4
- v0.5
- v1.0

Each future version will continue updating this changelog.