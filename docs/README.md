# Student C Studio

> **Write → Run → Learn**
>
> A lightweight educational C compiler and code analysis tool designed for HSC ICT students.

---

# Overview

Student C Studio is an educational compiler project developed to help beginners learn C programming by writing code, detecting mistakes, and understanding compiler feedback in simple Bangla.

Unlike a traditional compiler, Student C Studio focuses on teaching programming concepts rather than producing executable machine code.

The project follows a modular compiler architecture where every validation stage is handled by an independent checker.

---

# Objectives

- Help HSC ICT students learn C programming.
- Detect common syntax mistakes.
- Explain errors in simple Bangla.
- Keep the compiler architecture clean and maintainable.
- Provide fast analysis using a shared CompilerContext.

---

# Current Version

**Student C Studio v0.3 Stable**

---

# Major Features

- CompilerContext-based pipeline
- SourceSanitizer
- Context-aware checkers
- Bangla error explanations
- Smart semicolon detection
- Header validation
- Identifier validation
- Function validation
- Brace validation
- Parenthesis validation
- Quote validation
- Expression validation
- Variable declaration validation
- Format specifier validation
- Input/Output validation

---

# Compiler Pipeline

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
      ▼
Checker Pipeline
      │
      ▼
CompilerResult
```

---

# Architecture Highlights

- Single source sanitization
- Single CompilerContext creation
- Shared metadata
- Shared sanitized lines
- Context-aware checkers
- Modular design
- Regression-tested architecture

---

# Quality

Current Quality Report

```
flutter analyze

No issues found.

flutter test

419 tests passed.
```

---

# Project Structure

```
lib/
models/
services/
checkers/

test/

docs/
```

---

# Technologies

- Flutter
- Dart
- Git
- GitHub

---

# Development Principles

Student C Studio follows Test Driven Development (TDD).

Development cycle:

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

# Roadmap

## v0.4

- Better parser
- Better diagnostics
- More C syntax support

## v0.5

- Interpreter

## v1.0

- Stable educational compiler

---

# License

Educational Use

---

# Author

Jahirul Islam

Assistant Professor

Department of Accounting

Khagrachhari Government Women's College

Bangladesh

---

# Project Motto

> **Programming is not memorization. Programming is understanding.**
