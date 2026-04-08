# Cloth Compiler Specification (Draft)

> Status: Draft / evolving  
> This document defines the normative behavior of the Cloth Compiler.

---

## Table of Contents

1. Overview
2. Compilation Pipeline
   1. Lexing
   2. Parsing
   3. Semantic Analysis
   4. IR Generation
   5. Optimization
   6. LLVM Lowering
   7. Code Emission
3. Cloth IR
   1. Design Goals
   2. Instruction Model
   3. Type Representation
   4. Control Flow Graph
   5. Memory Model Mapping
   6. Ownership Representation
4. LLVM Generation
   1. Mapping Cloth Types to LLVM Types
   2. Function Lowering
   3. Object Layout
   4. Memory and Allocation Strategy
   5. Exception / Maybe Handling
   6. Optimization Passes

5. Runtime Requirements

```text
Lexer
  ↓
Parser
  ↓
AST
  ↓
Semantic Analysis (types, ownership, visibility, etc.)
  ↓
Cloth IR (very important for you)
  ↓
LLVM IR Emitter
  ↓
LLVM (opt + codegen)
```