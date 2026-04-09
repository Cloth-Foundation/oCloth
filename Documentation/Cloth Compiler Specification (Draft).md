# Cloth Compiler Specification

This document defines the normative behavior of the Cloth compiler toolchain for Cloth language edition **1.0**, with emphasis on the **backend**: the Cloth intermediate representation (Cloth IR), lowering to LLVM IR, and LLVM-based optimization and code generation.

This specification is written so that independent implementations can produce interoperable artifacts and can agree on:

1. The required compilation pipeline stages (as externally observable obligations).
2. The meaning and invariants of Cloth IR.
3. The mapping from Cloth IR semantics to LLVM IR semantics.
4. The required diagnostics and error categories for rejected programs.
5. The runtime and linker obligations implied by the generated code.

Unless explicitly labeled as informative, all statements are normative. Normative keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** are interpreted as in RFC 2119.

---

## Table of Contents

1. Overview
   1. Purpose and scope
   2. Relationship to the Cloth Language Specification
   3. Conformance claims and profiles
   4. Determinism, reproducibility, and build inputs
   5. Artifacts: outputs and their required properties
   6. Diagnostics, error handling, and recovery requirements
   7. Target platforms, ABIs, and LLVM versioning
   8. Security, safety, and undefined behavior boundaries
   9. Notation and conventions used in this document
2. Compilation Pipeline
   1. Stage boundaries and required stage outputs
   2. Lexing
   3. Parsing
   4. Semantic analysis (types, ownership, visibility, etc.)
   5. Cloth IR generation
   6. Cloth IR validation and canonicalization
   7. Optimization over Cloth IR
   8. LLVM IR lowering and emission
   9. LLVM optimization pipeline
   10. Code generation, object emission, and linking
3. Cloth IR
   1. Design goals and non-goals
   2. IR unit structure (modules, functions, globals)
   3. Instruction model
   4. Type system and type representation
   5. Values, SSA, and naming
   6. Control-flow graph model
   7. Memory model and aliasing model
   8. Ownership, lifetimes, and destruction semantics in IR
   9. Calls, ABI boundaries, and foreign interfaces
   10. Required IR validation rules
4. LLVM Generation
   1. Mapping Cloth types to LLVM types
   2. Function lowering
   3. Object layout and data layout rules
   4. Stack vs heap, allocation strategy, and lifetime intrinsics
   5. `maybe` lowering and error propagation
   6. Exceptions (if any), unwinding, and panic/abort strategy
   7. Debug info (source locations, DWARF/PDB obligations)
   8. Required and optional LLVM optimization passes
   9. Linkage, visibility, and symbol naming conventions
5. Runtime Requirements
   1. Minimum runtime surface required by generated code
   2. Entry, initialization, and shutdown coordination
   3. Allocation, deallocation, and memory services
   4. Failure modes (panic/abort), diagnostics integration
   5. Platform interoperability and C ABI boundary

---

# 1. Overview

## 1.1 Purpose and scope

This document specifies the required behavior of a Cloth compiler toolchain. Its primary purpose is to define a stable and implementable contract between:

1. **Cloth programs** (source files and build configuration).
2. **Cloth frontends** (lexing, parsing, semantic analysis).
3. **Cloth backends** (Cloth IR construction, optimization, and lowering).
4. **LLVM** (LLVM IR semantics, optimization passes, and code generation).
5. **The runtime and platform** (ABI, linking, calling conventions, and required services).

This specification is **backend-focused**. The Cloth Language Specification is authoritative for surface syntax and language semantics (types, ownership rules, evaluation semantics, and required diagnostics). This document is authoritative for:

1. The compiler’s externally observable stage obligations and boundary contracts.
2. The structure, invariants, and semantics of Cloth IR.
3. The lowering of Cloth IR into LLVM IR.
4. The emitted artifact properties and the runtime/link requirements implied by code generation.

This document intentionally does **not** attempt to redefine the language semantics. Any contradiction between this document and the Cloth Language Specification is resolved as follows:

1. If the question is about **surface language meaning** (parsing, name binding, typing, ownership/lifetime rules, evaluation order, statement behavior), the Cloth Language Specification is authoritative.
2. If the question is about **backend representation, IR invariants, or the mapping to LLVM**, this document is authoritative.
3. If a conflict remains within overlapping scope, the implementation MUST emit a diagnostic and MUST treat the relevant construct as ill-formed for purposes of a conforming build.

## 1.2 Relationship to the Cloth Language Specification

The Cloth Language Specification defines the source-level semantics and imposes obligations on implementations (compilers, analyzers, formatters, runtime libraries). This compiler specification refines those obligations by defining:

1. **Compilation stage outputs**: what data structures must conceptually exist (even if not materialized on disk) at each stage boundary.
2. **IR meaning**: how source-level constructs are represented in Cloth IR.
3. **Lowering meaning**: how Cloth IR constructs are represented in LLVM IR such that program behavior matches the language’s dynamic semantics.

The compiler specification MUST be interpreted as a strengthening of the language specification, not as an alternative. In particular:

1. A compiler conforming to this document MUST reject all programs that the language specification defines as ill-formed.
2. A compiler conforming to this document MUST preserve the observable dynamic semantics of all well-formed programs.
3. A compiler conforming to this document MUST NOT introduce new observable behaviors beyond those permitted by the language specification.

## 1.3 Conformance claims and profiles

An implementation MAY claim conformance to this specification under one or more profiles. A conformance claim MUST explicitly name:

1. The supported Cloth language edition(s).
2. The supported target triples / platforms.
3. The LLVM major version(s) used for code generation.
4. The conformance profile(s) claimed.

This document defines the following conformance profiles.

1. **Backend compiler conformance**
   1. The implementation consumes a semantically validated program representation (AST with resolved symbols/types/ownership) and produces LLVM IR and/or machine code artifacts.
   2. The implementation MUST implement Cloth IR semantics as defined by this document.
   3. The implementation MUST perform lowering to LLVM IR consistent with this document.

2. **End-to-end compiler conformance**
   1. The implementation implements the full pipeline from source text to artifacts.
   2. It MUST satisfy all frontend obligations from the Cloth Language Specification.
   3. It MUST satisfy all backend obligations from this document.

3. **IR tool conformance**
   1. Tools that consume or produce Cloth IR (optimizers, verifiers, printers) MAY claim conformance.
   2. Such tools MUST preserve Cloth IR invariants and MUST reject invalid IR with diagnostics.

If a requirement is stated as applying to “the compiler”, it applies at minimum to the end-to-end compiler profile; if it is stated as applying to “the backend”, it applies to backend compiler conformance and end-to-end compiler conformance.

## 1.4 Determinism, reproducibility, and build inputs

For Cloth to be a tooling-heavy language, compilation must be predictable.

1. Given identical:
   1. Source text inputs,
   2. Build configuration inputs (manifest and any declared build settings),
   3. Dependency graph contents,
   4. Target triple and codegen settings,
   5. Compiler implementation version,
   6. LLVM version,
   a conforming compiler SHOULD produce bit-identical artifacts. Where bit-identical output cannot be guaranteed due to platform constraints (timestamps, non-deterministic object file metadata), the implementation MUST document which parts are non-deterministic and MUST ensure that the semantic content (symbols, relocations, code behavior) is equivalent.

2. Compilation MUST be functionally deterministic:
   1. The set of accepted programs MUST NOT depend on thread scheduling, hash table iteration order, filesystem enumeration order, or other incidental ordering.
   2. The diagnostics emitted for ill-formed programs MUST be stable with respect to ordering of independent analyses. If a diagnostic order is not specified, the implementation MUST choose a deterministic ordering rule and document it.

3. The compiler MUST treat the program as the transitive closure of modules reachable from the configured build target(s), consistent with the language specification’s build/manifest rules.

## 1.5 Artifacts: outputs and their required properties

