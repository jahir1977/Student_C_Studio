# Checker Execution Order

> **Student C Studio v0.3 Stable**

---

# Purpose

Student C Studio executes every checker in a fixed order.

The execution order is carefully designed so that earlier checkers eliminate fundamental problems before later checkers perform more detailed analysis.

This document explains both the execution sequence and the reason behind it.

---

# Complete Execution Order

```
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
```

---

# Why This Order?

Compilation follows the principle:

```
Basic Syntax

↓

Program Structure

↓

Language Rules

↓

Semantic Validation

↓

Library Validation

↓

Specialized Validation
```

Earlier stages prevent unnecessary work in later stages.

---

# Stage 1 — Basic Control Flow

Checkers

- DoWhileChecker
- BreakContinueChecker
- GotoChecker

Purpose

Validate language control-flow rules before deeper syntax analysis.

---

# Stage 2 — Declaration Validation

Checkers

- ArrayChecker
- Semicolon Scanner
- VariableDeclarationChecker

Purpose

Ensure declarations are structurally valid before expressions are analyzed.

---

# Stage 3 — Control Statements

Checkers

- LoopChecker
- IfChecker
- SwitchChecker
- WhileChecker

Purpose

Validate the structure of control statements.

Examples

```
if (...)

for (...)

while (...)

switch (...)
```

---

# Stage 4 — Expression Analysis

Checker

- ExpressionChecker

Purpose

Validate expressions after declarations and control statements are already known to be valid.

Examples

```
a = b + c;

x++;

i <= 10;
```

---

# Stage 5 — Structural Validation

Checkers

- HeaderChecker
- QuoteChecker
- ParenthesisChecker
- BraceChecker

Purpose

Ensure the program structure is complete and balanced.

Examples

- Missing quote
- Missing parenthesis
- Missing brace
- Invalid header

---

# Stage 6 — Function Validation

Checker

- FunctionChecker

Purpose

Validate function names.

Examples

Valid

```
printf()

scanf()

sqrt()
```

Invalid

```
pritnf()

scnaf()

puts()
```

Control keywords such as

```
if

for

while

switch
```

are **not** treated as functions.

---

# Stage 7 — Identifier Validation

Checker

- IdentifierChecker

Purpose

Validate identifier names.

Examples

Valid

```
number

studentName

totalMarks
```

Invalid

```
2number

int

float
```

---

# Stage 8 — Library Validation

Checkers

- InputOutputChecker
- FormatSpecifierChecker
- StringChecker
- PointerChecker

Purpose

Validate standard library usage.

Examples

- printf()
- scanf()
- %d
- %f
- String handling
- Pointer syntax

---

# Fail-Fast Strategy

The compiler stops at the first detected error.

```
Checker

↓

Error?

↓

YES

↓

Stop Compilation
```

Only one error is reported during a compilation cycle.

This keeps feedback simple and easier for beginners.

---

# Why Not Run Everything?

Running every checker after the first error would

- produce confusing diagnostics
- increase execution time
- overwhelm beginners

Student C Studio intentionally reports only the first meaningful error.

---

# Future Expansion

Future versions may insert additional stages.

Examples

- StructChecker
- EnumChecker
- TypedefChecker
- FunctionParameterChecker
- SymbolTableChecker

The current architecture allows these additions without changing existing checkers.

---

# Summary

The checker execution order is intentionally designed.

Each checker receives a validated CompilerContext from previous stages and performs one specific responsibility.

This layered approach keeps Student C Studio

- predictable
- maintainable
- extensible
- beginner-friendly