# Compiler Pipeline

> **Student C Studio v0.3 Stable**

---

# Overview

The compiler pipeline describes how source code travels through Student C Studio from the moment the user clicks **Run** until the final result is produced.

Each stage has only one responsibility.

The pipeline is intentionally simple, deterministic, and easy to maintain.

---

# Pipeline Flow

```
User Code
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
    ▼
Checker Pipeline
    │
    ▼
CompilerResult
    │
    ▼
Editor Output
```

---

# Stage 1 — Source Code

The user writes C source code inside the editor.

Example

```c
#include<stdio.h>

int main()
{
    printf("Hello");
    return 0;
}
```

The original source code is preserved without modification.

---

# Stage 2 — SourceSanitizer

SourceSanitizer prepares the source code for analysis.

Responsibilities

- Remove comments
- Preserve original line numbers
- Generate sanitized source
- Generate sanitized lines

Only one sanitization is performed for each compilation.

---

# Stage 3 — CompilerContextBuilder

CompilerContextBuilder creates a shared CompilerContext.

Responsibilities

- Store raw source
- Store sanitized source
- Split source into lines
- Store metadata
- Store included headers

The CompilerContext is built exactly once.

---

# Stage 4 — CompilerContext

CompilerContext is the shared data model used by every checker.

Contents

- rawSource
- sanitizedSource
- rawLines
- sanitizedLines
- metadata
- includedHeaders

The context is immutable after creation.

---

# Stage 5 — Checker Pipeline

Every checker receives the same CompilerContext.

Current execution order

1. DoWhileChecker
2. BreakContinueChecker
3. GotoChecker
4. ArrayChecker
5. Semicolon Scanner
6. VariableDeclarationChecker
7. LoopChecker
8. IfChecker
9. SwitchChecker
10. WhileChecker
11. ExpressionChecker
12. HeaderChecker
13. QuoteChecker
14. ParenthesisChecker
15. BraceChecker
16. FunctionChecker
17. IdentifierChecker
18. InputOutputChecker
19. FormatSpecifierChecker
20. StringChecker
21. PointerChecker

The pipeline stops immediately when a checker reports an error.

---

# Stage 6 — CompilerResult

CompilerResult represents the final outcome of compilation.

Possible results

Success

```text
Program executed successfully.
```

Failure

```text
Unknown function 'pritnf'.
```

CompilerResult may include

- error
- banglaExplanation
- errorLine
- output

---

# Error Handling

Compilation follows a fail-fast strategy.

```
Checker
    │
Error?
    │
 ┌──Yes──────► Stop Compilation
 │
 └──No───────► Continue
```

Only the first detected error is reported.

This keeps feedback simple and easy for beginners.

---

# Performance

Student C Studio avoids repeated work.

The compiler performs

- One sanitization
- One CompilerContext creation
- Shared metadata
- Shared sanitized source
- Shared sanitized lines

This minimizes unnecessary processing.

---

# Design Goals

The compiler pipeline is designed to be

- Simple
- Predictable
- Modular
- Testable
- Easy to extend

---

# Future Expansion

The current pipeline supports future additions without major redesign.

Possible future stages include

- StructChecker
- EnumChecker
- TypedefChecker
- FunctionParameterChecker
- Interpreter
- Debugger

---

# Summary

The Student C Studio compiler pipeline is built around a single CompilerContext shared by every checker.

This architecture provides consistent validation, easier maintenance, and better performance while keeping the compiler understandable for students and contributors.