An end-to-end compiler MUST produce one or more artifacts based on build configuration. Supported artifact kinds are implementation-defined but commonly include:

1. **Executable**
2. **Static library**
3. **Dynamic library**
4. **Object file(s)**
5. **LLVM IR** (textual `.ll` and/or bitcode `.bc`)
6. **Cloth IR** (if the implementation exposes it)

For any produced artifact, the implementation MUST ensure:

1. **Semantic preservation**: running the artifact exhibits behavior consistent with the language specification.
2. **ABI correctness**: external linkage, calling conventions, alignment, and data layout match the selected target and any declared ABI boundary rules.
3. **Ownership/lifetime enforcement**: any runtime obligations implied by ownership rules (destruction calls, drop glue, finalization, etc.) are correctly generated.

If the compiler emits intermediate forms (Cloth IR, LLVM IR), then those forms MUST be well-formed per the rules in this document and per LLVM’s rules, respectively.

## 1.6 Diagnostics, error handling, and recovery requirements

Diagnostics in the compiler backend MUST adhere to the diagnostic requirements of the Cloth Language Specification (locations, text, clause references) when those requirements apply.

In addition, for backend-specific failures:

1. If Cloth IR generation fails due to an internal inconsistency in the frontend-provided semantic model, the compiler MUST emit a diagnostic that:
   1. Identifies the source construct(s) responsible.
   2. Identifies which backend invariant could not be satisfied.
   3. Provides a stable error code or category suitable for tooling.

2. If an optimization pass encounters invalid IR, it MUST either:
   1. Diagnose and terminate compilation, or
   2. Diagnose and safely skip the pass.
   Silent miscompilation is non-conforming.

3. Backend crashes (uncaught exceptions, process termination) are non-conforming behavior unless the input triggers undefined behavior and the implementation explicitly documents crash-as-diagnostic for that UB class.

## 1.7 Target platforms, ABIs, and LLVM versioning

This toolchain uses LLVM for code generation. Therefore, the compiler MUST define:

1. The mapping from Cloth target configuration to an LLVM target triple.
2. The LLVM data layout string used for each supported target.
3. The calling convention rules for Cloth functions and for foreign functions.

LLVM is a moving target. The implementation MUST specify the LLVM major version(s) it is compatible with. If behavior differs across LLVM versions (for example due to optimizer changes), the implementation MUST document any user-visible consequences and SHOULD provide an option to pin behavior by pinning LLVM.

## 1.8 Security, safety, and undefined behavior boundaries

The language specification defines undefined behavior at the language level. This document defines additional compiler-backend obligations to prevent introducing UB when lowering.

1. The backend MUST NOT assume properties that are not justified by:
   1. Proven static semantic facts (types/ownership), or
   2. Explicitly stated language guarantees.

2. When lowering to LLVM IR, the backend MUST NOT attach LLVM-level attributes, metadata, or `undef`/`poison`-sensitive transforms unless the corresponding assumptions are sound under Cloth semantics.

3. When representing memory, aliasing, and lifetimes, the backend MUST ensure that any LLVM `noalias`, `nonnull`, `dereferenceable`, `noundef`, or lifetime intrinsics are only emitted when provably valid.

## 1.9 Notation and conventions used in this document

1. When this document says “Cloth IR”, it refers to the intermediate representation defined in Section 3.
2. When this document says “LLVM IR”, it refers to the IR language defined by LLVM for the selected LLVM version.
3. Examples are informative unless explicitly labeled as normative.

---

## 2. Compilation Pipeline

The compilation pipeline is presented as an abstract sequence of stages. Implementations MAY fuse stages, run them incrementally, or implement them in a different internal architecture; however, the externally observable behavior MUST be equivalent to having applied the stages in an order consistent with the dependencies described in this section.

The canonical conceptual pipeline is:

```text
Lexer
  ↓
Parser
  ↓
AST
  ↓
Semantic Analysis (types, ownership, visibility, etc.)
  ↓
Cloth IR (canonical backend IR)
  ↓
LLVM IR Emitter
  ↓
LLVM (opt + codegen)
```

### 2.1 Stage boundaries and required stage outputs

This section defines compilation as a sequence of conceptual stage boundaries. These boundaries are normative contracts; an implementation MAY merge stages internally, but it MUST behave as though the following boundary outputs exist and satisfy the constraints specified here.

At each stage boundary, the following requirements apply.

1. **Failure propagation**
   1. If a stage determines that its input is ill-formed (per applicable rules), the implementation MUST emit at least one diagnostic and MUST NOT proceed as though the stage succeeded.
   2. Implementations MAY continue with later stages for the purpose of emitting additional diagnostics (error recovery), but MUST NOT emit final build artifacts while claiming conformance.

2. **Boundary completeness**
   1. The output of each stage MUST contain sufficient information for later stages to operate deterministically.
   2. If a later stage requires information not provided by the immediately preceding stage, then either:
      1. The stage boundary definition is incomplete (this specification must be amended), or
      2. The later stage is non-conforming.

3. **Source location tracking**
   1. Every stage output MUST preserve source locations at a granularity sufficient to satisfy diagnostic requirements.
   2. In particular, Cloth IR generation MUST preserve a mapping from IR constructs back to the governing source spans (directly or indirectly) so that backend diagnostics can cite source locations.

4. **Deterministic ordering**
   1. If the output contains ordered collections (for example lists of declarations, functions, or IR blocks), the implementation MUST define a deterministic ordering rule.
   2. The chosen ordering MUST NOT depend on nondeterministic platform properties (filesystem enumeration order, hash iteration order, or thread schedules).

The canonical stage outputs are:

1. **Token stream** (output of lexing)
2. **AST** (output of parsing)
3. **Semantically validated program model** (output of semantic analysis)
4. **Cloth IR module(s)** (output of Cloth IR generation)
5. **LLVM IR module(s)** (output of LLVM lowering/emission)
6. **Object file(s) / libraries / executable** (output of code emission and linking)

### 2.2 Lexing

Lexing converts source text into a token stream. Lexing is governed by the Cloth Language Specification lexical section; this document imposes additional toolchain integration obligations.

1. The compiler MUST tokenize source files according to the lexical rules of the Cloth Language Specification.
2. The compiler MUST treat the token stream as the sole input to the parser.
3. The lexer MUST preserve:
   1. Token kind.
   2. Token lexeme (lossless spelling).
   3. Token span.
4. The lexer MUST NOT perform name binding, type checking, ownership analysis, constant evaluation, or any semantic interpretation beyond token classification.

Lexing output is a sequence of tokens terminated by an explicit end-of-file sentinel per compilation unit.

### 2.3 Parsing

Parsing converts a token stream into an abstract syntax tree (AST). Parsing is governed by the grammar and syntactic well-formedness rules of the Cloth Language Specification.

1. The parser MUST be deterministic.
2. For accepted programs, the parser MUST produce an AST that preserves:
   1. The full syntactic structure of the input.
   2. Source spans for all syntactic constructs required by diagnostics.
3. For ill-formed token sequences:
   1. The parser MUST emit at least one diagnostic.
   2. The parser MAY recover and produce a partial AST, but any recovered AST MUST be explicitly marked as containing errors so that later stages do not treat it as fully valid.

The AST is the sole normative representation of syntactic structure at the boundary between parsing and semantic analysis.

### 2.4 Semantic analysis (types, ownership, visibility, etc.)

Semantic analysis assigns meaning to the AST by performing name resolution, type checking, ownership/lifetime validation, visibility/accessibility enforcement, and any other static checks required by the Cloth Language Specification.

Although this compiler specification focuses on the backend, semantic analysis defines the contract that the backend is permitted to rely on.

#### 2.4.1 Required semantic facts provided to the backend

For a program that successfully passes semantic analysis, the implementation MUST provide a semantically validated program model containing at least the following facts.

