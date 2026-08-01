# CompilerContext

> **Student C Studio v0.3 Stable**

---

# Overview

CompilerContext is the central data model of Student C Studio.

Beginning with version **v0.3**, every checker receives the same CompilerContext instance instead of parsing the source code independently.

This design eliminates duplicate work and keeps every checker synchronized.

---

# Why CompilerContext?

Before v0.3, each checker analyzed the source code independently.

Example

```
HeaderChecker
      │
      ▼
Parse Source

BraceChecker
      │
      ▼
Parse Source

FunctionChecker
      │
      ▼
Parse Source
```

The same source code was processed repeatedly.

This increased complexity and made future maintenance difficult.

---

# New Architecture

Version v0.3 introduces a shared CompilerContext.

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
      ├─────────────┐
      ▼             ▼
HeaderChecker   BraceChecker
      ▼             ▼
FunctionChecker ExpressionChecker
      ▼             ▼
CompilerResult
```

The source code is analyzed only once.

---

# CompilerContext Contents

CompilerContext stores every piece of information required during compilation.

Current fields

```
rawSource
sanitizedSource
rawLines
sanitizedLines
metadata
includedHeaders
```

Each field has a specific responsibility.

---

## rawSource

The original source code exactly as written by the user.

No modification is performed.

---

## sanitizedSource

Source code after SourceSanitizer removes comments while preserving line numbers.

Every checker uses this source for analysis.

---

## rawLines

Original source code split into individual lines.

Useful for reporting accurate locations.

---

## sanitizedLines

Sanitized source split into lines.

This allows line-based validation without repeating the sanitization process.

Example usage

- Semicolon scanner
- Statement analysis
- Future parser improvements

---

## metadata

CompilerMetadata stores general information about the source.

Examples

- Total line count
- Additional compiler statistics
- Future compilation metrics

---

## includedHeaders

A collection of all detected header files.

Example

```
stdio.h
math.h
string.h
```

This allows header-related validation without rescanning the source.

---

# CompilerContext Lifecycle

```
User presses Run
        │
        ▼
SourceSanitizer
        │
        ▼
CompilerContextBuilder
        │
        ▼
CompilerContext Created
        │
        ▼
Shared by Every Checker
        │
        ▼
Compilation Finished
```

CompilerContext exists only during compilation.

A new instance is created for every compilation request.

---

# Immutability

CompilerContext is treated as immutable.

After creation, no checker should modify its contents.

Advantages

- Predictable behavior
- Easier debugging
- Consistent validation
- Safe sharing

---

# Performance Benefits

CompilerContext significantly reduces repeated work.

Instead of

```
Checker A

Parse

Checker B

Parse

Checker C

Parse
```

Student C Studio performs

```
Parse Once

↓

Share Everywhere
```

Benefits

- Faster execution
- Cleaner code
- Less duplication
- Easier maintenance

---

# Current Users

As of v0.3 Stable, all compiler checkers use CompilerContext.

Examples

- HeaderChecker
- QuoteChecker
- ParenthesisChecker
- BraceChecker
- FunctionChecker
- IdentifierChecker
- VariableDeclarationChecker
- ExpressionChecker
- LoopChecker
- WhileChecker
- SwitchChecker
- PointerChecker

Every checker now follows the same architecture.

---

# Design Philosophy

CompilerContext was introduced with three primary goals.

1. Remove duplicate parsing

2. Improve maintainability

3. Prepare the compiler for future growth

---

# Future Expansion

CompilerContext is designed to support future compiler features.

Potential additions

- Symbol table
- Token stream
- Abstract Syntax Tree (AST)
- Diagnostics
- Warning collection
- Parser cache

These features can be added without changing the existing checker interface.

---

# Summary

CompilerContext is the foundation of Student C Studio v0.3.

It provides

- Single source sanitization
- Single context creation
- Shared compiler information
- Cleaner architecture
- Better performance
- Easier future expansion

Every checker now speaks the same language through CompilerContext.