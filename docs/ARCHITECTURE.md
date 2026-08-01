# Student C Studio Architecture

> **Version:** v0.3 Stable

---

# Introduction

Student C Studio follows a modular compiler architecture designed specifically for educational purposes.

Instead of performing all validations inside one large compiler, the project divides every responsibility into small independent checkers.

Each checker has only one responsibility.

This design keeps the compiler clean, maintainable, testable, and easy to extend.

---

# High Level Architecture

```
                Source Code
                     │
                     ▼
             SourceSanitizer
                     │
                     ▼
         CompilerContextBuilder
                     │
                     ▼
             CompilerContext
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼
 HeaderChecker   BraceChecker   ExpressionChecker
      ▼              ▼              ▼
  FunctionChecker IdentifierChecker ...
                     │
                     ▼
             CompilerResult
```

---

# Core Components

## SourceSanitizer

Responsibilities

- Remove comments
- Preserve line numbers
- Produce sanitized source
- Produce sanitized lines

Only one sanitization is performed during compilation.

---

## CompilerContextBuilder

CompilerContextBuilder creates the shared CompilerContext.

It runs only once for every compilation.

Responsibilities

- Build CompilerContext
- Split source into lines
- Store metadata
- Store included headers

---

## CompilerContext

CompilerContext is the shared immutable object passed to every checker.

Contents

- rawSource
- sanitizedSource
- rawLines
- sanitizedLines
- metadata
- includedHeaders

Every checker receives the same CompilerContext instance.

---

# Checker Architecture

Every checker follows the same principle.

```
CompilerContext
        │
        ▼
Checker
        │
        ▼
CompilerResult
```

Each checker is responsible for exactly one category of validation.

Examples

- HeaderChecker
- BraceChecker
- FunctionChecker
- IdentifierChecker
- ExpressionChecker

This follows the Single Responsibility Principle (SRP).

---

# MockCompiler

MockCompiler is no longer responsible for parsing source code.

Its responsibilities are now limited to:

- Creating CompilerContext
- Running the checker pipeline
- Returning CompilerResult

All syntax analysis is delegated to dedicated checkers.

---

# Compiler Pipeline

Compilation order

1. SourceSanitizer
2. CompilerContextBuilder
3. Checker Pipeline
4. CompilerResult

This guarantees consistent validation across the entire compiler.

---

# Design Principles

Student C Studio follows these software engineering principles.

## Single Responsibility Principle

Each checker performs exactly one job.

---

## Single Source Sanitization

Source code is sanitized only once.

Every checker shares the same sanitized source.

---

## Shared Context

CompilerContext is created once.

Every checker shares the same immutable context.

---

## Modular Design

Every checker is independent.

New checkers can be added without changing existing ones.

---

## Test Driven Development

Every feature follows this workflow.

```
Write Test
     │
     ▼
Fail
     │
     ▼
Implement
     │
     ▼
Regression
     │
     ▼
Git Commit
```

---

# Advantages

The current architecture provides:

- Better maintainability
- Faster compilation
- Cleaner code
- Easier debugging
- Independent testing
- Better scalability

---

# Future Expansion

The architecture is prepared for future features.

Examples

- Struct analysis
- Enum analysis
- Typedef support
- Function parameter validation
- Interpreter
- Debugger

---

# Summary

Student C Studio v0.3 introduces a modern compiler architecture centered around CompilerContext.

The compiler now performs:

- Single sanitization
- Single context creation
- Shared metadata
- Modular validation
- Context-aware checker execution

This architecture serves as the foundation for all future versions.