1. **Canonical symbol identity**
   1. Every reference to a declaration MUST be resolved to a unique canonical declaration identity.
   2. Overload resolution MUST be completed; every call site MUST identify the callee signature selected.

2. **Complete static types**
   1. Every expression and every declaration that participates in code generation MUST have a fully determined static type.
   2. All implicit conversions and coercions required by the language semantics MUST be explicit in the validated model (either as explicit AST nodes or explicit semantic edges).

3. **Ownership and lifetime classification**
   1. Each value whose lifetime is non-static MUST be classified by lifetime domain and ownership relationship as required by the language rules.
   2. Moves, borrows, and transfers MUST be resolved so that code generation can be performed without re-running ownership inference.

4. **Control-flow structure and reachability**
   1. The validated model MUST represent structured control flow (blocks, loops, conditionals, early exits) sufficiently to permit IR generation.
   2. The implementation MUST identify unreachable code when it is required to do so by the language specification.

5. **Constant evaluation results**
   1. Any compile-time constants required for code generation (for example array lengths, layout parameters, or constant initializers) MUST be evaluated or otherwise represented as constant expressions that can be lowered deterministically.

#### 2.4.2 Backend assumptions and forbidden assumptions

1. The backend MAY assume that the validated program model satisfies all language-level static constraints.
2. The backend MUST NOT assume:
   1. That any pointer is non-null unless the language semantics guarantee it.
   2. That any reference is unique or non-aliasing unless the ownership/lifetime rules guarantee it.
   3. That integer overflow is impossible unless the language semantics define overflow behavior accordingly.

### 2.5 Cloth IR generation

Cloth IR generation lowers the semantically validated program model into a canonical backend IR suitable for optimization and for systematic lowering to LLVM IR.

The output of this stage is one or more Cloth IR modules.

#### 2.5.1 Cloth IR generation obligations

1. **Semantic preservation**
   1. Cloth IR generation MUST preserve the observable behavior of the program as defined by the language specification.
   2. Any transformation performed during IR generation (desugaring, implicit destructor insertion, implicit temporary creation) MUST be semantics-preserving.

2. **Explicitness of implicit semantics**
   1. All implicit operations that affect runtime behavior MUST be made explicit in Cloth IR.
   2. This includes, but is not limited to:
      1. Construction and destruction operations.
      2. Ownership transfers and move semantics.
      3. Implicit copies (if permitted by the language) and their runtime cost.
      4. Implicit conversions and coercions.
      5. Control-flow lowering decisions that affect evaluation order.

3. **Evaluation order**
   1. Where the language specification defines an evaluation order, Cloth IR generation MUST preserve it.
   2. Where the language specification permits reordering, Cloth IR generation MAY choose any permitted ordering but MUST do so deterministically.

4. **Totality for well-formed programs**
   1. For any well-formed program within the implementation’s supported feature set, Cloth IR generation MUST succeed.
   2. If a construct is intentionally unsupported by the backend implementation, the compiler MUST emit a diagnostic that explicitly states that the feature is unimplemented and MUST cite the relevant language clause.

#### 2.5.2 Required information carried into Cloth IR

Cloth IR MUST preserve, directly or via attached metadata:

1. The static type of every value.
2. The ownership/lifetime domain of values where it affects destruction or aliasing assumptions.
3. The source location mapping needed for diagnostics and debug info.
4. A stable symbol naming scheme sufficient for linking and for cross-module references.

### 2.6 Cloth IR validation and canonicalization

Cloth IR is the primary boundary at which backend correctness is established. Therefore, the compiler MUST validate Cloth IR prior to applying optimization passes that assume IR well-formedness.

1. A conforming compiler MUST define an internal or external verifier that checks Cloth IR invariants.
2. If invalid Cloth IR is produced, the compiler MUST emit a diagnostic and MUST NOT continue as though the IR were valid.

Canonicalization is a semantics-preserving normalization pass that ensures later passes observe a consistent IR shape.

1. A conforming implementation SHOULD define a canonical form for Cloth IR (for example, normalized boolean branching, normalized temporary introduction, normalized destruction points).
2. If canonicalization is performed, it MUST be semantics-preserving and MUST be deterministic.

### 2.7 Optimization over Cloth IR

Optimization over Cloth IR is permitted only when it preserves the language-level observable behavior.

#### 2.7.1 General optimization constraints

1. An optimization MUST NOT:
   1. Change the observable results of program execution as defined by the language specification.
   2. Introduce undefined behavior in executions that were well-defined at the language level.
   3. Remove required side effects (including destructor/finalizer effects).

2. If the language semantics require a specific failure mode (for example, guaranteed trap/panic on a specific condition), optimizations MUST preserve that requirement.

3. Optimizations MUST respect the language’s rules for:
   1. Volatile or externally observable memory (if applicable).
   2. Foreign function boundaries.
   3. Any semantics of `maybe` error propagation that affect which paths are executed.

#### 2.7.2 Ownership-aware optimization constraints

Because Cloth has ownership and lifetime semantics, the following additional constraints apply.

1. An optimization MUST NOT reorder destruction or finalization across observable side effects unless the language specification explicitly permits it.
2. An optimization MUST NOT eliminate a destructor call unless it can prove that the destructor is semantically a no-op under the program’s semantics and that eliminating it cannot affect external behavior.
3. An optimization MUST preserve the semantics of moves and borrows; in particular, it MUST NOT introduce additional uses of moved-from values.

### 2.8 LLVM IR lowering and emission

LLVM IR lowering converts Cloth IR into LLVM IR modules suitable for LLVM optimization and code generation.

#### 2.8.1 Lowering correctness obligations

1. For any Cloth IR construct, the emitted LLVM IR MUST have equivalent semantics under the selected target’s data layout and calling conventions.
2. The lowering MUST preserve:
   1. Control flow (including exceptional/error paths if present).
   2. Memory effects and aliasing behavior as permitted by the language.
   3. Destruction/finalization points implied by ownership semantics.

#### 2.8.2 LLVM attribute and metadata soundness

LLVM IR is sensitive to incorrect “strengthening” metadata.

1. The compiler MUST NOT attach LLVM function or parameter attributes that strengthen semantics (for example `noalias`, `nonnull`, `noundef`, `dereferenceable`, `readonly`, `readnone`) unless they are sound under Cloth semantics.
2. The compiler MUST NOT use LLVM `undef` or `poison` producing operations unless the corresponding behavior is permitted by Cloth semantics in the relevant execution.
3. If the compiler emits lifetime intrinsics, they MUST be consistent with actual object lifetimes; otherwise, the optimizer may miscompile.

### 2.9 LLVM optimization pipeline

After LLVM IR emission, the compiler MAY run LLVM optimization passes.

1. The chosen pass pipeline MUST be deterministic for a given configuration.
2. If the implementation offers optimization levels (for example `-O0`, `-O1`, `-O2`, `-O3`), then:
   1. Each level MUST correspond to a documented pipeline.
   2. Increasing optimization level MUST NOT change language-level semantics.

3. The compiler MUST ensure that any LLVM optimizations that depend on undefined behavior assumptions are only enabled when those assumptions are valid for Cloth.

### 2.10 Code generation, object emission, and linking

LLVM code generation produces target-specific object files and ultimately a linked artifact.

#### 2.10.1 Object emission

1. The compiler MUST emit object files that conform to the target platform’s object format (COFF/ELF/Mach-O as appropriate).
2. The compiler MUST ensure that symbol visibility, linkage, and calling conventions match the rules defined in this document and any platform ABI obligations.

#### 2.10.2 Linking

1. The compiler MUST define whether it performs linking directly or invokes an external linker.
2. If an external linker is used, the compiler MUST:
   1. Invoke it deterministically.
   2. Pass all required runtime objects and libraries.
   3. Preserve the selected target triple, relocation model, and ABI constraints.

#### 2.10.3 Runtime integration points

If code generation depends on runtime-provided functions (for example allocation, panic/abort handlers, or entrypoint glue), the compiler MUST:

