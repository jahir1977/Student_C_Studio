# Student C Studio
# Architecture Freeze v0.4

**Status:** Frozen  
**Version:** v0.4  
**Date:** August 2026

---

# Purpose

This document defines the final compiler architecture for Student C Studio v0.4.

After this point, the architecture should remain stable.
Future development should focus on adding new features instead of redesigning the compiler.

---

# High Level Architecture

```
Editor
        │
        ▼
CompilerContextBuilder
        │
        ▼
CompilerContext
        │
        ▼
MockCompiler
        │
        ▼
Checker Registry Runner
        │
        ├── Early Registry
        ├── Structural Registry
        ├── Statement Registry
        ├── Library Registry
        └── Special Checkers
```

---

# Registry Execution Order

Compiler execution order is fixed.

## 1. Early Registry

Executed first.

Contains:

- DoWhileChecker
- BreakContinueChecker
- GotoChecker
- ArrayChecker

Purpose:

Detect language structure problems before parsing deeper constructs.

---

## 2. Structural Registry

Executed second.

Contains:

- HeaderChecker
- QuoteChecker
- ParenthesisChecker
- BraceChecker
- FunctionChecker
- IdentifierCheckerAdapter

Purpose:

Validate program structure.

---

## 3. Statement Registry

Executed third.

Contains:

- LoopChecker
- IfChecker
- SwitchChecker
- WhileChecker
- ExpressionChecker

Purpose:

Validate statement syntax.

---

## 4. Library Registry

Executed fourth.

Contains:

- InputOutputChecker
- FormatSpecifierChecker
- StringCheckerAdapter
- PointerCheckerAdapter

Purpose:

Validate standard library usage.

---

# Special Checkers

These checkers remain independent.

Current list:

- VariableDeclarationChecker

Reason:

Uses VariableCheckResult instead of CompilerResult.

---

# Adapter Layer

Adapters exist only to convert legacy static checkers into CompilerChecker implementations.

Current adapters:

- IdentifierCheckerAdapter
- StringCheckerAdapter
- PointerCheckerAdapter

No business logic should exist inside adapters.

---

# CompilerChecker Contract

Every CompilerChecker must implement:

```dart
CompilerResult checkContext(
    CompilerContext context,
);
Checker Rules

Every checker should:

be stateless
be deterministic
avoid modifying CompilerContext
return CompilerResult only
stop immediately after detecting the first error
CompilerContext Rules

CompilerContext is read-only.

Checkers must never modify:

sanitizedSource
symbolTable
includedHeaders

Future fields should also remain immutable.

MockCompiler Rules

MockCompiler is an orchestrator.

It should never contain business logic belonging to checkers.

Its responsibilities:

build CompilerContext
execute registries
return CompilerResult

Nothing more.

Testing Rules

Every architecture change must satisfy:

flutter analyze
flutter test

No warning.

No analyzer issue.

All tests must pass.

Git Rules

One architectural change

=

One commit

Never mix:

architecture
UI
feature

inside the same commit.

Future Development

Allowed:

new checkers
new adapters
new registries
new diagnostics
better error messages

Not allowed:

redesigning CompilerContext
redesigning CompilerChecker
changing registry execution order without documentation
Freeze Declaration

Version v0.4 establishes the compiler architecture.

Future versions should extend this architecture instead of replacing it.