1. Define the required symbol names and calling conventions.
2. Ensure that missing runtime symbols are diagnosed as link-time errors with clear messaging.
3. Ensure that the runtime integration does not violate ownership/lifetime semantics (for example by skipping required destruction).

---

# 3. Cloth IR

## 3.1 Design goals and non-goals

Cloth IR is a typed, SSA-based intermediate representation designed to act as the canonical boundary between:

1. Frontend semantic analysis (which establishes source-level meaning), and
2. Backend lowering and optimization (which must preserve that meaning).

The central purpose of Cloth IR is to make *implicit* language semantics explicit (construction, destruction, moves, borrows, and error flow), while remaining sufficiently low-level and structured to lower deterministically to LLVM IR.

### 3.1.1 Design goals

1. **Semantic fidelity**
   1. Cloth IR MUST be capable of expressing all semantics of the language edition targeted by this specification.
   2. Lowering source semantics into Cloth IR MUST NOT require heuristics or implementation-defined guesses.

2. **Deterministic lowering to LLVM**
   1. For any well-formed Cloth IR module, lowering to LLVM IR MUST be a deterministic function of:
      1. The IR module,
      2. The selected target,
      3. The selected ABI configuration.

3. **Typed representation**
   1. Every value in Cloth IR MUST have an explicit static type.
   2. Type checking of Cloth IR MUST be decidable and MUST be enforced by the IR verifier (Section 3.11).

4. **Ownership visibility**
   1. Ownership and lifetime semantics that affect runtime behavior MUST be representable in Cloth IR.
   2. The IR MUST represent destruction/finalization points explicitly.

5. **Optimization safety**
   1. Cloth IR MUST define a memory/aliasing model sufficient to justify optimization without relying on unsound assumptions.
   2. Optimization passes MUST be able to rely on verifier-checked invariants.

### 3.1.2 Non-goals

1. **Source-level syntax preservation**
   1. Cloth IR is not required to preserve surface syntax or formatting.
   2. It is required to preserve *source locations* for diagnostics and debug info, not source spellings.

2. **Stability of textual spelling**
   1. A textual serialization (if provided) is primarily for debugging and tooling.
   2. Unless a later section explicitly makes a textual form normative, the exact printed spelling is not part of the conformance surface.

3. **Direct human authoring**
   1. Cloth IR is not designed to be written by humans.
   2. Tools MAY allow manual IR authoring for research, but such authoring is non-normative.

## 3.2 IR unit structure (modules, functions, globals)

### 3.2.1 Modules

A Cloth IR **module** is the unit of compilation and lowering. A module contains:

1. A target configuration (at minimum a target triple identifier and data layout identifier).
2. A set of type declarations.
3. A set of global declarations.
4. A set of function declarations and function definitions.
5. Optional metadata tables (debug/source mapping, optimization hints).

The module is the unit at which:

1. Symbol naming and linkage are defined.
2. Cross-function invariants are validated.
3. Whole-module lowering decisions (for example, layout choices) are fixed.

### 3.2.2 Symbol identity and linkage

Every externally visible entity in Cloth IR MUST have:

1. A **symbol name** (string) used for linkage.
2. A **linkage kind**, one of:
   1. `internal` (not visible outside the module),
   2. `export` (visible outside the module),
   3. `import` (declared but defined elsewhere).

The implementation MUST define a deterministic mangling scheme from language-level entities to symbol names.

1. Mangling MUST be injective within a program: distinct language-level entities MUST NOT collide.
2. Mangling MUST be stable with respect to deterministic compilation inputs (Section 1.4).
3. Mangling MUST not depend on memory addresses, hash iteration order, or concurrency.

### 3.2.3 Globals

A Cloth IR **global** is a module-level storage location.

1. A global MUST have a type.
2. A global MUST specify whether it is:
   1. `constant` (immutable after initialization), or
   2. `mutable`.
3. A global MUST specify initialization form:
   1. `const_init` (compile-time known initializer), or
   2. `runtime_init` (initializer code executed during program initialization).

The mapping of global initialization order to runtime behavior MUST preserve the language-level initialization semantics.

### 3.2.4 Functions

A Cloth IR **function** has:

1. A symbol name.
2. A function type (parameter types and return type).
3. A calling convention identifier.
4. Linkage (`internal`, `export`, `import`).
5. A body consisting of basic blocks (for definitions) or no body (for declarations/imports).

For an `import` function, the implementation MUST specify the external ABI used and the lowering rules MUST treat the function as an ABI boundary.

## 3.3 Representation and serialization

Cloth IR is defined abstractly in this document. Implementations MAY choose any in-memory representation.

If an implementation serializes Cloth IR to disk (for example for debugging, caching, or tooling), it MUST satisfy:

1. **Round-trippability**
   1. Serializing and deserializing MUST preserve semantic content and verifier-relevant invariants.
   2. The serialization MUST be deterministic.

2. **Versioning**
   1. A serialized form MUST carry a version identifier.
   2. Tools MUST reject unknown major versions with diagnostics.

Unless a future section defines a normative textual grammar, the exact printed spelling is informative.

## 3.4 Type system and type representation

Cloth IR types represent lowered source-level types but remain distinct from LLVM types.

### 3.4.1 Type categories

The canonical IR type categories are:

1. **Scalar types**
   1. Signed integers: `i8`, `i16`, `i32`, `i64`, `i128`.
   2. Unsigned integers: `u8`, `u16`, `u32`, `u64`, `u128`.
   3. Booleans: `bool`.
   4. Floating-point: `f16`, `f32`, `f64`.
   5. `unit` (the type with exactly one value).

2. **Pointer-like types**
   1. `ptr<T>`: a raw address pointer to `T` (semantics defined by Section 3.13).
   2. `ref<T>`: a reference with verifier-checked validity/aliasing constraints (semantics defined by Section 3.13).

3. **Aggregate types**
   1. `struct { f0: T0, f1: T1, ... }`.
   2. `tuple(T0, T1, ...)`.
   3. `array<T, N>` where `N` is a compile-time constant.

4. **Nominal types**
   1. `nominal<Name>` represents a declared type with a fixed layout policy.
   2. The mapping from `nominal<Name>` to its layout MUST be defined within the module (or imported in a verifiable manner).

5. **Function types**
   1. `fn(T0, T1, ...) -> R`.

6. **Maybe / error-flow types**
   1. Cloth IR MUST represent `maybe` semantics explicitly.
   2. The canonical representation is `result<Ok, Err>` where `Err` is an error carrier type.
   3. Section 3.15 defines the required IR-level representation; Section 4.5 defines the required LLVM lowering shape.

### 3.4.2 Type identity and equality

1. Scalar types are equal by spelling.
2. Two aggregate types are equal if and only if their structure is equal recursively and any required layout parameters match.
3. Two `nominal<Name>` types are equal if and only if they refer to the same canonical type declaration identity.

### 3.4.3 Layout obligations

Cloth IR MUST define, for every sized type:

1. Size in bytes.
2. Alignment in bytes.
3. Field offsets for aggregates.

These layout facts MUST be deterministic functions of:

1. The type structure,
2. The target data layout,
3. Any explicitly declared packing/alignment rules.

If a type is unsized, the IR MUST represent it using a sized handle type (for example a pointer + metadata pair) or MUST reject it as unsupported.

## 3.5 Values, SSA, and naming

### 3.5.1 SSA form

Cloth IR values within a function body are in static single assignment (SSA) form.

1. Every SSA value MUST be defined exactly once.
2. Every use of an SSA value MUST be dominated by its definition.
3. Control-flow merges MUST be represented using explicit `phi` nodes or an equivalent verifier-checkable mechanism.

SSA values do not, by themselves, imply storage. Storage is represented explicitly via allocations and memory operations (Section 3.13).

### 3.5.2 Value kinds

The canonical value kinds are:

1. **Immediate constants** (integers, floats, boolean, unit).
2. **SSA temporaries** produced by instructions.
3. **Function parameters**.
4. **Global addresses**.
5. **Basic-block parameters** are not part of canonical Cloth IR (Section 3.19). If used internally, they MUST be lowered to `phi` nodes prior to conformance-critical verification, optimization, or lowering.

### 3.5.3 Naming

1. SSA value names are not semantically significant.
2. If printed, implementations SHOULD provide stable names to support deterministic diffs.
3. Symbol names for globals and functions are semantically significant for linking (Section 3.2.2).

## 3.6 Instruction model

Cloth IR instructions are typed operations that produce zero or more SSA results and may have side effects.

### 3.6.1 Purity and side effects

Every instruction MUST be classified as either:

1. **Pure**: no side effects, result depends only on operands.
2. **Effectful**: may read/write memory, may allocate, may call, may throw/propagate errors, may influence control flow.

The IR verifier MUST enforce that optimizations only reorder or eliminate instructions in ways that preserve the semantics of effectful instructions.

### 3.6.2 Canonical instruction categories

The instruction set is defined in terms of categories. Implementations MAY refine into a richer set, but MUST preserve the category semantics.

1. **Arithmetic and bitwise**
   1. `add`, `sub`, `mul`, `div`, `rem` for integer and floating types.
   2. `and`, `or`, `xor`, `shl`, `shr` for integer types.
   3. Overflow behavior MUST match the language semantics. The IR MUST NOT silently assume no-overflow unless proven.

2. **Comparisons**
   1. `icmp` and `fcmp` with explicit predicate.
   2. Predicate set MUST be sufficient to represent language-level comparisons.

3. **Control flow**
   1. `br` (conditional branch), `jmp` (unconditional jump).
   2. `ret`.
   3. `unreachable` (marks a path that cannot be executed for any well-formed program execution).
   4. `switch` MAY exist but is not required.

4. **Value construction and aggregation**
   1. `make_struct`, `get_field`, `set_field` (or equivalent).
   2. `make_tuple`, `get_elem`.
   3. `insert`, `extract` forms MUST have well-defined semantics without undefined padding behavior.

5. **Memory and addressing**
   1. `alloca` (stack allocation) with explicit type and count.
   2. `load` and `store` with explicit type.
   3. `addr_of_global`.
   4. `ptr_offset` / `gep`-like computation with in-bounds rules defined by the memory model.
   5. `memcpy`, `memmove`, `memset` MAY exist but MUST be modeled as effectful.

6. **Calls and returns**
   1. `call` with explicit callee and calling convention.
   2. Calls that can fail under `maybe` MUST use explicit error-flow constructs (Section 3.8).

7. **Ownership and lifetime**
   1. `move` (transfer of ownership)
   2. `borrow` (creation of a reference under borrow rules)
   3. `drop` (explicit destruction/finalization)
   4. `retain`/`release` MAY exist for shared-handle mechanisms, if the language semantics require it.

8. **Type conversion**
   1. `cast` instructions MUST be explicit and typed.
   2. Bit-level casts MUST be distinguished from value-preserving casts.

### 3.6.3 Instruction source mapping

Every instruction that can trigger diagnostics, runtime traps, or other user-visible behavior MUST be associated with a source span.

## 3.7 Control-flow graph model

### 3.7.1 Basic blocks

A function body is a control-flow graph (CFG) of basic blocks.

1. A **basic block** is a sequence of non-terminator instructions followed by exactly one terminator instruction.
2. Terminators are control-flow instructions (`br`, `jmp`, `ret`, `unreachable`, etc.).
3. Control can enter a block only via its predecessor edges.

### 3.7.2 Dominance and SSA correctness

1. The verifier MUST enforce SSA dominance rules.
2. If the IR uses `phi` nodes, `phi` nodes MUST:
   1. Appear at the beginning of a block (before non-phi instructions), and
   2. Provide one incoming value per predecessor edge.

### 3.7.3 Critical edges and canonicalization

Implementations MAY split critical edges during canonicalization, but must preserve semantics.

## 3.8 Memory model and aliasing model

This section defines the minimum memory semantics required for correct lowering and optimization.

### 3.8.1 Abstract machine memory

1. Memory is a collection of **allocations**.
2. Each allocation has:
   1. A base address,
   2. A size in bytes,
   3. An alignment,
   4. A lifetime interval (creation to end-of-lifetime),
   5. Optionally, an associated dynamic type.

3. A pointer value in Cloth IR denotes:
   1. An allocation identity, and
   2. An offset within that allocation.

4. Pointer arithmetic MUST be represented explicitly.

### 3.8.2 Definedness and initialization

1. The IR MUST distinguish between:
   1. Allocated-but-uninitialized memory, and
   2. Initialized memory containing a value of some type.

2. A `load` from uninitialized memory is undefined behavior unless the language semantics define it otherwise.
3. The backend MUST NOT use LLVM `undef`/`poison` as a substitute for Cloth-level uninitialized state unless this mapping is proven sound.

### 3.8.3 Aliasing model

The IR MUST support conservative aliasing by default.

1. Unless proven by ownership/borrowing facts, two pointers/references MUST be assumed to potentially alias.
2. Any IR-level aliasing fact used to justify optimization MUST be representable as verifier-checkable metadata derived from validated ownership semantics.

### 3.8.4 Volatile and foreign memory

If the language specification defines volatile or foreign-memory semantics, Cloth IR MUST represent such operations explicitly so that they are not optimized away.

## 3.9 Ownership, lifetimes, and destruction semantics in IR

Cloth IR MUST represent ownership-driven destruction as explicit operations.

### 3.9.1 Owned values and moves

1. An owned value has a unique destruction responsibility.
2. A `move` transfers this responsibility to another SSA value or storage location.
3. After a move, using the moved-from value is ill-formed IR.
4. The verifier MUST reject IR that uses moved-from values.

### 3.9.2 Borrowed references

1. `borrow` creates a `ref<T>` that is valid only within a statically defined region.
2. The IR MUST represent borrow scopes sufficiently for the verifier to ensure that:
   1. A reference is not used beyond its region.
   2. Mutability and aliasing constraints (if any) are preserved.

### 3.9.3 Drop / destruction

1. `drop` is the canonical instruction that triggers destruction/finalization of an owned value.
2. For every owned value whose lifetime ends during execution, exactly one `drop` MUST occur on every dynamic path that ends that lifetime.
3. A `drop` MUST NOT occur more than once for the same owned value.
4. The verifier MUST enforce that drops are balanced with moves and that double-drop is rejected.

The ordering of `drop` relative to other side effects MUST preserve the language-level destruction ordering.

## 3.10 Calls, ABI boundaries, and foreign interfaces

### 3.10.1 Call instruction requirements

1. A `call` MUST specify:
   1. Callee identity (direct symbol or an indirect function pointer value).
   2. Calling convention.
   3. Argument values.
   4. Return value receiving (including `unit` for void-like returns).

2. Calls MUST be treated as effectful unless the callee is proven pure under a rule explicitly defined in this specification.

### 3.10.2 ABI boundaries

At ABI boundaries (imports/exports/FFI), the IR MUST:

1. Make representation choices explicit (by-value vs by-reference, ownership transfer across boundary).
2. Require explicit marshaling instructions where representation differs.
3. Preserve the platform ABI and this document’s linkage rules.

### 3.10.3 Panic/abort and failure paths

If the language has a panic/abort mechanism, Cloth IR MUST represent such paths explicitly (for example via a `trap` instruction or a `call` to a well-known runtime function followed by `unreachable`).

## 3.11 Required IR validation rules

The implementation MUST provide a verifier that rejects invalid Cloth IR with diagnostics. At minimum, the verifier MUST enforce:

1. **Type correctness**
   1. Every instruction’s operand types satisfy the instruction’s type rules.
   2. Every SSA value has exactly one type.

2. **CFG well-formedness**
   1. Every basic block ends with exactly one terminator.
   2. Every branch target exists.
   3. The entry block is unique.

3. **SSA well-formedness**
   1. Dominance constraints.
   2. `phi` correctness (incoming values match predecessors).
   3. No use-before-def.

4. **Memory operation validity**
   1. `load` and `store` address types are valid.
   2. Alignment requirements are satisfied or are made explicit by defined unaligned-access semantics.
   3. Pointer offsets remain within allocation bounds unless the IR explicitly permits out-of-bounds sentinel pointers (if so, the permitted form MUST be defined).

5. **Ownership correctness**
   1. No use-after-move.
   2. No double-drop.
   3. Drops occur on all required dynamic paths.

6. **Source mapping presence**
   1. Every instruction that may trigger a diagnostic or user-visible failure MUST have a source span.

IR that fails verification is ill-formed. A conforming compiler MUST NOT lower ill-formed Cloth IR to LLVM IR.

## 3.12 Canonical forms, normalization, and required invariants

This section defines *canonical forms* that later stages (optimizers and lowerers) are permitted to assume.

1. An implementation MAY choose additional canonicalization rules; however, any rule in this section is a required canonical form whenever the IR claims to be in “canonical” state.
2. If an implementation runs optimizations that depend on canonical form, it MUST ensure canonicalization has been applied.

### 3.12.1 Terminator completeness

1. Every basic block MUST end with exactly one terminator.
2. No instruction may appear after a terminator.
3. The set of successors of a terminator MUST be explicit in the terminator operands.

### 3.12.2 Single representation of boolean branching

To reduce ambiguity in lowering:

1. Conditional control flow MUST be represented using `br cond, then_block, else_block` where `cond` has type `bool`.
2. Integer-as-boolean branching MUST NOT exist in canonical IR.
3. If the source language permits truthiness, the conversion MUST be explicit as a comparison operation before branching.

### 3.12.3 Structured error-flow canonicalization

If the program uses `maybe` semantics, canonical Cloth IR MUST represent error propagation using the `result` conventions defined in Section 3.15.

### 3.12.4 Explicit destruction points

1. Canonical Cloth IR MUST contain explicit `drop` instructions for all owned values whose lifetime ends in the function.
2. Canonical Cloth IR MUST NOT rely on implicit “end of scope” semantics.
3. If the implementation uses a deferred-drop representation during IR construction, it MUST be fully resolved prior to optimization.

## 3.13 Pointers, references, and memory operations

This section is normative and defines the operational meaning of memory instructions.

### 3.13.1 `ptr<T>` versus `ref<T>`

Cloth IR distinguishes:

1. `ptr<T>`: a raw address that participates in the memory model. It carries no borrow/aliasing guarantees beyond those explicitly stated.
2. `ref<T>`: a reference whose validity and aliasing constraints are justified by ownership/borrow facts.

In canonical IR:

1. Any operation that may violate reference validity MUST operate on `ptr<T>`, not on `ref<T>`.
2. Converting a `ref<T>` to `ptr<T>` MUST be explicit (for example `ref_to_ptr`).
3. Creating a `ref<T>` from a `ptr<T>` MUST be explicit and MUST be verifier-checked (for example `ptr_to_ref`) and is only permitted when the required reference preconditions are provably satisfied.

This explicit distinction is required so that LLVM attribute emission can be made sound: `ref<T>` is the only form that can justify strengthening assumptions, and only when the verifier proves the assumptions.

### 3.13.2 Allocation model and `alloca`

`alloca` creates a stack allocation in the current function.

1. `alloca T, count` produces a value of type `ptr<T>`.
2. `count` MUST be an integer type and MUST be non-negative.
3. The allocation size in bytes is `sizeof(T) * count`.
4. The allocation alignment is `alignof(T)` unless an explicit alignment operand is provided; if provided, it MUST be a power of two and MUST be >= `alignof(T)`.
5. The lifetime of an `alloca` allocation begins immediately after the `alloca` executes.
6. The lifetime ends at:
   1. Function return, or
   2. An explicit `stack_free`/lifetime-end instruction, if the IR provides it.

If the implementation emits explicit stack lifetime intrinsics later (for LLVM), the lifetime interval used MUST correspond exactly to the interval defined above.

### 3.13.3 `load` semantics

`load` reads a value of type `T` from memory.

1. `load T, addr` requires `addr` to be `ptr<T>` (or an explicitly convertible pointer).
2. The effective address MUST be aligned to `alignof(T)` unless the `load` explicitly specifies an unaligned access mode that is defined by the IR.
3. If the pointed-to bytes are uninitialized for `T`, the `load` triggers undefined behavior unless the language-level semantics define a specific outcome.
4. A `load` is an effectful instruction (it reads memory) even if it is later optimized.

### 3.13.4 `store` semantics

`store` writes a value of type `T` to memory.

1. `store T, value, addr` requires `value` to have type `T` and `addr` to be `ptr<T>`.
2. The effective address alignment rules match those of `load`.
3. A `store` makes the destination memory initialized for type `T` unless an explicit “store uninit” operation is used.
4. A `store` is effectful.

### 3.13.5 Address computation: `ptr_offset`

`ptr_offset` computes an address derived from a base pointer.

1. `ptr_offset ptr<T>, index, scale` returns `ptr<U>` (where `U` is specified by the instruction) and computes:
   1. `addr = base + index * scale`.
2. Canonical IR MUST require `scale` to equal the target type’s stride (typically `sizeof(U)` for element indexing) unless the instruction is explicitly a byte-offset primitive.
3. If an in-bounds mode is used, then the resulting pointer MUST remain within the same allocation and within bounds of the allocation’s lifetime; violating this is undefined behavior.
4. If a not-in-bounds mode is used, the result pointer may be out of bounds, but dereferencing it (via `load`/`store`) is undefined behavior.

### 3.13.6 Memory intrinsics

If the IR includes bulk memory operations (`memcpy`, `memmove`, `memset`):

1. They MUST be modeled as effectful.
2. Their overlap, alignment, and definedness semantics MUST be explicitly specified.
3. Lowering MUST ensure that LLVM semantics are preserved (for example `memcpy` overlap constraints).

## 3.14 Defined behavior, traps, and `unreachable`

### 3.14.1 Undefined behavior boundaries

Cloth IR MUST NOT use “undefined” as a general escape hatch. Where behavior is undefined, it MUST be categorized.

1. **Language-level UB**: behavior that the language specification marks as UB.
2. **IR-level UB**: behavior that is not permitted by Cloth IR invariants (for example, use-after-move in IR).

Any execution that triggers IR-level UB is non-conforming with respect to IR generation: a conforming compiler MUST NOT generate IR that can trigger IR-level UB on executions that are well-defined at the language level.

### 3.14.2 Traps and `unreachable`

1. `unreachable` denotes a program point that cannot be reached in any execution of a well-formed program.
2. If `unreachable` is executed at runtime, the behavior is undefined unless the implementation defines it to trap.
3. An implementation MAY lower `unreachable` to LLVM `unreachable`.
4. A `trap` instruction (if provided) denotes an intentional runtime failure. Unlike `unreachable`, executing `trap` is defined and MUST terminate execution in an implementation-defined manner (for example abort).

## 3.15 `maybe` / `result` representation and error flow

This section defines the required IR-level representation of `maybe`-based error propagation.

### 3.15.1 Canonical `result<Ok, Err>` value model

In canonical IR, a `maybe`-returning operation is represented as a value of type `result<Ok, Err>`.

1. `result<Ok, Err>` is a sum type with exactly two variants:
   1. `ok(Ok)`
   2. `err(Err)`
2. The representation of `result<Ok, Err>` MUST be fully determined by:
   1. The layout rules of sum types in Section 3.16, and
   2. Target data layout.

### 3.15.2 Construction and inspection operations

Canonical IR MUST provide (either as dedicated instructions or as a standardized library of intrinsics) the following operations:

1. `make_ok Ok, Err, value -> result<Ok, Err>`
2. `make_err Ok, Err, value -> result<Ok, Err>`
3. `is_ok result<Ok, Err> -> bool`
4. `unwrap_ok result<Ok, Err> -> Ok` (requires dynamic precondition `is_ok == true`)
5. `unwrap_err result<Ok, Err> -> Err` (requires dynamic precondition `is_ok == false`)

Executing `unwrap_ok` when the value is `err`, or executing `unwrap_err` when the value is `ok`, is undefined behavior unless the language semantics define a trap/panic outcome.

### 3.15.3 Canonical control-flow pattern for propagation

Error propagation (the source-level `?`-like behavior) MUST be represented by explicit branching.

1. Given `r : result<Ok, Err>`, propagation is represented as:
   1. `cond = is_ok r`
   2. `br cond, ok_block, err_block`
   3. In `ok_block`, `v = unwrap_ok r` and evaluation continues.
   4. In `err_block`, `e = unwrap_err r` and control returns (or otherwise propagates) the error as defined by the surrounding function’s error contract.

This explicit form is required so that LLVM lowering does not invent implicit control flow that could reorder side effects.

### 3.15.4 Interaction with ownership and drops

1. If a computation produces a `result<Ok, Err>` and then branches on it, any owned temporaries created prior to the branch MUST have their drops placed on both arms as required.
2. Error-propagation blocks MUST include drops for owned values that go out of scope on that path.

## 3.16 Nominal types, object layout, and tagging

This section defines the minimum IR obligations for representing nominal types and sum-like tagging.

### 3.16.1 Struct-like nominal layout

For a nominal type whose layout is equivalent to a struct:

1. The IR MUST define a field list with types in a deterministic order.
2. Field offsets MUST be computed deterministically from the target data layout and any explicit packing rules.
3. Padding bytes are permitted, but reading padding as a value is undefined unless explicitly specified.

### 3.16.2 Class-like nominal layout

If the language supports class-like reference types:

1. The IR MUST define whether class values are represented as:
   1. By-value aggregates, or
   2. Heap-allocated objects referenced by a pointer-like handle.
2. If heap-allocated:
   1. The IR MUST define an object header policy (for example, vtable pointer presence) if dynamic dispatch is supported.
   2. Allocation and destruction responsibilities MUST be explicit via `alloc`/`free` and `drop` glue.

### 3.16.3 Enum / sum type representation

`result<Ok, Err>` is a specific case of a general sum type.

1. A sum type is represented as:
   1. A tag field of an integer type large enough to represent all variants, and
   2. A payload area large enough and aligned enough to store the largest variant payload.
2. The exact tag type and payload layout MUST be deterministic.
3. The tag value assignment to variants MUST be deterministic and MUST be documented (for example, in source order starting at 0).

### 3.16.4 Alignment and ABI exposure

If a nominal type is exposed across an ABI boundary, its layout MUST be treated as part of the ABI contract for that boundary.

## 3.17 Drop glue and destruction lowering contract

This section defines how `drop` relates to language-defined destruction behavior.

1. For each type `T` that requires destruction (for example it owns resources or contains owned fields), the backend MUST define a *drop glue* routine `drop_T` (name is illustrative; the mangled symbol is implementation-defined).
2. A `drop` of a value of type `T` is defined as:
   1. Executing `drop_T` on that value, and
   2. Marking the value as no longer owned/usable.

Drop glue MUST:

1. Destroy owned fields in a deterministic order consistent with language ownership semantics.
2. Respect dynamic dispatch requirements if destruction is virtual (if the language supports it).
3. Be idempotent only if the language semantics require idempotence; otherwise double-drop is UB and must be prevented.

The compiler MAY inline drop glue, but the semantics MUST be equivalent to invoking the conceptual routine.

## 3.18 Expanded verifier obligations

The verifier requirements in Section 3.11 are minimums. This section strengthens them to eliminate ambiguity in optimization and lowering.

### 3.18.1 Dominance and control-flow soundness

1. Every SSA use MUST be dominated by its definition.
2. Every `phi` incoming edge MUST correspond to a predecessor.
3. The verifier MUST reject irreducible control flow only if the implementation chooses to forbid it; if permitted, lowering rules MUST specify how it is lowered.

### 3.18.2 Ownership path coverage

For each owned value `v` with required destruction:

1. Along every dynamic path that exits `v`’s lifetime, exactly one `drop v` MUST occur.
2. Along any path where `v` is moved, `drop v` MUST NOT occur after the move unless the move’s destination is proven to be the same ownership instance (which is generally forbidden).
3. The verifier MUST reject IR where drop coverage depends on unspecified control flow.

### 3.18.3 Reference region validity

For each `ref<T>` produced by `borrow` (or equivalent):

1. All uses of the reference MUST occur within the reference’s validity region.
2. The region MUST be representable by verifier-checkable structure (for example dominance-based regions or explicit region markers).

### 3.18.4 ABI boundary checks

1. The verifier MUST enforce that calls to `import` functions match the declared ABI signature.
2. The verifier MUST enforce that `export` functions’ IR signatures match the module’s exported ABI contract.

## 3.19 Canonical SSA merge form

To eliminate representational ambiguity, canonical Cloth IR uses `phi` nodes for SSA merges.

1. Basic-block parameters are NOT part of canonical Cloth IR.
2. If an implementation uses block parameters internally, it MUST lower them into equivalent `phi` nodes prior to:
   1. Verification intended to satisfy Section 3.11 and Section 3.18, and
   2. Any optimization or lowering pipeline that claims conformance to this specification.

## 3.20 Required core instruction set and precise semantics

This section defines a canonical instruction set sufficient to represent Cloth IR programs for edition 1.0.

1. A conforming backend MUST be able to generate and consume (verify, optimize, and lower) all instructions in this section.
2. Implementations MAY introduce additional instructions, but MUST define them in terms of:
   1. Typing rules,
   2. Side-effect classification,
   3. Undefined behavior conditions,
   4. Lowering equivalence to this canonical set.

Unless explicitly stated otherwise:

1. All instruction operands MUST be well-typed.
2. Violating an instruction’s static preconditions makes the IR ill-formed and MUST be rejected by the verifier.
3. Violating an instruction’s dynamic preconditions triggers undefined behavior unless the language semantics require a defined failure mode.

### 3.20.1 Control-flow instructions

#### 3.20.1.1 `br`

Form:

1. `br cond: bool, then: block, else: block`

Semantics:

1. Transfers control to `then` if `cond` is `true`, else transfers control to `else`.
2. `br` is effectful.

Verifier rules:

1. `then` and `else` MUST be distinct blocks unless the implementation explicitly permits degenerate branches.
2. Both successors MUST exist in the function.

#### 3.20.1.2 `jmp`

Form:

1. `jmp target: block`

Semantics:

1. Transfers control unconditionally to `target`.
2. `jmp` is effectful.

#### 3.20.1.3 `ret`

Form:

1. `ret value: R` for a function return type `R`.
2. `ret` with no operand is permitted only for return type `unit`.

Semantics:

1. Returns from the current function.
2. All required destructions for owned values whose lifetimes end at function exit MUST have been made explicit by prior `drop` instructions.

#### 3.20.1.4 `unreachable`

Form:

1. `unreachable`

Semantics:

1. Indicates that control cannot reach this point in any execution of a well-formed program.
2. Executing `unreachable` at runtime is undefined behavior unless the implementation defines it to trap.

#### 3.20.1.5 `trap`

Form:

1. `trap`

Semantics:

1. `trap` is a defined, intentional runtime failure.
2. Executing `trap` MUST terminate program execution in an implementation-defined way.
3. `trap` MUST NOT be treated as undefined behavior by the optimizer.
4. Canonical IR MUST use `trap` (not `unreachable`) for language-defined dynamic failures that are required to be defined failures.

Lowering notes:

1. The backend MAY lower `trap` to:
   1. A call to a well-known runtime abort/panic routine followed by LLVM `unreachable`, or
   2. An LLVM trap intrinsic,
   provided the resulting runtime behavior matches the defined failure semantics.

### 3.20.2 SSA merge instruction

#### 3.20.2.1 `phi`

Form:

1. `%v = phi T [pred0: value0], [pred1: value1], ...`

Typing:

1. `%v` has type `T`.
2. Each incoming `valuei` MUST have type `T`.

Semantics:

1. When control reaches the containing block from predecessor `predi`, `%v` evaluates to `valuei`.
2. `phi` is pure.

Verifier rules:

1. The containing block MUST list exactly one incoming value per predecessor edge.
2. `phi` nodes MUST appear before any non-`phi` instruction in the block.

### 3.20.3 Arithmetic and bitwise instructions

Unless stated otherwise, arithmetic instructions are pure.

#### 3.20.3.1 Integer arithmetic (`add`, `sub`, `mul`, `div`, `rem`)

Typing:

1. Operands MUST be the same integer type (`iN` or `uN`).
2. Result type is the same integer type.

Semantics:

1. Overflow behavior MUST match the language semantics.
2. If the language semantics define overflow as wrapping, the IR MUST represent wrapping behavior explicitly and MUST allow lowering to wrapping operations.
3. If the language semantics define overflow as trapping or as UB, the IR MUST represent that rule explicitly (for example via checked ops or explicit `trap`).

Dynamic preconditions:

1. For `div` and `rem`, division by zero triggers undefined behavior unless the language defines a trap/panic.
2. For signed `div`/`rem`, the `MIN / -1` case MUST follow the language’s rule; if the language defines it as trapping, the IR MUST represent it as defined failure.

#### 3.20.3.2 Bitwise and shifts (`and`, `or`, `xor`, `shl`, `shr`)

Typing:

1. Operands MUST be the same integer type.
2. Result type is that integer type.

Dynamic preconditions:

1. Shift counts MUST be within range as defined by the language semantics. If the language defines out-of-range shift as UB, the IR may treat it as UB; if it defines a trap, the IR MUST represent a defined failure.

### 3.20.4 Comparison instructions

#### 3.20.4.1 `icmp`

Form:

1. `%b = icmp pred, lhs, rhs`

Typing:

1. `lhs` and `rhs` MUST be the same integer type.
2. `%b` has type `bool`.

Semantics:

1. The predicate set MUST include equality and signed/unsigned ordering comparisons as needed.
2. For unsigned integer types, signed predicates MUST NOT be used in canonical IR.

#### 3.20.4.2 `fcmp`

Typing:

1. `lhs` and `rhs` MUST be the same floating type.
2. Result is `bool`.

Semantics:

1. The predicate set MUST be sufficient to encode the language’s NaN behavior.
2. If the language defines total ordering or specific NaN comparison semantics, canonical IR MUST encode that semantics explicitly rather than relying on target-default floating comparisons.

### 3.20.5 Memory instructions

The semantics of memory operations are defined in Section 3.13; this section makes the instruction forms explicit.

#### 3.20.5.1 `alloca`

Form:

1. `%p = alloca T, count`

Result:

1. `%p` has type `ptr<T>`.

#### 3.20.5.2 `load`

Form:

1. `%v = load T, addr`

Typing:

1. `addr` MUST have type `ptr<T>`.

Result:

1. `%v` has type `T`.

#### 3.20.5.3 `store`

Form:

1. `store T, value, addr`

Typing:

1. `value` MUST have type `T`.
2. `addr` MUST have type `ptr<T>`.

#### 3.20.5.4 `addr_of_global`

Form:

1. `%p = addr_of_global @g`

Typing:

1. If global `@g` has type `T`, then `%p` has type `ptr<T>`.

Semantics:

1. Produces a pointer to the global storage.
2. `addr_of_global` is pure.

#### 3.20.5.5 `ptr_offset`

Form:

1. `%q = ptr_offset U, base: ptr<T>, index: iN, scale: iN, mode`

Typing:

1. `%q` has type `ptr<U>`.

Semantics:

1. Defined by Section 3.13.5.

### 3.20.6 Reference conversion instructions

These instructions make reference assumptions explicit.

#### 3.20.6.1 `ref_to_ptr`

Form:

1. `%p = ref_to_ptr r: ref<T>`

Typing:

1. `%p` has type `ptr<T>`.

Semantics:

1. Produces a raw pointer to the same underlying storage.
2. `ref_to_ptr` is pure.

#### 3.20.6.2 `ptr_to_ref`

Form:

1. `%r = ptr_to_ref p: ptr<T>, kind`

Typing:

1. `%r` has type `ref<T>`.

Semantics:

1. Asserts (and requires) that `p` satisfies the reference preconditions associated with `kind`.
2. `ptr_to_ref` is pure, but has dynamic preconditions.

Dynamic preconditions:

1. `p` MUST be non-null.
2. `p` MUST be aligned for `T`.
3. `p` MUST point into a live allocation for the entire lifetime of `%r`.
4. Any aliasing constraints implied by `kind` MUST hold.

If the implementation cannot prove these preconditions from validated semantics, it MUST NOT generate `ptr_to_ref` and MUST instead operate on `ptr<T>`.

### 3.20.7 Call instructions

#### 3.20.7.1 `call`

Form:

1. `%out = call callee, cc, (arg0, arg1, ...)`

Typing:

1. `callee` MUST have a function type `fn(A0, A1, ...) -> R`.
2. Each argument MUST have the corresponding parameter type.
3. `%out` has type `R` (or is omitted if `R` is `unit`).

Semantics:

1. `call` is effectful.
2. Unless proven otherwise by a rule in this specification, calls MUST be treated as potentially reading and writing memory.
3. Calls across an ABI boundary MUST respect the ABI boundary rules in Section 3.10.

### 3.20.8 Ownership instructions

#### 3.20.8.1 `move`

Form:

1. `%y = move %x`

Typing:

1. `%x` and `%y` have the same type `T`.

Semantics:

1. Transfers ownership responsibility from `%x` to `%y`.
2. After `move`, any use of `%x` is ill-formed IR.
3. `move` is pure, but imposes verifier-tracked ownership state changes.

#### 3.20.8.2 `borrow`

Form:

1. `%r = borrow %x, kind, region`

Typing:

1. `%x` must designate an addressable storage location (either by `ptr<T>` or by a verifiable owned place model defined by the IR).
2. `%r` has type `ref<T>`.

Semantics:

1. Produces a reference valid for `region`.
2. `borrow` is pure, but introduces verifier obligations about aliasing and lifetime.

#### 3.20.8.3 `drop`

Form:

1. `drop %x`

Typing:

1. `%x` has type `T`.

Semantics:

1. Defined by Section 3.17.
2. `drop` is effectful.

### 3.20.9 Result/maybe helper instructions

To make `maybe` explicit, canonical IR provides helper operations. Implementations MAY encode these as intrinsics or as normal instructions; in either case their semantics are as defined here.

#### 3.20.9.1 `make_ok` / `make_err`

1. `make_ok Ok, Err, value: Ok -> result<Ok, Err>` is pure.
2. `make_err Ok, Err, value: Err -> result<Ok, Err>` is pure.

#### 3.20.9.2 `is_ok`

1. `is_ok r: result<Ok, Err> -> bool` is pure.

#### 3.20.9.3 `unwrap_ok` / `unwrap_err`

1. `unwrap_ok r -> Ok` is pure with dynamic precondition `r` is `ok`.
2. `unwrap_err r -> Err` is pure with dynamic precondition `r` is `err`.

If the language requires a defined failure when unwrapping the wrong variant, the IR MUST use `trap` (or an explicit panic call) instead of leaving it undefined.