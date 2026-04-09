# Cloth Language Specification

> Status: Normative release 1.0  > This document defines the complete, enforceable semantics of the Cloth programming language.

---

## Table of Contents

1. Introduction
   1. Goals and Non-Goals
   2. Conformance, Normative Language, and Specification Mechanics
   3. Terminology
   4. Notation, grammar conventions, and examples
   5. Document organization and forward references
   6. Editions, version selection, and stability
2. Lexical Structure
   1. Definitions and observable lexer outputs
   2. Source Text and Normalization
   3. Lexical Grammar and Tokenization
   4. Meta Tokens
   5. Whitespace and Comments
   6. Identifiers
   7. Keywords
   8. Operators and Punctuation
   9. Literals
3. Program Structure
   1. Definitions
   2. Source Files and Compilation Units
   3. Module Declarations and Namespaces
   4. Import System
   5. Top-Level Declarations
   6. File Layout Requirements
   7. Deterministic Compilation Workflow
   8. Required structural diagnostics
4. Type System
   1. Type model and foundational requirements
   2. Classification and Guarantees
   3. Primitive Types
   4. Composite Types
   5. Nullable Types
   6. Modifiers and Ownership Annotations
   7. Type Identity and Equality
   8. Type Inference Rules
   9. Conversion and Casting Semantics
5. Declarations
   1. Declaration model and environments
   2. General declaration grammar
   3. Variable declarations
   4. Constant declarations
   5. Function and method declarations
   6. Receivers and member functions
   7. Type declarations (overview)
   8. Required declaration diagnostics
   9. Traits (attached declaration metadata)
6. Scope and Accessibility
   1. Scope objects, environments, and terminology
   2. Scope Model
   3. Name Resolution
   4. Shadowing
   5. Visibility and Accessibility
   6. Required scope and accessibility diagnostics
7. Expressions
   1. Expression model and evaluation obligations
   2. Categories
   3. Operator Precedence and Associativity
   4. Assignment
   5. Comparison
   6. Logical Expressions
   7. Bitwise Expressions
   8. Arithmetic Expressions
   9. Null-Coalescing
   10. Ternary Operator
   11. Lambda Expressions
   12. Cast Expressions
   13. Call Expressions
   14. Member Access
   15. Evaluation Order and Side Effects
8. Statements
   1. Statement execution model
   2. Categories
   3. Declaration Statements
   4. Assignment Statements
   5. Expression Statements
   6. Control Flow
   7. Block Statements
   8. Exception Handling
   9. Call Statements
   10. Required statement diagnostics
9. Type Definitions and Behavior
   1. Common requirements for nominal types
   2. Classes
   3. Structs
   4. Enums
   5. Interfaces
   6. Members
   7. Member Lookup and Resolution
   8. Shadowing and Overriding
   9. Initialization Order
   10. Construction Model
   11. Meta Accessors (Objects and Primitives)
   12. Examples
   13. Required type-system diagnostics (Section 9)
10. Functions and Methods
    1. Declaration Grammar
    2. Signatures and Identity
    3. Parameters and Ownership
    4. Evaluation Order and Bodies
    5. Return Semantics
    6. Maybe Clauses and Error Flow
    7. Overloading and Resolution
    8. Invocation Semantics
    9. Methods and Receivers
    10. Recursion, Generics, and Async Execution
11. Ownership & Lifetime Reference
    1. Scope and Authority
    2. Lifetime Domains
    3. Relationship Markers
    4. Ownership Tree
    5. Transfers and Moves
    6. Borrowing Rules
    7. Shared Handles
    8. Static Domain
    9. Scope Integration
    10. Diagnostics and Undefined Behavior
12. Program Execution Model
    1. Objectives and Responsibilities
    2. Entrypoint Discovery
    3. Main Class Requirements
    4. Entry Constructors
    5. Initialization Sequence
    6. Runtime Environment
    7. Steady-State Execution
    8. Error Propagation and Process Exit
    9. Shutdown Semantics
    10. Re-entrancy and Embedding
    11. Required execution-model diagnostics
13. Build System
    1. Manifest Placement and Encoding
    2. Required Sections
    3. Optional Core Tables
    4. Dependency Resolution Flow
    5. Reproducibility and Lock Files
    6. Workspaces and Nested Packages
    7. Validation and Diagnostics
    8. Minimal Manifest Example

## 1. Introduction

Cloth is a statically typed, ownership-oriented programming language designed for high-performance systems software and tooling-heavy production environments. This document defines the normative behavior of Cloth language edition **1.0**: it specifies the syntax, static semantics (name binding, type rules, ownership rules), dynamic semantics (evaluation and execution behavior), and the observable requirements imposed on toolchains.

This specification is written so that independent parties can build interoperable compilers, analyzers, formatters, IDE integrations, and runtime libraries that agree on:

1. The accepted surface syntax.
2. The meaning of accepted programs.
3. The required diagnostics and error categories for rejected programs.
4. The set of behaviors that are intentionally unspecified or implementation-defined.

Unless a clause is explicitly labeled as informative, it is normative and enforceable. A conforming implementation MUST implement every normative requirement that applies to its declared conformance profile (Section 1.2.3). A conforming program MUST avoid undefined behavior and MUST satisfy every well-formedness constraint.

This document is intended for three audiences:

1. **Language implementers** building compilers, interpreters, linkers, and runtimes.
2. **Tooling authors** integrating Cloth into editors, debuggers, build systems, profilers, and refactoring engines.
3. **Program authors** writing Cloth code who rely on deterministic, portable semantics.

Whenever this document refers to a companion specification (for example, the **Cloth Ownership & Lifetime Reference**), that companion text is normative within the scope explicitly stated by this document. When multiple normative sources overlap, conflicts are resolved by Section 1.2.6.

### 1.1 Goals and Non-Goals

Cloth exists to provide predictable machine-level behavior while remaining statically analyzable for correctness, resource safety, and tooling automation. The goals below are mandatory design outcomes. A change that violates a goal constitutes a language redesign and requires a new edition.

#### 1.1.1 Goals

1. **Predictable execution and resource lifetimes**
   1. Construction, destruction, and resource finalization MUST be defined by ownership relationships rather than by garbage collection.
   2. Every value with non-static lifetime MUST have an ownership and lifetime provenance that is checkable prior to execution.
   3. The destruction order of owned object graphs MUST be deterministic and MUST be derivable from the ownership tree rooted at the entrypoint `Main` instance (Section 11 and Section 12).

2. **Mechanical transparency and interoperability**
   1. Value layout, alignment, size, and calling semantics MUST be specified sufficiently for ABI-sensitive code and for foreign interfaces.
   2. Meta queries (for example `::SIZEOF`, `::ALIGNOF`, `::TYPEOF`) MUST return results that are consistent with the language’s representation and layout rules.
   3. If the language allows multiple surface spellings for the same canonical construct (for example `int` and `i32`), the semantic result MUST be identical.

3. **Static assurance as a baseline**
   1. Type checking MUST either succeed or fail before program execution begins.
   2. Ownership validation MUST either succeed or fail before program execution begins.
   3. The presence of `maybe`-annotated error flow MUST be checked statically so that unhandled error paths cannot be silently ignored.
   4. Implementations MAY offer additional dynamic checks; however, the acceptance of a program MUST NOT depend on runtime observations.

4. **Tooling determinism and analyzability**
   1. Lexing and parsing MUST be deterministic.
   2. Name binding and overload resolution MUST be deterministic and MUST NOT depend on implementation-specific ordering, hashing, or concurrency.
   3. The manifest model and program structure rules MUST be strict enough that tools can compute module graphs and symbol boundaries without executing user code.

5. **Edition-based evolution**
   1. Language evolution proceeds via numbered editions.
   2. An edition MAY add features, tighten diagnostics, or reserve syntax.
   3. Edition changes MUST be explicitly version-gated via manifest configuration (Section 13) so that the intended semantics are mechanically knowable.

#### 1.1.2 Non-Goals

1. **Standard library definition**
   1. This document does not define the standard library surface area or its versioning policy.
   2. Where the language requires library support (for example runtime entry mechanics), this document specifies the required behavior but not the full API catalog.

2. **Mandating compiler architecture**
   1. This document does not mandate a specific internal representation (AST, IR, bytecode) or compilation pipeline.
   2. Any architecture is permitted as long as externally observable behavior matches this specification.

3. **Dynamic code loading and runtime reflection**
   1. Dynamic module loading, runtime reflection, and just-in-time compilation are not part of edition 1.0.
   2. Programs MUST NOT rely on such facilities. Implementations MAY provide extensions, but such extensions are non-normative and MUST be explicitly marked.

4. **Concurrency semantics guarantees**
   1. Unless a clause explicitly defines concurrent behavior, Cloth edition 1.0 specifies semantics as if execution occurs on a single-threaded abstract machine.
   2. Implementations MAY execute code concurrently as an optimization only when doing so does not change the observable behavior as defined by this specification.

### 1.2 Conformance, Normative Language, and Specification Mechanics

#### 1.2.1 Normative keywords

The keywords **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** are to be interpreted as described in RFC 2119.

In this document:

1. A statement using a normative keyword is a normative requirement.
2. A requirement applies to a subject class, typically one of:
   1. **Implementation** (compiler, linker, analyzer, formatter, runtime).
   2. **Program** (a set of source files and build configuration).
   3. **Program author** (the act of writing a program that is intended to be conforming).
3. The absence of a normative keyword does not imply non-normativity; headings and definitions can be normative when they constrain interpretation.

#### 1.2.2 Well-formed, ill-formed, and diagnosable programs

1. A **well-formed program** is one that satisfies all syntactic and static semantic constraints required by this specification.
2. An **ill-formed program** violates one or more such constraints.
3. For any ill-formed program, a conforming implementation MUST emit at least one diagnostic (Section 1.2.5) and MUST NOT produce a successful build artifact while claiming conformance.
4. Some constraints are stated as **undefined behavior** rather than as ill-formedness constraints; such programs may be accepted but are not conforming programs (Section 1.2.4).

#### 1.2.3 Conformance profiles

Because Cloth tooling can exist in different roles, this document defines conformance in terms of profiles. An implementation claiming conformance MUST declare at least one of the following profiles and MUST satisfy all requirements applicable to that profile.

1. **Compiler conformance**
   1. Accepts and rejects programs per this specification.
   2. Produces artifacts (executables, libraries, object files) whose observable behavior matches the dynamic semantics.

2. **Static analyzer conformance**
   1. Performs lexing/parsing/name binding/type checking/ownership checking consistent with the specification.
   2. Emits diagnostics consistent with the specification.
   3. It MAY omit code generation.

3. **Formatter conformance**
   1. Must preserve program meaning.
   2. Must not introduce ill-formedness.
   3. Must preserve token order and token spelling where meaning would otherwise change (for example in string literals).

4. **Runtime library conformance**
   1. Provides any required runtime services described by this specification.
   2. Must honor ownership, initialization, and shutdown semantics that depend on runtime behavior.

If a requirement is written in terms of “the compiler”, it applies to the compiler conformance profile; if it is written as “implementation”, it applies to all profiles unless the context restricts it.

#### 1.2.4 Undefined behavior, unspecified behavior, and implementation-defined behavior

This specification distinguishes three categories of underspecification.

1. **Undefined behavior (UB)**
   1. For UB, this specification imposes no requirements on behavior.
   2. A conforming program MUST NOT execute a code path that triggers UB.
   3. A conforming implementation MAY diagnose UB, MAY reject UB, or MAY accept UB; however, it is not required to diagnose UB unless explicitly stated.

2. **Unspecified behavior**
   1. For unspecified behavior, this specification allows multiple permitted behaviors.
   2. A conforming implementation MUST choose one of the permitted behaviors.
   3. A conforming program MUST NOT rely on which permitted behavior is chosen unless it has been made implementation-defined.

3. **Implementation-defined behavior**
   1. For implementation-defined behavior, the implementation MUST choose a behavior and MUST document that choice.
   2. Implementations SHOULD make implementation-defined choices visible via machine-readable tooling outputs (for example a `--print-config` facility), but the mechanism is implementation-defined.

Any behavior that is neither explicitly permitted nor explicitly categorized as unspecified or implementation-defined is UB.

#### 1.2.5 Diagnostics

1. A **diagnostic** is any message emitted by an implementation describing an error, warning, note, or informational finding.
2. For any rule that uses the phrase “MUST emit a diagnostic”, the diagnostic MUST:
   1. Identify the source location (file, line, column, and span) of the primary offending construct.
   2. Identify the reason for the diagnostic in text.
   3. Reference the governing clause number(s) from this document.
3. If multiple diagnostics could apply, the implementation MAY emit more than one; however, it MUST emit at least one.
4. Warnings and lints are non-fatal unless a clause explicitly states that they are errors.

#### 1.2.6 Conflict resolution among normative sources

When two normative statements appear to conflict:

1. The more specific rule overrides the more general rule.
2. If neither is more specific, the stricter requirement prevails (the requirement that forbids more programs or permits fewer behaviors).
3. If conflict remains after applying (1) and (2), the implementation MUST emit a diagnostic explaining the conflict and MUST treat the construct as ill-formed.
4. If this document and a companion normative document overlap, this document is authoritative unless it explicitly delegates authority to the companion document for the overlapping subject.

### 1.3 Terminology

The following terms are used with the specified meanings. If a term is capitalized in running text, it refers to the definition in this section unless otherwise stated.

1. **Implementation**
   1. A tool that consumes Cloth source text or intermediate representation to produce diagnostics, artifacts, or both.
   2. Unless stated otherwise, “implementation” refers to an implementation attempting full conformance for at least one conformance profile (Section 1.2.3).

2. **Program**
   1. The transitive closure of modules reachable from the build target’s entry selection (Section 12 and Section 13).
   2. A program includes all source files, generated files, and build configuration inputs that affect semantics.

3. **Compilation unit**
   1. A single physical source file after decoding, normalization, and tokenization.
   2. Compilation units are the atomic input to the parser.

4. **Module**
   1. A namespace introduced by a `module` declaration.
   2. A module is the unit of import, visibility boundary, and symbol partitioning.
   3. Multiple compilation units may contribute to a single logical module as specified in Section 3.

5. **Declaration**
   1. A syntactic construct that introduces a named entity (type, member, variable, parameter, etc.) into some scope.
   2. Declarations are subject to name binding, visibility, and type rules.

6. **Type declaration**
   1. A top-level construct that introduces a nominal type such as `class`, `struct`, `enum`, `interface`, or other forms specified by this document.

7. **Instance**
   1. A runtime value produced by evaluation of a construction operation.
   2. Instances are associated with a lifetime domain and ownership relationships.

8. **Static member**
   1. A member declared with `static`.
   2. Static members belong to the static lifetime domain and have initialization rules defined by this document.

9. **Ownership tree**
   1. The directed hierarchy induced by `owned` relationships.
   2. Destruction is defined as a traversal from leaves to root with deterministic ordering constraints specified in the Ownership & Lifetime rules.

10. **Lifetime domain**
   1. One of `owned`, `shared`, or `static`.
   2. The meaning of each domain, and the permitted transfers between them, are defined by Section 11.

11. **Entrypoint**
   1. The program-defined type chosen to initiate execution.
   2. The entrypoint is responsible for constructing the root `Main` instance and establishing the program’s top-level ownership root.

12. **Manifest**
   1. The `build.toml` file describing package identity, edition selection, dependency graph, source roots, and targets.

13. **Reserved syntax**
   1. Keywords, operators, or grammar productions reserved for future editions.
   2. Implementations MUST reject reserved syntax so that future editions can assign meaning without silently changing existing programs.

14. **Undefined behavior (UB)**
   1. A program property for which this document imposes no requirements on outcome.
   2. UB is never a permitted dependency for conforming programs.

Specialized terms (for example borrow, move, shared handle, `maybe`) are defined in the sections where they become normative.

### 1.4 Notation, grammar conventions, and examples

#### 1.4.1 Grammar form

1. Grammar productions are written in an EBNF-like notation.
2. Terminals are written in single quotes, for example `'module'`.
3. Non-terminals are written as identifiers containing hyphens, for example `module-declaration`.
4. The operator `*` indicates repetition (zero or more), `+` indicates repetition (one or more), and `?` indicates optionality.
5. Parentheses group expressions.
6. When grammar and prose conflict, the prose is authoritative only if it explicitly states that it overrides the grammar; otherwise, the grammar is authoritative.

#### 1.4.2 Code font and naming

1. Inline code formatting (for example `module`, `import`, `Main`) refers to source spelling.
2. Uppercase names preceded by `::` (for example `::SIZEOF`) refer to meta keywords (Section 2.3.2).
3. When multiple spellings map to the same canonical entity (for example `int` and `i32`), the canonical name is used when describing semantics.

#### 1.4.3 Examples

1. Examples are informative unless explicitly stated as normative.
2. Examples may omit imports or surrounding scaffolding for brevity; omitted components are not implied by the language.
3. Implementations MUST NOT treat examples as additional permitted syntax.

### 1.5 Document organization and forward references

1. Section 2 defines lexing rules.
2. Section 3 defines program structure (modules, imports, file layout).
3. Sections 4 through 10 define the type system, declarations, scope, expressions, statements, and type behavior.
4. Section 11 defines ownership and lifetime.
5. Section 12 defines the execution model and entry mechanics.
6. Section 13 defines the build manifest model.

Some rules intentionally refer forward to later sections. Forward references are normative and do not weaken the present rule.

### 1.6 Editions, version selection, and stability

1. The language is versioned by edition. This document specifies edition **1.0**.
2. A build selects an edition via manifest configuration (Section 13). If no edition is specified, the implementation MUST assume edition 1.0.
3. An implementation MAY support multiple editions simultaneously. When it does:
   1. It MUST treat the selected edition as authoritative for parsing and semantics.
   2. It MUST provide a diagnostic when source appears to rely on constructs reserved or changed in another edition.
4. A future edition MAY tighten errors (rejecting programs that earlier editions accepted) only if the program is not conforming under the earlier edition or if the change is explicitly documented as an edition break.

## 2. Lexical Structure

Lexical analysis converts a sequence of bytes (a source file) into a deterministic stream of tokens. The token stream is consumed by the parser; therefore, the lexical rules in this section define the boundary between raw text and syntactic structure.

This stage is purely syntactic:

1. Lexing MUST NOT perform name lookup, type checking, ownership analysis, or semantic evaluation.
2. Lexing MUST NOT depend on project configuration, imports, or module graphs.
3. Lexing MUST be deterministic: identical bytes (after the normalization steps required by this section) MUST produce identical token sequences.

Every clause in Section 2 applies uniformly to all Cloth source locations, including module headers, declarations, expressions, attributes, and directive-like syntax. If a later section introduces a construct that requires a new token kind, that token kind MUST be lexed according to the principles in this section.

### 2.0 Definitions and observable lexer outputs

#### 2.0.1 Code points, scalars, and bytes

1. Source files are sequences of bytes.
2. Decoding produces a sequence of Unicode scalar values.
3. A **Unicode scalar value** is any Unicode code point except surrogate code points U+D800 through U+DFFF.
4. Where this document uses “code point” in lexical contexts, it refers to a Unicode scalar value unless stated otherwise.

#### 2.0.2 Positions and spans

Every token and every diagnostic location is expressed using positions and spans.

1. A **byte offset** is a non-negative integer index into the UTF-8 byte sequence of a single physical file.
2. A **position** is the tuple `(byte_offset, line, column)`.
3. A **span** is the pair `(start_position, end_position)` where:
   1. `start_position` is inclusive.
   2. `end_position` is exclusive.
   3. Both positions are in the same physical file.
4. Line and column numbers are 1-based.
5. Line and column counts are tracked in terms of decoded scalar values after line terminator normalization (Section 2.1.2).
6. Tokens MUST record, at minimum:
   1. Token kind.
   2. Lexeme (the exact source spelling, as bytes or as a lossless string view).
   3. Span.

Tooling MAY record additional metadata (for example preceding trivia or whitespace ranges), but such metadata MUST NOT change token boundaries.

### 2.1 Source Text and Normalization

#### 2.1.1 Encoding

1. Source files MUST be encoded as UTF-8 without a byte-order mark (BOM).
2. Implementations MAY accept BOM-prefixed files by discarding the BOM prior to lexing, but they MUST NOT emit different token streams solely because a BOM was present.
3. Any byte sequence that is not well-formed UTF-8 is ill-formed source text. Compilers MUST emit a diagnostic and MUST NOT recover by inserting replacement characters.
4. Tooling that manipulates Cloth code in other encodings (for example UTF-16 editors) MUST transcode to UTF-8 before invoking a compiler, formatter, or analyzer.

#### 2.1.1.1 Ill-formed decoding diagnostics

1. If decoding fails, the implementation MUST emit a diagnostic that includes:
   1. The file path.
   2. The byte offset where decoding first fails.
   3. The reason (for example, invalid continuation byte).
2. After a decoding failure, the implementation MUST NOT continue lexing that file as if it had decoded successfully.

#### 2.1.2 Line Terminators

1. The recognized line terminators are LF (U+000A), CR (U+000D), and the two-character sequence CR LF.
2. During normalization, every CR LF pair MUST be converted to a single LF.
3. A lone CR MUST be treated as a line terminator and MUST be normalized as if it were LF.
4. Other Unicode separators (U+2028, U+2029, etc.) are illegal outside string and character literals. Encountering one MUST produce a diagnostic that cites the offending code point.
5. Logical line numbers increment immediately after each normalized LF. Columns reset to 1 after the increment.

#### 2.1.2.1 Column counting requirements

1. Columns count scalar values, not display cells.
2. A horizontal tab (U+0009) counts as exactly one column for the purpose of positions.
3. Implementations MAY render tabs at any visual width in user interfaces, but diagnostics MUST be stable and consistent with the position model.

#### 2.1.3 Control Characters and Layout

1. Outside string and character literals, the only permitted control characters are horizontal tab (U+0009), carriage return, line feed, and space (U+0020).
2. Vertical tab, form feed, NUL, and any other C0 control MUST trigger diagnostics identifying the code point and its location.
3. Implementations MUST NOT treat non-breaking space, zero-width joiner, or other formatting characters as whitespace unless explicitly listed above.
4. Implementations MUST treat any Unicode scalar value with general category `Cf` (format characters) as illegal outside string and character literals unless a later edition explicitly permits it.
5. Implementations MUST treat U+FEFF (ZERO WIDTH NO-BREAK SPACE) as illegal if it appears in source text after the initial BOM handling.

#### 2.1.4 File Boundaries

1. Each physical file constitutes an independent tokenization unit. After consuming the last code point, the lexer MUST append an EndOfFile meta token whose span starts and ends at the logical end position.
2. Tooling that synthesizes buffers (IDEs, REPLs, notebooks) MUST enforce the same decoding, normalization, and EndOfFile semantics as disk-backed files.
3. Concatenation options (for example `compiler -cat a.co b.co`) operate on bytes before normalization. No extra newline is inserted between files unless one already exists.

#### 2.1.5 Input stability and hashing

1. A conforming implementation MUST define token boundaries based solely on the normalized decoded scalar sequence.
2. Any hashing, incremental lexing, or caching scheme MUST NOT change the produced token stream.
3. If an implementation performs incremental lexing, it MUST behave as though it had lexed the full file from the beginning.

### 2.2 Lexical Grammar and Tokenization

#### 2.2.1 Token categories

The canonical token categories are:

1. Identifier
2. Keyword
3. Literal
4. Operator/Punctuation
5. Meta

#### 2.2.2 Determinism and maximal munch

1. Lexing is deterministic. Feeding identical normalized text to a conforming lexer MUST produce the same ordered token sequence.
2. The lexer uses maximal munch:
   1. At each input position it MUST select the longest prefix that matches any token production.
   2. If no token production matches, the lexer MUST emit an illegal-character diagnostic and MUST advance by at least one scalar value to avoid infinite loops.
3. When two different token productions match the same-length prefix, tie-breaking MUST be performed by the following precedence order:
   1. Keyword
   2. Identifier
   3. Literal
   4. Operator/Punctuation
   5. Meta

The precedence order above is chosen to ensure that reserved words are never silently interpreted as identifiers.

#### 2.2.3 Token metadata

Tokens MUST carry the following metadata:

1. Start byte offset (inclusive).
2. End byte offset (exclusive).
3. Start line and column.
4. End line and column.
5. The lexeme.

Implementations MUST expose this metadata to diagnostic subsystems.

#### 2.2.4 Lexing algorithm requirements

Implementations MAY structure their lexer using any internal approach. The externally observable behavior MUST be equivalent to the following abstract algorithm:

1. Normalize the input file per Section 2.1.
2. Initialize position to the start of the file.
3. While not at end-of-file:
   1. If the current character begins whitespace, consume a maximal contiguous whitespace sequence and continue.
   2. Else if the current character begins a comment, consume the maximal comment per Section 2.4 and continue.
   3. Else attempt to match a token production at the current position, choosing the maximal munch match and applying tie-break rules.
   4. If a token is matched, emit it and advance by its length.
   5. If no token matches, emit a diagnostic and advance.
4. Emit the EndOfFile meta token.

#### 2.2.5 ASCII terminals used in grammars

Unless specified otherwise, grammars in this section use:

1. `letter = [A-Z] | [a-z]`
2. `digit = [0-9]`
3. `underscore = '_'`

The grammars in Section 2 intentionally restrict many constructs to ASCII even though source text as a whole is Unicode.

#### 2.2.6 Lexical errors

Lexical errors include, but are not limited to:

1. Illegal code points outside string/character literals.
2. Unterminated block comments.
3. Unterminated string or character literals.
4. Invalid escape sequences where the edition defines them as invalid.
5. Digits outside the radix of a numeric literal.

When a lexical error occurs:

1. The implementation MUST emit a diagnostic.
2. The implementation SHOULD continue lexing to find additional errors, provided it can do so without producing a token stream that contradicts the text.

### 2.3 Meta Tokens

Meta tokens are synthesized by the lexer to communicate structure, end-of-input, or recovery information to later compilation stages. Meta tokens never appear directly in user-written source.

If an implementation introduces additional meta tokens beyond those in this specification, it MUST ensure:

1. Such tokens are not required for program meaning.
2. Such tokens do not escape diagnostic or recovery contexts.
3. Such tokens do not affect acceptance/rejection of programs except by enabling better error messages.

#### 2.3.1 Sentinel Tokens

- EndOfFile MUST be emitted exactly once per tokenization unit after the final real token. Its lexeme is the empty string and its span coincides with the logical end position.
- Implementations MAY introduce additional recovery tokens (for example InsertedSemicolon). Any such token MUST be documented and MUST NOT leak beyond diagnostic contexts.

#### 2.3.2 Meta Keywords

Certain uppercase identifiers become meta tokens when preceded immediately by `::` (the meta introducer). The lexer MUST emit a Meta token whose lexeme is the uppercase keyword instead of a normal identifier or keyword token. The recognized meta keywords are:

| Lexeme      | Semantics                                        |
|-------------|--------------------------------------------------|
| ALIGNOF     | Query the alignment of a type or expression.     |
| DEFAULT     | Produce the default value of a type.             |
| LENGTH      | Query the length of an aggregate.                |
| MAX         | Maximum representable value of the operand type. |
| MEMSPACE    | Name an implementation-defined memory space.     |
| MIN         | Minimum representable value of the operand type. |
| SIZEOF      | Size in bytes of a type or expression.           |
| TO_BITS     | Convert a value to its raw bit pattern.          |
| TO_BYTES    | Convert a value to a byte sequence.              |
| TO_STRING   | Convert a value to a textual representation.     |
| TYPEOF      | Reflect the static type of an expression.        |

Recognition is case-sensitive. `alignof` or `AlignOf` remain ordinary identifiers. If the uppercase identifier is not immediately preceded by `::`, it behaves as a reserved keyword and cannot be used as an identifier.

The tokenization of `::` and the subsequent uppercase lexeme MUST be as follows:

1. The lexer emits an `OP_ColonColon` token for `::`.
2. If and only if the next token would lex as an identifier consisting entirely of ASCII uppercase letters and underscores, and the lexeme matches one of the recognized meta keywords, the lexer emits a Meta token for that lexeme.
3. Otherwise, the lexer emits the ordinary token kind for the subsequent characters (typically an Identifier) and the meaning is determined by later sections.

The restriction above prevents accidental capture of general identifiers as meta keywords.

### 2.4 Whitespace and Comments

#### 2.4.1 Whitespace

1. Whitespace consists of the characters listed in Section 2.1.3.
2. The lexer MUST treat any non-empty sequence of whitespace as a separator between tokens.
3. The lexer MUST NOT emit whitespace tokens.
4. Whitespace MAY appear between any two tokens unless a later section explicitly requires adjacency.

#### 2.4.2 Comments

Comments are not tokens. Comment text does not contribute to program meaning.

1. Line comments begin with `//` and extend to, but do not include, the next normalized LF or the end of the file.
2. Block comments begin with `/*` and terminate at the next `*/`.
3. Block comments MUST NOT nest.
4. If end-of-file occurs before a terminating `*/`, the lexer MUST emit an unterminated-comment diagnostic whose span begins at the `/*` and ends at EndOfFile.
5. Characters inside comments are ignored for syntactic purposes but MUST update line/column counters.

#### 2.4.3 Comment and token boundary interactions

1. Comments act as separators exactly like whitespace.
2. The sequence `//` begins a line comment even if it appears immediately after another token with no intervening whitespace.
3. The sequence `/*` begins a block comment even if it appears immediately after another token with no intervening whitespace.
4. Implementations MUST ensure that removing comments from a source file cannot create new tokens that were not already present as adjacent tokens separated by a boundary.

#### 2.4.4 Reserved documentation comments

Specialized documentation comment forms are reserved for future editions. Until standardized:

1. `///` behaves exactly like `//`.
2. `/**` behaves exactly like `/*`.

### 2.5 Identifiers

Identifiers name user-defined entities and follow this grammar:

```
identifier ::= identifier-start identifier-part*
identifier-start ::= letter | '_'
identifier-part ::= identifier-start | digit | '$'
```

1. Identifiers are case-sensitive. `Renderer` and `renderer` name distinct entities.
2. The dollar sign MAY appear only after the first character. Its primary purpose is to facilitate generated symbol names (for example `Type_meta`). Hand-authored code SHOULD avoid `$` unless interoperating with generated artifacts.
3. The single underscore `_` is a valid identifier and typically denotes an intentionally unused binding.
4. Keywords (Section 2.6) and meta keywords (Section 2.3.2) MUST NOT be used as identifiers.
5. Cloth presently restricts identifiers to ASCII; non-ASCII letters, combining marks, and escape sequences are illegal and MUST trigger diagnostics.

Additional identifier requirements:

1. An identifier MUST NOT contain whitespace.
2. An identifier MUST NOT contain comment introducers as a substring in a way that would alter tokenization; this is already enforced by maximal munch and the token grammar.
3. Implementations MUST accept identifiers up to at least 256 characters; longer identifiers MAY be rejected with a diagnostic. If rejected, the diagnostic MUST cite the identifier’s length.
4. Identifiers that begin with `_` are not semantically special in edition 1.0, except where a later section explicitly assigns meaning (for example placeholder binders).

### 2.6 Keywords

Keywords are reserved lexemes that always produce dedicated token kinds. Attempting to use a keyword where an identifier is expected is a compile-time error. Cloth keywords are case-sensitive.

| Category                 | Lexemes |
|--------------------------|---------|
| Boolean & Nullity        | `true`, `false`, `null`, `NaN` |
| Control Flow             | `if`, `else`, `switch`, `case`, `default`, `for`, `while`, `do`, `break`, `continue`, `yield`, `return`, `throw`, `try`, `catch`, `finally`, `defer`, `await` |
| Expression Keywords      | `and`, `or`, `is`, `in`, `as`, `maybe` |
| Modifiers & Ownership    | `public`, `private`, `internal`, `static`, `shared`, `owned`, `const`, `var`, `get`, `set`, `async`, `atomic` |
| Type & Declaration Forms | `module`, `import`, `class`, `struct`, `enum`, `interface`, `trait`, `type`, `func`, `new`, `delete`, `this`, `super`, `bit`, `bool`, `char`, `byte`, `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `float`, `double`, `real`, `long`, `short`, `int`, `uint`, `unsigned`, `void`, `any`, `string` |
| Traits / Directives      | `Override`, `Implementation`, `Prototype`, `Deprecated` |

Synonyms such as `int`/`i32`, `long`/`i64`, and `real`/`f64` map to the same primitive types; implementations MUST treat these lexemes identically during semantic analysis.

#### 2.6.1 Reserved (future) keywords

1. Any uppercase identifier listed in Section 2.3.2 is reserved even when not preceded by `::`.
2. If a future edition reserves additional keywords, the compiler MUST reject them when compiling under that future edition, and SHOULD provide a migration diagnostic when compiling older code under a newer edition.

### 2.7 Operators and Punctuation

The following symbol sequences form individual tokens. Lexers MUST apply longest-match semantics so that, for example, encountering `...` yields `OP_DotDotDot` instead of three consecutive `OP_Dot` tokens.

Unless explicitly stated otherwise:

1. Operators are ASCII-only.
2. Operators are not identifiers.
3. An operator token is determined solely by its lexeme, independent of surrounding whitespace.

| Lexeme | Token name | Description |
|--------|------------|-------------|
| `...` | `OP_DotDotDot` | Variadic placeholder / spread operator. |
| `..` | `OP_DotDot` | Range operator. |
| `::` | `OP_ColonColon` | Qualified name separator / meta operator. |
| `:>` | `OP_ReturnArrow` | Function return-type introducer. |
| `->` | `OP_Arrow` | Lambda arrow / flow indicator. |
| `??` | `OP_Fallback` | Null-coalescing operator. |
| `++`, `--` | `OP_PlusPlus`, `OP_MinusMinus` | Increment / decrement. |
| `=` | `OP_Equal` | Assignment operator. |
| `+=`, `-=`, `*=`, `/=`, `%=` | Compound assignments | Arithmetic compound assignment operators. |
| `&=`, `|=`, `^=` | Compound assignments | Bitwise compound assignment operators. |
| `==`, `!=`, `<`, `>`, `<=`, `>=` | Comparison operators | Comparison operators. |
| `+`, `-`, `*`, `/`, `%` | Arithmetic operators | Arithmetic operators. |
| `&`, `|`, `^`, `~` | Bitwise operators | Bitwise operators. |
| `!` | `OP_Not` | Logical negation. |
| `.` | `OP_Dot` | Member access. |
| `,` | `OP_Comma` | List separator. |
| `;` | `OP_Semicolon` | Statement terminator. |
| `:` | `OP_Colon` | Label / clause separator. |
| `(` `)` | Parentheses | Expression grouping / parameter lists. |
| `{` `}` | Braces | Blocks / type bodies. |
| `[` `]` | Brackets | Indexing / array literals. |
| `@` | `OP_At` | Attribute introducer. |
| `#` | `OP_Hash` | Trait introducer. |
| `$` | `OP_Dollar` | Reserved for future meta constructs. |
| `?` | `OP_Question` | Ternary introducer / placeholder. |
| `` ` `` | `OP_Backtick` | Template or meta binding introducer (reserved). |

Any character not listed here and not part of another token category is illegal outside string or character literals and MUST raise a diagnostic.

#### 2.7.1 Reserved operator sequences

1. Operator sequences referenced by later sections but not listed in the table above are reserved and MUST be rejected during lexing or parsing with a diagnostic.
2. If a lexeme is both a prefix of a listed operator and a valid operator by itself, maximal munch applies.

### 2.8 Literals

Literals produce constant values that participate directly in expressions. The grammar below uses `digits = digit+` unless stated otherwise.

Unless a literal’s semantics state otherwise:

1. Literal tokenization MUST be independent of expected type at the parse site.
2. Range checking and overflow checking occur during semantic analysis.
3. Lexical forms that cannot be tokenized unambiguously MUST be rejected by the lexer.

#### 2.8.1 Integer Literals

```
integer-literal ::= radix-prefix? digits type-suffix?
radix-prefix ::= '0b' | '0B' | '0o' | '0O' | '0d' | '0D' | '0x' | '0X'
type-suffix ::= 'b' | 'B' | 'i' | 'I' | 'l' | 'L' | 'u' | 'U'
```

1. The default radix is decimal. Prefixes select binary (`0b`), octal (`0o`), decimal (`0d`), or hexadecimal (`0x`).
2. Digits MUST belong to the chosen radix; invalid digits require a diagnostic.
3. Digit separators are not permitted.
4. Suffix semantics:
   - `b`/`B` - canonical type `byte` (value MUST be within `[0, 255]`).
   - `i`/`I` - canonical type `int` (default when omitted).
   - `l`/`L` - canonical type `long`.
   - `u`/`U` - canonical type `uint`.
5. The lexer SHOULD evaluate the literal to a canonical integer value. Overflow is detected during semantic analysis; if the literal cannot fit in any target type, the compiler MUST emit a diagnostic.

Additional lexical constraints:

1. A radix prefix MUST be immediately followed by at least one digit.
2. A suffix, if present, MUST immediately follow the digit sequence.
3. A leading sign (`+` or `-`) is not part of the integer literal token; it is lexed as an operator and interpreted by the parser as unary sign.

#### 2.8.2 Floating-Point Literals

```
float-literal ::= digits? '.' digits? exponent-part? float-suffix?
exponent-part ::= ('e' | 'E') ('+' | '-')? digits
float-suffix ::= 'f' | 'F' | 'd' | 'D'
```

1. At least one side of the decimal point MUST contain digits. A bare `.` token is parsed as `OP_Dot`.
2. The optional exponent part follows IEEE-754 notation.
3. Suffix semantics: `f`/`F` -> `float` (`f32`), `d`/`D` -> `double` (`f64`, default).
4. The literal value is parsed as an IEEE double. If the runtime cannot represent the lexeme, the compiler MUST reject it.

Additional lexical constraints:

1. A leading sign (`+` or `-`) is not part of the floating literal token.
2. The exponent-part, if present, MUST include at least one digit.
3. If a suffix is present, it MUST be the final character of the literal token.
4. Implementations MUST reject `NaN` spellings other than the keyword `NaN`.

#### 2.8.3 Byte Literals

- Byte literals are integer literals with suffix `b` or `B`. Regardless of radix, the numeric value MUST fit in `[0, 255]`.
- The canonical type is `byte` (`u8`). Assigning a byte literal to a wider integer implicitly zero-extends it; assigning to a narrower type requires an explicit cast.

#### 2.8.4 Bit Literals

```
bit-literal ::= ('0' | '1') ('t' | 'T')
```

Bit literals represent the single-bit type `bit`. They convert losslessly to `bool`, `byte`, or larger integers, but converting from wider types to `bit` requires explicit casts defined in Section 7.

Additional lexical constraints:

1. The `t` or `T` suffix is part of the literal token.
2. No radix prefix is permitted for bit literals.

#### 2.8.5 Character Literals

1. Character literals are enclosed in single quotes (`'A'`).
2. Exactly one Unicode scalar value MUST appear between the quotes, either directly or via an escape sequence.
3. Unescaped line terminators are illegal inside a character literal.
4. Supported escapes are:
   1. `\n` (LF)
   2. `\r` (CR)
   3. `\t` (TAB)
   4. `\"` (double quote)
   5. `\\` (backslash)
   6. `\'` (single quote)
5. Hex and Unicode escapes are reserved in edition 1.0 unless the implementation explicitly documents support; if supported, the implementation MUST apply the same rules across all platforms.
6. Surrogate code points are illegal.
7. The canonical type is `char`. Character literals promote to integers by zero-extension of the scalar’s code point.

#### 2.8.6 String Literals

1. String literals are enclosed in double quotes (`"..."`). The closing quote MUST appear on the same logical line unless escaped. Encountering a newline before the closing quote requires an "unterminated string literal" diagnostic.
2. Escape sequences match those available to character literals. Unknown escapes insert the escaped character literally but SHOULD trigger a warning so that future editions can extend the escape set without silently changing semantics.
3. Strings may contain any Unicode scalar value except the forbidden control characters listed in Section 2.1.3. Implementations MUST preserve the original spans so diagnostics inside strings can reference the correct characters.
4. String literals evaluate to the immutable `string` type. Storage is owned by the declaring module unless explicitly copied.

Additional lexical constraints:

1. A backslash preceding a line terminator within a string literal denotes an escaped line terminator only if a later edition defines it; edition 1.0 does not define multi-line string literals.
2. The sequence `\0` is not a special escape in edition 1.0; it is treated as an unknown escape (subject to warnings).

#### 2.8.7 Boolean, Null, and Special Literals

- `true` and `false` produce keyword tokens representing the `bool` values.
- `null` denotes the absence of an object reference. Nullable semantics are governed by Section 4.4.
- `NaN` represents the IEEE Not-a-Number value of type `f64`.

#### 2.8.8 Future Literal Forms

Byte-array literals, template strings, numeric separators, and additional escape forms are intentionally unspecified. Until a future edition standardizes them, any attempted use MUST produce a diagnostic so that programs do not depend on undefined behavior.


## 3. Program Structure

This section defines the static, deterministic structure of Cloth programs: how physical source files form compilation units; how compilation units form modules; how modules form a program; and how imports specify compile-time dependencies.

The rules in Section 3 are intentionally strict. They exist so that:

1. A build system can compute dependency graphs without executing user code.
2. IDE tooling can map paths to symbols deterministically.
3. Independent implementations can agree on what constitutes “the program” and can diagnose structural errors consistently.

Unless explicitly stated otherwise, all rules in Section 3 are enforced before type checking and ownership analysis.

### 3.0 Definitions

The following terms are used throughout this section.

1. **Source file**: a physical file containing Cloth source text.
2. **Compilation unit**: the result of lexing and parsing a single source file (Section 2).
3. **Logical module**: the global namespace introduced by a specific module path.
4. **Module segment**: one identifier component of a module path.
5. **Module graph**: a directed graph whose vertices are logical modules and whose edges are import dependencies.
6. **Target**: a build output configuration selected by the manifest (Section 13).
7. **Entry module**: the module containing the entrypoint type selected by the target (Section 12).

If a term is defined here and later redefined elsewhere, the more specific definition applies in that context.

### 3.1 Source Files and Compilation Units

#### 3.1.1 File selection

1. Every physical source file selected by the manifest’s source selection rules (Section 13) is an input to the build.
2. Generated source files and hand-written source files are subject to identical rules.
3. A build MUST define a finite set of source files. If file selection is dynamic (for example, depends on globbing), the resulting set MUST be resolved prior to lexing.
4. If a selected source file cannot be read, decoded, or normalized according to Section 2, the implementation MUST emit a diagnostic and MUST treat the build as failed.

#### 3.1.2 Compilation unit grammar

Each compilation unit MUST conform to the following high-level grammar:

```
compilation-unit   ::= file-header? module-declaration import-section? top-level-type-declaration EndOfFile
file-header        ::= (line-comment | block-comment)*
import-section     ::= import-directive*
```

Additional constraints:

1. The `module` declaration MUST be the first non-comment token.
2. Shebang-like lines and license headers are permitted only if they are expressed as comments.
3. A compilation unit MUST contain exactly one `module` declaration.
4. A compilation unit MUST contain exactly one top-level type declaration (Section 3.4).
5. Imports MUST appear as a contiguous block immediately after the module declaration (Section 3.3).

#### 3.1.3 Deterministic file ordering

When a build includes multiple files, the implementation MUST process them in a deterministic order at all externally observable boundaries (diagnostics, generated artifact naming, and stable symbol enumeration). Unless a later section specifies a different order, the canonical order is:

1. Lexicographic order by normalized absolute file path.
2. Within a file, by increasing source span.

If an implementation uses parallelism, it MUST still behave as though it followed the canonical order whenever the order is observable.

### 3.2 Module Declarations and Namespaces

#### 3.2.1 Syntax and Semantics

```
module-declaration ::= 'module' module-path ';'
module-path        ::= identifier ('.' identifier)*
```

Semantic requirements:

1. Module segments obey the identifier grammar in Section 2.5.
2. Keywords and meta keywords MUST NOT appear as module segments.
3. Empty segments are illegal.
4. Module names are case-sensitive.
5. A module path identifies a logical module. All compilation units declaring the same module path are members of the same logical module.

#### 3.2.2 Module membership and namespace merging

Before semantic analysis, a conforming implementation MUST construct logical modules and merge their declarations.

1. The module graph is discovered from the set of compilation units selected by the build.
2. For each distinct module path, the implementation creates exactly one logical module.
3. The implementation then adds each compilation unit’s top-level type declaration into that module’s namespace.
4. If two compilation units in the same logical module introduce top-level types with the same name, the program is ill-formed and the implementation MUST emit a duplicate-type diagnostic.
5. If a future edition introduces partial types, it MUST do so explicitly. Edition 1.0 does not define partial type merging.

Namespace stability requirements:

1. The merged set of declarations in a module MUST be independent of file processing order.
2. If the implementation offers incremental or cached builds, the merged module namespace MUST be equivalent to a clean build.

#### 3.2.2 Directory Conventions

1. Source layout SHOULD mirror module hierarchies (e.g., `cloth/net/http/Main.co` contains `module cloth.net.http;`).
2. This convention is not required for semantic correctness.
3. Tooling MAY assume this convention for navigation, but compilers MUST NOT assign meaning based solely on directory structure.
4. Sharing a prefix with another module does not imply visibility. Visibility is governed only by modifiers and import forms.

#### 3.2.3 Reserved Prefixes

- `cloth.*`, `compiler.*`, and `std.*` are reserved for the official distribution, compiler tooling, and the standard library. User code MUST NOT declare these modules unless the manifest explicitly authorizes it.
- Vendors MAY document additional reserved prefixes. When a project attempts to claim such a prefix, the compiler MUST issue a diagnostic referencing the reservation.

Implementations MUST treat reserved-prefix violations as errors.

### 3.3 Import System

Imports describe compile-time dependencies. They never imply runtime dynamic loading.

#### 3.3.1 Syntax

```
import-directive ::= 'import' module-path ('.' identifier)* ('::{' import-list '}')? ';'
import-list      ::= import-entry (',' import-entry)*
import-entry     ::= identifier ('as' identifier)?
```

Syntactic constraints:

1. The import-section MUST appear immediately after the module declaration.
2. Imports appearing after any top-level declaration are ill-formed.
3. The `::` introducer is mandatory for selective imports.
4. The optional `('.' identifier)*` suffix after `module-path` denotes selecting a submodule path; it does not select a symbol.
5. Renaming identifiers introduced by `as` MUST satisfy the identifier grammar.

#### 3.3.2 Import forms

Cloth defines two import forms.

1. **Module import**
   1. Syntax: `import A.B.C;`
   2. Effect: binds the imported module path for qualified access.
   3. Qualified access uses `.` syntax as defined by the expression grammar (for example `A.B.C.symbol`).

2. **Selective import**
   1. Syntax: `import A.B.C::{x, y as z};`
   2. Effect: binds specific exported symbols from module `A.B.C` into the importing module’s scope.
   3. Each entry binds either the same name (`x`) or the alias name (`z`).

Wildcard imports are intentionally unsupported in edition 1.0.

#### 3.3.3 Import resolution model

Import resolution is a structural operation that produces an import environment for each compilation unit. It MUST be performed before type checking.

Resolution occurs in two phases:

1. **Module graph resolution**: resolve each referenced module path to a logical module.
2. **Symbol import resolution**: for selective imports, resolve imported symbol names against the exports of the resolved module.

#### 3.3.4 Module graph resolution

For each import directive in a compilation unit, the implementation MUST resolve the referenced module path.

1. If the referenced module path does not exist in the build’s module set, the implementation MUST emit an error at the import site.
2. If the referenced module exists but is not part of the selected build target (for example excluded by target selection), the implementation MUST emit an error that indicates the target mismatch.
3. Module existence is determined by the set of compilation units selected for the build; directory structure alone MUST NOT create modules.

#### 3.3.5 Export sets and visibility interaction

Each logical module has an **export set** consisting of all declarations that are visible outside that module.

1. The export set is defined by visibility modifiers (Section 6).
2. For the purpose of Section 3, the implementation MUST treat a symbol as importable if and only if it is present in the export set.

If a selective import references a non-exported symbol, the implementation MUST emit an error at the import site.

#### 3.3.6 Selective import symbol resolution

For each selective import entry `name` (or `name as alias`), the implementation MUST:

1. Resolve the module path (Section 3.3.4).
2. Look up `name` in the target module’s export set.
3. If no export matches, emit a missing-symbol diagnostic.
4. If the export exists but is not sufficiently visible, emit an accessibility diagnostic.
5. If the entry introduces `alias`, bind `alias` in the importing compilation unit’s import environment.
6. Otherwise bind `name`.

#### 3.3.7 Determinism, conflicts, and ambiguity

Imports must produce a deterministic environment.

1. Reordering import directives MUST NOT change the set of bound imported names, except that it MAY change diagnostic ordering when multiple independent errors exist.
2. Selective imports MUST NOT shadow local declarations.
   1. If an imported name would conflict with a local declaration name in the same scope, the implementation MUST emit a conflict diagnostic and MUST require qualified access.
3. Duplicate selective entries are illegal.
   1. Duplicates include:
      1. Importing the same symbol twice into the same name.
      2. Importing the same symbol twice into two different names.
   2. The implementation MUST emit a duplicate-import diagnostic.
4. If two distinct imports introduce the same name (for example `import A::{x}; import B::{x};`), the program is ill-formed unless a later section defines disambiguation rules. The implementation MUST emit an ambiguous-import diagnostic.

#### 3.3.8 Cycles

Import cycles are permitted only when they do not prevent the construction of module namespaces and import environments.

1. The implementation MUST construct the module graph and detect strongly connected components.
2. A cycle is permitted if and only if, for every module in the cycle, all imported module paths can be resolved and no selective import requires a symbol that is not yet present in the export set.
3. If cycle resolution fails, the implementation MUST reject the program and MUST include the cycle path in the diagnostic.

### 3.4 Top-Level Declarations

#### 3.4.1 Permitted top-level constructs

Only the following constructs may appear at the top level of a compilation unit:

1. The `module` declaration.
2. Zero or more `import` directives in the import-section.
3. Exactly one top-level type declaration:
   1. `class`
   2. `struct`
   3. `enum`
   4. `interface`
   5. `type` alias
4. Zero or more trait declarations (`trait`) as specified by Section 5.8.11.

No other top-level constructs are permitted in edition 1.0.

#### 3.4.2 The single-top-level-type rule

1. Each physical file MUST contain exactly one top-level type declaration.
2. If a file contains zero top-level type declarations, the program is ill-formed.
3. If a file contains more than one top-level type declaration, the program is ill-formed.
4. Nested types are permitted only within type bodies, and they are not counted as top-level type declarations.

Trait declarations are not type declarations and do not contribute to the single-top-level-type rule.

The single-top-level-type rule is intended to guarantee a deterministic mapping between files and primary types for tooling.

#### 3.4.3 Forbidden top-level constructs

1. Top-level statements are forbidden.
2. Top-level variables are forbidden.
3. Top-level functions are forbidden.
4. If an implementation encounters such constructs, it MUST emit a diagnostic at the first forbidden construct.

#### 3.4.4 Default visibility and annotation placement

1. Top-level types default to `internal` visibility unless explicitly declared otherwise.
2. Members declared inside a type default to `private` unless explicitly declared otherwise.
3. Attributes and meta invocations that annotate a top-level type MUST immediately precede the type keyword with no intervening imports or declarations.

### 3.5 File Layout Requirements

Each source file MUST follow this canonical order:

1. Optional license header or tooling directives (comments only).
2. `module` declaration.
3. A contiguous import-section.
4. Exactly one top-level type declaration.

Additional requirements:

1. The `module` declaration MUST appear exactly once.
2. The import-section MUST not be interleaved with other declarations.
3. A file MUST NOT declare more than one module.
4. Generated files MUST obey the same layout.

Naming conventions:

1. A project MAY impose a convention that the file name matches the top-level type name.
2. This document does not require that convention for language conformance.
3. If an implementation enforces such a convention, it MUST do so as a non-normative lint unless a future edition standardizes the rule.

### 3.6 Deterministic Compilation Workflow

Although implementations may organize their front ends differently, observably every conforming compiler behaves as though it executes at least two logical passes.

1. **Structural pass** - Parses syntax, records module memberships, collects declarations, builds symbol tables, and resolves imports. No type checking or ownership analysis occurs in this phase.
2. **Semantic pass** - Performs name binding, type checking, ownership validation, meta-token evaluation, and code generation using the immutable artifacts produced by the structural pass.

Requirements for both passes:

- Diagnostics emitted in either pass MUST reference the original source span discovered during the structural pass.
- Incremental builds MAY cache results between passes, but caches MUST NOT change observable semantics. Recompiling from scratch and recompiling from cache produce identical diagnostics and artifacts.
- Implementations MUST document the order in which files are processed so tooling can reproduce compiler behavior when running lint or format commands.

These structural guarantees ensure that any conforming Cloth toolchain can understand, refactor, or compile a project without hidden assumptions about file layout or module discovery. Every build step, from manifest parsing to semantic analysis, relies on the invariant that modules, imports, and top-level declarations follow the deterministic rules specified above.

### 3.7 Required structural diagnostics

For the following structural errors, a conforming implementation MUST emit a diagnostic and MUST reject the build:

1. Missing `module` declaration.
2. Multiple `module` declarations in one file.
3. Imports appearing outside the import-section.
4. Missing top-level type declaration.
5. Multiple top-level type declarations in one file.
6. Reserved module prefix violations.
7. Importing a non-existent module.
8. Selective import of a non-exported symbol.
9. Duplicate or ambiguous imported names.
10. Import cycle errors that prevent namespace or import-environment construction.


## 4. Type System

Cloth uses a nominal, statically checked, ownership-aware type system. Every expression, declaration, intermediate value, and storage location has a type determined at compile time. This section defines:

1. The universe of types and their classification.
2. The required binary representation properties for primitive types.
3. Composite and derived type formation rules.
4. Nullability and its interaction with type identity and control flow.
5. Modifiers that refine type behavior.
6. Type identity and equality.
7. Type inference constraints.
8. Conversion, casting, and the required diagnostics for unsafe or ambiguous conversions.

Unless explicitly stated otherwise:

1. Types are resolved in the structural and semantic phases described in Section 3.
2. A program is ill-formed if any expression cannot be assigned a type.
3. The implementation MUST reject ill-formed programs with diagnostics that identify the relevant spans and cite the governing clauses.

### 4.0 Type model and foundational requirements

#### 4.0.1 Type assignment

Every expression `e` has a statically determined type `T`. Informally, this may be written as `Γ ⊢ e : T`, where `Γ` is the typing environment (a mapping from names to types and associated modifiers).

1. Type checking is performed without executing user code.
2. Type checking MUST be deterministic.
3. If a construct permits multiple possible types (for example overload candidates), disambiguation rules MUST be deterministic and MUST not depend on hash order, thread scheduling, or file processing order.

#### 4.0.2 Value types and reference types

Cloth distinguishes value categories. These categories are used by the ownership rules (Section 11) and the conversion rules (Section 4.8).

1. A **value type** is represented directly in storage (stack slots, struct fields, tuple components) and has copy/move behavior defined by the language.
2. A **reference type** denotes an indirection to an instance (a heap allocation or implementation-defined runtime allocation).
3. `struct` and tuples are value types.
4. `class` and arrays are reference types.
5. `string` is a reference type.

#### 4.0.3 Type well-formedness

A type expression is well-formed if and only if:

1. Every identifier used in the type expression resolves to a declared type.
2. The type expression uses only type constructors defined by this document (for example `T[]`, `(T0, T1)`, `T?`, `atomic T`).
3. The type constructors are applied only where permitted (for example `atomic T` constraints in Section 4.5.1).

If a type expression is not well-formed, the program is ill-formed.

### 4.1 Classification and Guarantees

This section classifies all types available in edition 1.0 and establishes global invariants.

1. **Primitive types** consist of:
   1. Signed integers: `i8`, `i16`, `i32`, `i64`.
   2. Unsigned integers: `u8`, `u16`, `u32`, `u64`.
   3. Floating-point: `f32`, `f64`.
   4. Boolean: `bool`.
   5. Single-bit integer: `bit`.
   6. Text: `string`.
   Their layout and semantics are fixed by this specification except where explicitly designated implementation-defined.
2. **Composite types** are derived from other types and remain first-class values:
   1. Arrays: `T[]`.
   2. Tuples: `(T0, T1, ..., Tn)`.
3. **Nullable types** `T?` extend the value domain of `T` with the distinguished value `null`.
4. **User-defined types** (classes, structs, interfaces, traits, enums, aliases) are nominal:
   1. Identity depends on the declaring module and the declared name.
   2. Structural equivalence does not imply type identity.
5. `any` is the universal reference supertype.
   1. Any reference type may be implicitly converted to `any`.
   2. A value type may be converted to `any` only if a later section defines boxing; edition 1.0 does not define implicit boxing.
6. `void` denotes the absence of a value.
   1. It may appear only as a function return type.
   2. Variables, fields, and parameters MUST NOT have type `void`.
7. Nullability is explicit.
   1. A non-nullable type MUST NOT receive `null`.
   2. A nullable type MUST permit `null`.
   3. The compiler MUST reject any flow that can assign `null` to a non-nullable location.

### 4.2 Primitive Types

Primitive types have fixed representations and conversion constraints.

#### 4.2.1 Integer types

| Name | Width | Signed | Canonical synonyms |
|------|-------|--------|--------------------|
| `i8` | 8 bits | yes | |
| `i16` | 16 bits | yes | `short` |
| `i32` | 32 bits | yes | `int` |
| `i64` | 64 bits | yes | `long` |
| `u8` | 8 bits | no | `byte` |
| `u16` | 16 bits | no | |
| `u32` | 32 bits | no | `uint`, `unsigned` |
| `u64` | 64 bits | no | |
| `bit` | 1 bit | no | |

Representation and arithmetic requirements:

1. Signed integer types MUST be represented using two’s-complement encoding.
2. Unsigned integer types MUST represent values modulo `2^N`, where `N` is the bit-width.
3. The `bit` type has exactly two values: `0t` and `1t` (Section 2.8.4).
4. Integer literals are tokenized per Section 2 and typed per Section 7 and Section 4.8.

Overflow and exceptional conditions:

1. For signed integer operations, overflow is undefined behavior unless a later clause explicitly defines checked operations.
2. For unsigned integer operations, the result is computed modulo `2^N`.
3. Division by zero is undefined behavior.
4. Shifts by a negative amount or by an amount greater than or equal to the type bit-width are undefined behavior.

#### 4.2.2 Floating-point types

| Name | Width | Standard | Canonical synonyms |
|------|-------|----------|--------------------|
| `f32` | 32 bits | IEEE-754 binary32 | `float` |
| `f64` | 64 bits | IEEE-754 binary64 | `double`, `real` |

Requirements:

1. `f32` and `f64` MUST follow IEEE-754 semantics for arithmetic, comparisons, NaN propagation, and infinities.
2. The set of NaN payload bits is implementation-defined; however, NaN behavior MUST obey IEEE-754 ordering rules (including that comparisons with NaN are false except `!=`).
3. Floating-point exceptions (inexact, overflow, underflow flags) are outside the scope of edition 1.0 and are unspecified.

#### 4.2.3 Boolean type

1. `bool` has exactly two values: `true` and `false`.
2. Control-flow constructs (`if`, `while`, `switch` guards, loop conditions) require operands of type `bool`.
3. No other type implicitly converts to `bool`.

Representation requirements:

1. The in-memory representation of `bool` is implementation-defined.
2. The implementation MUST ensure that `bool` is stably representable for the purposes of `::SIZEOF`, `::ALIGNOF`, and ABI interop rules.

#### 4.2.4 String type

`string` represents immutable text.

1. A `string` value denotes a sequence of UTF-8 bytes.
2. A `string` MAY contain embedded NUL bytes (U+0000) within the UTF-8 sequence.
3. String length, when queried by language operators or meta queries, is measured in bytes unless explicitly stated otherwise by a library API.

Storage and ownership:

1. A `string` value is a reference type.
2. String literals denote `string` values.
3. Literal storage MAY be shared by the implementation, but the language semantics MUST remain consistent with immutability.

### 4.3 Composite Types

Composite types are formed from other types. They have required type identity rules (Section 4.6) and required ownership/lifetime interactions (Section 11).

#### 4.3.1 Arrays

1. Syntax: `T[]`.
2. `T[]` is well-formed if and only if `T` is a well-formed type.
3. Arrays are reference types.
4. An array owns its elements unless the element type itself is a borrow or shared handle type as defined by the ownership model.

Length and indexing:

1. The length of an array is fixed at construction in edition 1.0.
2. Indexing is bounds-checked.
3. A bounds violation MUST result in a runtime error mechanism defined by the runtime environment; the error kind is implementation-defined but MUST be documented.

Equality:

1. Array equality is identity equality unless a later section explicitly defines structural equality.
2. Two arrays are equal if and only if they refer to the same allocation.

#### 4.3.2 Tuples

1. Syntax: `(T0, T1, ..., Tn)` for `n >= 1`.
2. Tuple component types MUST be well-formed.
3. Tuples are value types.

Layout requirements:

1. Tuple components are laid out in declaration order.
2. Each component is aligned according to its alignment requirement.
3. Padding MAY be inserted between components to satisfy alignment.
4. The tuple alignment is the maximum alignment of its components.

Equality and hashing:

1. Tuple equality is structural: two tuples compare equal if and only if each corresponding component compares equal.
2. If any component type lacks equality, tuple equality is ill-formed at any site that requires it.

### 4.4 Nullable Types

#### 4.4.1 Formation and value domain

1. Syntax: `T?`.
2. `T?` is well-formed if and only if `T` is well-formed and `T` is not `void`.
3. The value set of `T?` is `{null} ∪ {v | v ∈ T}`.
4. `T?` is never identical to `T`.

#### 4.4.2 Default values

1. The default value of any nullable type `T?` is `null`.
2. No nullable type defaults to a non-null `T` value unless explicitly initialized.

#### 4.4.3 Null checks and elimination

Converting from `T?` to `T` requires proving non-nullness.

1. A non-null proof may be established by:
   1. Explicit comparison against `null`.
   2. `??` fallback.
   3. Safe cast `as?` combined with control-flow.
   4. Any later construct that explicitly states it eliminates nullability.
2. If the compiler cannot prove non-nullness, assigning a `T?` value to a `T` location is ill-formed.
3. Implementations MUST NOT silently insert null-dereference traps in place of static rejection unless an explicit construct requests a runtime check.

#### 4.4.4 Composition and precedence

1. Nullability binds to the nearest type constructor.
2. `(T[])?` means “nullable reference to an array of `T`”.
3. `T[]?` is ill-formed in edition 1.0 because `?` applies to the array type as a whole; the canonical spelling for nullable arrays is `(T[])?`.
4. A later edition may introduce additional binding rules; edition 1.0 requires parentheses when ambiguity is possible.

### 4.5 Modifiers and Ownership Annotations

Modifiers refine how types and declarations behave with respect to concurrency, storage, or ownership.

#### 4.5.1 `atomic`

1. `atomic T` denotes an atomic storage location containing a value of type `T`.
2. Reads and writes of an `atomic T` location MUST be atomic with sequentially consistent ordering.
3. Only types with a representation supported by the target platform’s native atomic operations may be marked `atomic`.
4. If `T` is not supported for atomic operations, the program is ill-formed and the compiler MUST emit a diagnostic.
5. Applying `atomic` to a reference type applies to the reference value (the handle), not to the referenced object.

#### 4.5.2 `const`

1. `const` denotes immutability of the binding, not necessarily deep immutability of the object graph.
2. Rebinding or assigning to a `const` location is ill-formed.
3. If a `const` binding refers to a mutable reference type, mutation through that reference is governed by the language’s mutability rules; edition 1.0 does not define deep immutability.

#### 4.5.3 Ownership domain modifiers

The modifiers `owned`, `shared`, and `static` interact with Section 11.

1. `owned` indicates that the value participates in deterministic destruction under its owner.
2. `shared` indicates that the value is managed under the shared lifetime domain.
3. `static` indicates the static lifetime domain.
4. A program is ill-formed if it constructs an ownership graph that violates Section 11’s constraints (for example, shared instances owning non-shared children where forbidden).

### 4.6 Type Identity and Equality

Type identity is the criterion for when two types are considered “the same type” for assignment, overloading, and layout.

1. Primitive type identity is based on canonical names.
   1. Canonical synonyms map to the same identity (`int` and `i32` are identical).
2. User-defined type identity is the pair `(declaring module path, declared type name)`.
3. Array type identity is determined by element type identity.
4. Tuple type identity requires identical arity and pairwise identical component types.
5. Nullable type identity is distinct: `T?` is never identical to `T`.
6. Type aliases do not introduce new identity.

### 4.7 Type Inference Rules

Inference exists to reduce verbosity for local bindings while keeping cross-module semantics stable.

1. `var` enables local inference: `var x = expr;` infers `x` as the static type of `expr`.
2. A `var` declaration MUST have an initializer.
3. Inference does not flow from later uses.
4. If an expression has an ambiguous type (for example overload ambiguity), inference fails and the compiler MUST emit a diagnostic requiring explicit annotation.
5. Implementations MUST NOT infer visibility, ownership domain, or lifetime domain from usage.

### 4.8 Conversion and Casting Semantics

Conversions move values between types. Some conversions are implicit; others require explicit syntax.

#### 4.8.1 Explicit cast (`as`)

1. Syntax: `expr as TargetType`.
2. The cast is well-formed if and only if `TargetType` is well-formed and the cast is permitted by the conversion rules below.
3. If the cast cannot be proven safe statically, the implementation MUST insert a runtime check.
4. If a runtime check fails, execution MUST signal a cast failure using an error mechanism. The specific error type is implementation-defined but MUST be documented.

#### 4.8.2 Safe cast (`as?`)

1. Syntax: `expr as? TargetType`.
2. The result type is `TargetType?`.
3. If the cast succeeds, the result is the value converted to `TargetType`.
4. If the cast fails, the result is `null` and no exception is thrown.

#### 4.8.3 Implicit conversions

Implicit conversions are limited to conversions that cannot lose information and cannot fail.

1. Integer widening that preserves signedness (for example `i16 -> i32`, `u8 -> u32`).
2. Floating widening `f32 -> f64`.
3. Reference upcasting along inheritance and interface edges.
4. Adding nullability (`T -> T?`).
5. Converting `bit` to `bool` is permitted only where explicitly stated by later expression rules; it is not a general implicit conversion.

All other conversions require explicit casts.

#### 4.8.4 Prohibited implicit conversions

The following conversions are never implicit in edition 1.0:

1. Any narrowing numeric conversion.
2. Any signed/unsigned conversion.
3. Any conversion from floating-point to integer.
4. Any conversion from nullable to non-nullable.
5. Any conversion from `any` to a more specific type.

#### 4.8.5 Diagnostic requirements for conversions

1. If an implicit conversion is not permitted, the implementation MUST emit a diagnostic that identifies the source type and target type.
2. If a cast is syntactically present but semantically invalid (for example forbidden cast), the implementation MUST emit a diagnostic.
3. If a cast requires a runtime check, the implementation MUST specify (in documentation or diagnostics) that the cast may fail at runtime.

These rules ensure that every type in a Cloth program has a well-defined layout, lifetime, and conversion story. Implementations MUST diagnose violations so that programs remain analyzable and interoperable across toolchains.

## 5. Declarations

Declarations introduce names and associate those names with types, storage, and behavioral constraints. This section specifies the syntax and semantics of declaration forms in edition 1.0.

Section 5 is normative for:

1. The set of legal declaration forms.
2. When and where names become bound.
3. How modifiers change binding, storage, and ownership behavior.
4. Definite assignment and initialization constraints.
5. Function signatures, parameter passing, returns, and `maybe` error flow.

### 5.0 Declaration model and environments

#### 5.0.1 Binding and symbol tables

1. A declaration introduces a **symbol** into a scope (Section 6).
2. A symbol has at minimum:
   1. A name.
   2. A kind (variable, constant, function, type, member, parameter).
   3. A type.
   4. A storage domain (Section 5.0.2).
   5. A visibility (Section 6).
3. Name binding is deterministic.
4. If two declarations introduce the same name in a scope where redeclaration is not permitted, the implementation MUST emit a diagnostic at the later declaration.

#### 5.0.2 Storage domains

Every declared value belongs to exactly one storage domain.

1. **Static domain**: created by `static` declarations.
2. **Instance domain**: fields and members stored within an instance.
3. **Local domain**: locals and temporaries scoped to a block.

The lifetime semantics of each domain are defined by Section 11 and Section 12.

#### 5.0.3 Relationship markers

Cloth uses relationship markers to indicate ownership/lifetime relationships in types.

1. `T` denotes an owned value of type `T`.
2. `&T` denotes a borrow of `T`.
3. `$T` denotes a shared handle to `T`.

The detailed semantics of these markers are governed by Section 11. Section 5 specifies how declaration sites introduce these relationships.

### 5.1 General declaration grammar

This section defines the common lexical and syntactic structure used by the declaration forms below.

#### 5.1.1 Common non-terminals

```
declaration              ::= variable-declaration
                         | constant-declaration
                         | function-declaration
                         | type-declaration

identifier               ::= /* Section 2.5 */
type                      ::= /* Section 4 */
expression                ::= /* Section 7 */
block                      ::= '{' statement* '}'
```

#### 5.1.2 Modifiers

Modifiers appear as a sequence of keywords preceding a declaration.

1. A modifier applies to the smallest following declaration construct.
2. If the same modifier appears more than once on a declaration, the program is ill-formed.
3. If two modifiers are incompatible, the program is ill-formed.
4. Incompatibility is defined by this section and later sections; if not defined explicitly, implementations MUST treat ambiguous combinations as errors rather than picking an interpretation.

### 5.2 Variable declarations

#### 5.2.1 Syntax

Variable declarations introduce mutable bindings.

```
variable-declaration ::= storage-modifier* ('var' | type) declarator-list ';'
declarator-list      ::= declarator (',' declarator)*
declarator           ::= identifier initializer?
initializer          ::= '=' expression

storage-modifier     ::= visibility-modifier
                      | 'static'
                      | 'shared'
                      | 'owned'
                      | 'const'
                      | 'atomic'

visibility-modifier  ::= 'public' | 'private' | 'internal'
```

Constraints:

1. A `var` declaration MUST include an initializer for every declarator in the list.
2. A typed declaration MAY omit the initializer, subject to definite assignment rules.
3. `const` in a variable declaration produces an immutable binding and is governed by Section 4.5.2.
4. `atomic` applies to the declared storage location; it does not change the underlying type except as specified by Section 4.5.1.

#### 5.2.1.1 Declarator list semantics

When a variable declaration contains multiple declarators (for example `i32 a, b = 1;`), the following rules apply:

1. Each declarator introduces a distinct symbol.
2. Each declarator has its own initializer presence or absence.
3. A single modifier sequence applies to every declarator in the list.
4. The type specifier (or `var`) applies to every declarator in the list.
5. If `var` is used, every declarator MUST have an initializer; partial initialization within a declarator list is ill-formed.

#### 5.2.1.2 Storage domain determination

The storage domain of a variable declaration is determined syntactically:

1. If the declaration appears within a block scope (Section 6.1.2), it is a **local declaration**.
2. If the declaration appears within a type body (Section 6.1.4) and is not marked `static`, it is an **instance field declaration**.
3. If the declaration appears within a type body and is marked `static`, it is a **static member declaration**.
4. Edition 1.0 forbids top-level variable declarations (Section 3.4). Therefore every variable declaration is either local, instance, or static.

#### 5.2.1.3 Visibility modifier applicability

Visibility modifiers apply only where a declaration contributes to a module export surface.

1. A local variable declaration MUST NOT specify `public`, `private`, or `internal`.
2. An instance field or static member MAY specify visibility modifiers.
3. If a local variable declaration specifies a visibility modifier, the program is ill-formed and the implementation MUST emit a diagnostic.

#### 5.2.1.4 Modifier categories and roles

The modifiers permitted in a variable declaration have the following roles:

1. `static` selects the static storage domain.
2. `owned` and `shared` constrain ownership domain behavior as defined by Section 11.
3. `const` constrains mutability of the binding (Section 4.5.2).
4. `atomic` constrains storage access and representation (Section 4.5.1).

#### 5.2.1.5 Modifier compatibility and required diagnostics

An implementation MUST enforce the following compatibility rules.

1. `owned` and `shared` are mutually exclusive. If both appear on the same declaration, the program is ill-formed.
2. `atomic` MUST NOT appear together with `shared`.
   1. Rationale: shared handles have domain-specific operations that are not defined as atomic read-modify-write in edition 1.0.
   2. A later edition may define `atomic $T` semantics; edition 1.0 rejects it.
3. `atomic` MAY appear together with `owned`.
4. `static` MAY appear together with `owned`, `shared`, `const`, and `atomic`, subject to their own constraints.
5. If an implementation cannot establish that `atomic` is valid for the underlying type per Section 4.5.1, it MUST emit a diagnostic.
6. If any modifier is repeated, the program is ill-formed.

#### 5.2.2 Local inference with `var`

1. For `var x = expr;`, the compiler assigns `x` the static type of `expr` as determined by Section 4.
2. If `expr` has an ambiguous type, the compiler MUST emit a diagnostic and require an explicit type.
3. Implementations MUST NOT infer visibility, ownership domains, or lifetime domains from later uses.

#### 5.2.3 Definite assignment

1. A variable is **definitely assigned** at a program point if every control-flow path to that point assigns it a value.
2. Reading a variable that is not definitely assigned is ill-formed.
3. For locals without initializers, the compiler MUST enforce definite assignment across all control-flow paths.
4. For instance fields, constructors MUST ensure that every owned field is definitely assigned before the instance is observable outside the constructor (Section 9).

#### 5.2.3.1 Definite assignment analysis requirements

For local variables, the implementation MUST enforce definite assignment using a sound control-flow analysis.

The externally observable behavior MUST be equivalent to the following abstract algorithm:

1. Construct a control-flow graph (CFG) for each function body.
2. For each basic block `B`, compute a set `In[B]` of variables that are definitely assigned on entry, and a set `Out[B]` of variables that are definitely assigned on exit.
3. Define `Transfer(B, S)` to be the result of executing the statements in block `B` in order, adding a variable to the set when an assignment to that variable occurs.
4. Initialize `In[Entry]` with all parameters (including implicit `this`) and with all local variables that have an initializer at their declaration point.
5. For all other blocks, initialize `In[B]` to the empty set.
6. Iterate to a fixed point:
   1. For each block `B` (in any order), set:
      1. `In[B] = ⋂ Out[P]` over all predecessors `P` of `B`.
      2. `Out[B] = Transfer(B, In[B])`.
7. A read of variable `x` at program point `p` is permitted if and only if `x ∈ DA(p)`, where `DA(p)` is the definite-assignment set computed for the CFG location containing `p`.

Loops:

1. The fixed-point iteration handles loops naturally.
2. Implementations MUST NOT assume loop bodies execute at least once.

Short-circuiting control flow:

1. Conditional operators and short-circuiting operators contribute control-flow edges.
2. Definite assignment MUST account for short-circuit evaluation semantics as defined by the expression rules.

The analysis MAY be conservative (reject some programs that are safe) only if a later edition explicitly permits conservative rejection. Edition 1.0 requires acceptance of all programs that satisfy the algorithm above.

#### 5.2.3.2 Uninitialized storage

1. A local variable declared without an initializer is in an uninitialized state until assigned.
2. An instance field declared without an initializer is in an uninitialized state until assigned by a constructor.
3. Static variables declared without an initializer are initialized according to the static initialization rules (Section 9 and Section 12). If no default initialization is defined for a given static type, the program is ill-formed.

#### 5.2.4 Ownership at variable binding

1. If a variable has owned type `T`, the variable becomes the owner of the assigned value and participates in deterministic destruction.
2. If a variable has borrowed type `&T`, the binding does not transfer ownership; it creates a borrow governed by Section 11.
3. If a variable has shared type `$T`, assignment copies or acquires a shared handle as defined by Section 11.

#### 5.2.5 Initialization and assignment semantics at declaration sites

1. If an initializer is present, it is evaluated exactly once and the resulting value is assigned to the declared variable.
2. Initialization order for multiple declarators is textual left-to-right.
3. If an initializer expression reads a variable declared later in the same declarator list, the program is ill-formed (the later variable is not in scope).
4. If a variable is declared with `const`, it MUST be initialized at its declaration site unless a later section explicitly permits deferred initialization.

#### 5.2.6 Variable-specific required diagnostics

For the following variable-declaration errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. A `var` declaration without an initializer.
2. A `var` declarator list where not every declarator has an initializer.
3. A local variable declaration specifying `public`, `private`, or `internal`.
4. `owned` and `shared` applied together.
5. `atomic` applied to a type not permitted by Section 4.5.1.
6. `atomic` applied together with `shared`.
7. Any repeated modifier.
8. Any read of a variable that is not definitely assigned at that program point.

### 5.3 Constant declarations

Constants introduce immutable bindings.

#### 5.3.1 Syntax

```
constant-declaration ::= visibility-modifier? 'static'? 'const' type identifier '=' constant-expression ';'
```

#### 5.3.1.1 Constant kinds

Constants exist in two forms.

1. **Static constants**: declared with `static const`.
   1. Their storage is in the static domain.
   2. Their initializer is evaluated during program initialization (Section 12), subject to the constant-expression restrictions in this section.
2. **Instance constants**: declared with `const` inside a type body without `static`.
   1. Their storage is in the instance domain.
   2. Their initializer is evaluated during instance construction, in textual order relative to other field and constant initializers.

Edition 1.0 does not define local `const` declarations as a distinct declaration form; `const` used in a variable declaration is treated as an immutable variable binding (Section 5.2).

#### 5.3.2 Constant expressions

A constant-expression is an expression that can be evaluated at compile time.

1. A constant-expression MAY contain:
   1. Literals.
   2. Meta keyword invocations.
   3. References to other constants.
2. A constant-expression MUST NOT allocate owned runtime instances unless a later edition defines compile-time allocation semantics.
3. If an initializer is not a constant-expression, the program is ill-formed and the implementation MUST emit a diagnostic.

#### 5.3.2.1 Constant-expression grammar (edition 1.0)

The following grammar defines the syntactic subset of expressions permitted as constant-expressions in edition 1.0.

```
constant-expression ::= constant-or
constant-or         ::= constant-and ('or' constant-and)*
constant-and        ::= constant-eq ('and' constant-eq)*
constant-eq         ::= constant-rel (('==' | '!=') constant-rel)*
constant-rel        ::= constant-add (('<' | '<=' | '>' | '>=') constant-add)*
constant-add        ::= constant-mul (('+' | '-') constant-mul)*
constant-mul        ::= constant-unary (('*' | '/' | '%') constant-unary)*
constant-unary      ::= ('+' | '-' | '!' | '~') constant-unary | constant-primary
constant-primary    ::= literal
                    | identifier
                    | qualified-constant
                    | meta-invocation
                    | '(' constant-expression ')'

qualified-constant  ::= module-path '.' identifier ('.' identifier)*
meta-invocation     ::= '::' META_KEYWORD meta-args?
meta-args           ::= '(' constant-arg-list? ')'
constant-arg-list   ::= constant-expression (',' constant-expression)*
```

Constraints:

1. `identifier` and `qualified-constant` in a constant-expression MUST resolve to a constant declaration.
2. Function calls are not permitted in constant-expressions in edition 1.0.
3. Allocation expressions (`new`) are not permitted in constant-expressions in edition 1.0.
4. Member access on non-module values is not permitted in constant-expressions in edition 1.0.
5. The exact set of permitted operators is the set shown in the grammar above.
6. Any use of an expression form not covered by this grammar is not a constant-expression.

#### 5.3.2.2 Constant evaluation semantics

The implementation MUST evaluate each constant-expression to a value of the declared constant type.

1. Meta invocations are evaluated according to their definitions (Section 2.3.2 and later semantic rules).
2. If constant evaluation encounters undefined behavior (for example division by zero in a constant-expression), the program is ill-formed and MUST be rejected with a diagnostic.
3. If constant evaluation requires a runtime check (for example a cast that is not statically provable), the expression is not a constant-expression and the program is ill-formed.

#### 5.3.2.3 Type checking of constant expressions

1. The initializer of a constant MUST be type-correct under the normal expression typing rules.
2. Implicit conversions in constant expressions follow the same rules as other expressions.
3. If the initializer’s type cannot be converted to the constant’s declared type, the program is ill-formed.

#### 5.3.2.4 Constant dependency graph

Constant initializers may refer to other constants. Implementations MUST resolve these dependencies deterministically.

1. Construct a directed dependency graph `G` where each node is a constant declaration and an edge `A -> B` indicates that constant `A`’s initializer depends on constant `B`.
2. Dependencies are determined after name resolution.
3. The implementation MUST evaluate constants in an order consistent with a topological ordering of `G`.

#### 5.3.2.5 Cycles

1. If the dependency graph contains a directed cycle, the program is ill-formed.
2. The implementation MUST emit a diagnostic that:
   1. Identifies at least one constant involved in the cycle.
   2. Prints a cycle path.
3. The implementation MUST NOT break cycles by choosing an arbitrary evaluation order.

#### 5.3.3 Storage and initialization

1. A constant MUST be initialized exactly once.
2. A `static const` constant is initialized in the static domain.
3. A non-static `const` declaration inside a type body denotes an instance constant bound per-instance and initialized during instance construction.

#### 5.3.3.1 Initialization ordering within a type

Within a type body, instance constant initializers are evaluated in the same ordering regime as instance field initializers.

1. Initialization order is textual order.
2. An initializer MAY reference earlier fields/constants.
3. An initializer MUST NOT reference later fields/constants.
4. Violations MUST be diagnosed.

#### 5.3.3.2 Visibility of constants

1. Visibility modifiers on constants are enforced as for other member declarations (Section 6).
2. A constant referenced from another module MUST be visible and exported.
3. If an out-of-module reference violates visibility, the implementation MUST emit an accessibility diagnostic.

#### 5.3.4 Constant-specific required diagnostics

For the following constant-declaration errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Constant initializer is not a constant-expression.
2. Constant initializer contains a forbidden construct (call, allocation, non-constant member access).
3. Constant initializer evaluates a form of undefined behavior (for example division by zero).
4. Constant dependency cycle.
5. Reference to an identifier in a constant-expression that does not resolve to a constant.
6. Constant initializer type mismatch.
7. Instance constant initializer references a later field/constant in the same type.

### 5.4 Function and method declarations

Functions introduce callable symbols.

#### 5.4.1 Syntax

```
function-declaration ::= function-modifier* 'func' identifier parameter-list return-clause maybe-clause? function-body
parameter-list       ::= '(' parameter (',' parameter)* ')'
parameter            ::= type identifier default-value?
default-value        ::= '=' expression
return-clause        ::= ':>' type
maybe-clause         ::= 'maybe' type-list
type-list            ::= type (',' type)*
function-body        ::= block | ';'
```

Constraints:

1. A function declaration with body `';'` is an abstract signature (permitted only where explicitly allowed, for example in interface-like types).
2. A function declaration with a `block` is a definition.
3. The return type MUST be specified; edition 1.0 does not infer return types.

#### 5.4.1.1 Function modifiers

Function modifiers refine visibility, storage domain, and concurrency semantics.

Edition 1.0 recognizes the following function modifiers:

1. Visibility modifiers: `public`, `private`, `internal`.
2. Storage modifier: `static`.
3. Concurrency modifier: `async`.

An implementation MUST reject any function modifier not listed above unless compiling under an edition that defines it.

Modifier application rules:

1. A function modifier sequence applies to the declared function.
2. Duplicate modifiers are ill-formed.
3. Incompatible modifiers are ill-formed.

Compatibility rules:

1. `static` is compatible with any visibility modifier.
2. `async` is compatible with any visibility modifier.

Override behavior is specified via traits (Section 5.8), not via function modifiers.

#### 5.4.1.2 Declarations, definitions, and abstract signatures

1. A function declaration with a `block` is a definition.
2. A function declaration terminated by `;` is an abstract signature.
3. Abstract signatures are permitted only inside `interface` bodies in edition 1.0, unless the declaration is annotated with `#Trait Prototype` (Section 5.8).
4. An abstract signature MUST NOT appear at module scope.
5. A definition MUST NOT appear inside an `interface` body.
6. If an abstract signature appears where definitions are required, or vice versa, the program is ill-formed.

#### 5.4.1.3 Return clause requirements

1. Every function MUST have an explicit return clause `:> T`.
2. `T` MUST be a well-formed type.
3. A function returning `void` MUST still specify `:> void`.

#### 5.4.1.4 `maybe` clause syntax constraints

1. If present, a `maybe` clause MUST appear after the return clause.
2. A `maybe` clause MUST contain at least one type.
3. Each type in a `maybe` clause MUST be a well-formed type and MUST be distinct within the list.

#### 5.4.2 Function identity and signatures

The identity of a function is determined by:

1. Declaring module.
2. Declaring type, if any.
3. Function name.
4. Parameter count.
5. Parameter types in order.

Return types and `maybe` clauses do not participate in overload identity unless a later section explicitly states otherwise.

If two functions in the same overload set have identical identity, the program is ill-formed.

#### 5.4.2.1 Overload sets and lookup

1. Functions with the same name in the same declaring scope form an overload set.
2. Overload sets are formed independently for:
   1. Module-level functions.
   2. Static member functions.
   3. Instance member functions.
3. Name lookup selects an overload set before overload resolution.
4. If overload resolution is ambiguous, the program is ill-formed and the compiler MUST emit a diagnostic that identifies the candidate set.

#### 5.4.2.2 Signature compatibility for overrides

Where a method overrides another method:

1. Parameter count MUST match.
2. Parameter types MUST be identical.
3. Return type MUST be identical.
4. `maybe` clause types MUST be identical.

A later edition may introduce variance rules; edition 1.0 requires exact match.

#### 5.4.3 Parameter passing and ownership

1. Parameters are bindings local to the function scope.
2. For owned parameters (`T`), argument evaluation transfers ownership into the callee.
3. For borrowed parameters (`&T`), argument evaluation binds a borrow; ownership remains with the caller.
4. For shared parameters (`$T`), argument evaluation copies a shared handle.
5. The callee MUST NOT store a borrow beyond the lifetime proven by Section 11.

#### 5.4.3.1 Parameter list constraints

1. Every parameter MUST have an explicit type.
2. Every parameter MUST have an identifier name.
3. Parameter names MUST be unique within a single parameter list.
4. Parameters are introduced into function scope in textual order.
5. Relationship markers in parameter types (`T`, `&T`, `$T`) have the semantics described in Section 11.

#### 5.4.3.2 Argument evaluation and binding order

Unless a later section explicitly defines a different order, function call evaluation MUST behave as follows:

1. The callee expression is evaluated first.
2. Arguments are evaluated left-to-right.
3. Default arguments (Section 5.4.4) are evaluated at the call site and interleaved as if they appeared at their parameter positions.
4. After evaluation, each argument value is bound to its corresponding parameter according to the parameter’s relationship marker.

If argument evaluation causes side effects, the left-to-right order above is observable and therefore normative.

#### 5.4.3.3 Owned parameter obligations

If a parameter has owned type `T`:

1. The callee becomes the owner of the argument value.
2. The callee MUST ensure that the owned value is either:
   1. Destroyed within the callee, or
   2. Moved into another owner, or
   3. Returned to the caller.

Failure to satisfy ownership obligations is ill-formed and MUST be diagnosed by ownership analysis (Section 11).

#### 5.4.4 Default parameter values

1. Default parameter values are evaluated at the call site.
2. Default parameter values are evaluated immediately before argument binding.
3. A default parameter expression MAY reference earlier parameters by name.
4. A default parameter expression MUST NOT reference later parameters.

#### 5.4.4.1 Default parameter placement

1. Parameters without defaults MUST precede parameters with defaults.
2. If a parameter without a default appears after a parameter with a default, the program is ill-formed.

#### 5.4.4.2 Default parameter typing

1. The default expression MUST be type-correct.
2. The default expression’s type MUST be convertible to the parameter type.
3. Default expressions MUST obey ownership rules. If a default expression yields an owned value, that owned value is transferred into the callee as if it were explicitly passed.

#### 5.4.5 Return semantics

1. Returning an owned type transfers ownership to the caller.
2. Returning a borrowed type `&T` borrows from a value whose lifetime MUST outlive the call.
3. Returning a shared handle `$T` returns a handle value governed by shared-domain rules.

#### 5.4.5.1 Return completeness

1. A function with non-`void` return type MUST return a value along every control-flow path.
2. A `return;` statement is permitted only in a function returning `void`.
3. Reaching the end of a function body without returning in a non-`void` function is ill-formed.

#### 5.4.6 `maybe` clauses

1. A `maybe` clause declares a finite set of error types that may be thrown instead of returning normally.
2. The listed types MUST be well-formed types.
3. A function without a `maybe` clause MUST NOT throw typed errors except where a later section defines an untyped panic mechanism.
4. Ownership rules apply to both success and error paths.

#### 5.4.6.1 `maybe` as part of the function contract

1. A `maybe` clause is part of the function’s static contract.
2. Any `throw` statement in the function body MUST throw a value whose type is included in the `maybe` list.
3. If the function calls another function that may throw, the caller MUST either:
   1. Handle the error (Section 8), or
   2. Include that error type in its own `maybe` clause.

#### 5.4.7 Function-specific required diagnostics

For the following function-declaration errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Missing return clause.
2. Abstract signature used outside an `interface` body.
3. Function definition used inside an `interface` body.
4. Duplicate parameter name in a parameter list.
5. Parameter without explicit type.
6. Parameter without name.
7. Non-default parameter appearing after a default parameter.
8. Default parameter referencing a later parameter.
9. Non-`void` function missing a return along some control-flow path.
10. `maybe` clause with duplicate types.
11. `throw` of a type not listed in the enclosing function’s `maybe` clause.
12. Invalid use of reserved or unsupported function modifier in edition 1.0.

### 5.5 Receivers and member functions

Member functions are functions declared within a type body. Instance member functions are **methods** and introduce an implicit receiver binding `this`.

#### 5.5.1 Receiver existence and kind

1. A member function declared with the `static` modifier is a **static member function** and has no implicit receiver.
2. A member function declared without `static` is an **instance member function** and has an implicit receiver named `this`.
3. The binding `this` is a parameter-like binding that exists for the duration of the method body.
4. The spelling `this` is reserved and MUST NOT be re-bound by a local declaration.

#### 5.5.2 Default receiver relationship marker

The implicit receiver `this` has a relationship marker determined by the declaring type category.

1. For classes, the default receiver relationship marker is owned (`T`): `this : T`.
2. For structs, the default receiver relationship marker is borrowed (`&T`): `this : &T`.
3. Edition 1.0 does not define a syntax for explicitly changing the receiver relationship marker at the declaration site.
4. A later edition may define receiver modifiers (for example `mutating`) that alter receiver semantics; no such modifier exists in edition 1.0.

#### 5.5.3 Receiver scope and resolution

1. Within an instance member function body, unqualified member access MAY be written using implicit `this`.
   1. For example, `field` within a method body is equivalent to `this.field`.
2. If an identifier name is both a local binding and a member name, the local binding takes precedence.
3. If an unqualified name resolves to both a field and a zero-argument method, the resolution rules MUST be deterministic and MUST be specified by the expression rules (Section 7); in the absence of such a rule, the program is ill-formed.

#### 5.5.4 Call-site forms and binding

Instance member function calls and static member function calls are syntactically and semantically distinct.

1. A static member function MUST be referenced through its declaring type name (Section 7.13) and MUST NOT be invoked through an instance.
2. An instance member function MUST be invoked through a receiver expression.
3. The receiver expression is evaluated before the argument list and participates in ownership and lifetime checks.
4. Argument evaluation order is defined by Section 5.4.3.2.

#### 5.5.5 `this` lifetime and borrowing constraints

The receiver binding `this` participates in the ownership and lifetime model (Section 11).

1. If `this` is borrowed (`&T`), the method MUST NOT:
   1. Store `this` (or a borrow derived from `this`) into any location whose lifetime may outlive the call.
   2. Return a borrow that is not proven to be derived from a value that outlives the call.
2. If `this` is owned (`T`), invoking an instance method consumes the receiver value unless the method is invoked through a borrow of that value.
3. Any move out of `this` that would leave `this` partially uninitialized is governed by the ownership rules in Section 11.

#### 5.5.6 Member function declarations vs free functions

1. A member function is associated with a declaring type and participates in that type’s member scope.
2. A free function is declared at module scope.
3. The overload sets for member functions are separate from overload sets for free functions.

#### 5.5.7 Interaction with traits affecting dispatch

Dispatch-related semantics for member functions are expressed using traits (Section 5.8).

1. Override declarations are expressed using `#Trait Override` (Section 5.8.9.4).
2. Prototype/implementation pairing for member functions is expressed using `#Trait Prototype` and `#Trait Implementation` (Sections 5.8.9.1 and 5.8.9.2).

#### 5.5.8 Receiver-specific required diagnostics

For the following receiver and member-function errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. A static member function invocation performed through an instance receiver.
2. An instance member function invocation performed without a receiver.
3. Any attempt to declare a local binding named `this`.
4. Any attempt to reference `this` in a static member function.

### 5.6 Type declarations (overview)

Type declarations introduce nominal types and their member declarations.

1. The full semantics of classes, structs, enums, and interfaces are defined in Section 9.
2. Section 5 specifies the declaration-site constraints required for a program to be structurally and semantically well-formed.

#### 5.6.0 Type declaration categories

Edition 1.0 recognizes the following nominal type declaration categories:

1. `class`
2. `struct`
3. `enum`
4. `interface`

Other type forms, including `type` aliases, are described elsewhere in this document.

#### 5.6.0.1 Declaration grammar (structural)

This section constrains the structural shape of type declarations for the purpose of name binding and well-formedness.

```
type-declaration ::= class-declaration | struct-declaration | enum-declaration | interface-declaration | type-alias

class-declaration     ::= visibility-modifier? class-modifier* 'class' identifier class-header? type-body
struct-declaration    ::= visibility-modifier? struct-modifier* 'struct' identifier struct-header? type-body
enum-declaration      ::= visibility-modifier? enum-modifier* 'enum' identifier enum-header? type-body
interface-declaration ::= visibility-modifier? interface-modifier* 'interface' identifier interface-header? type-body

type-body ::= '{' member-declaration* '}'
```

The exact permitted modifier sets (`class-modifier`, `struct-modifier`, etc.) and header forms (`class-header`, `enum-header`, etc.) are defined in Section 9. Section 5 requires that the declaration be structurally parseable and that the name-binding and member constraints below are enforced.

Common constraints:

1. Type names MUST be valid identifiers.
2. A type declaration introduces a symbol into the enclosing module.
3. A type name MUST be unique within its module.
4. Members are declared within the type body and participate in the type’s member scope.

#### 5.6.0.2 Type symbol identity

1. The identity of a type is determined by:
   1. The declaring module.
   2. The declared type name.
   3. The declaration category (`class`, `struct`, `enum`, `interface`).
2. If two type declarations in the same module share the same name (regardless of category), the program is ill-formed.

#### 5.6.0.3 Member categories

Member declarations are syntactic constructs inside a type body. Edition 1.0 recognizes the following member categories:

1. Field declarations (instance and static).
2. Constant declarations (instance and static).
3. Function/method declarations (instance and static).
4. Constructor declarations.
5. Destructor declarations.
6. Nested type declarations.
7. Trait annotations (Section 5.8) applied to any of the above.

If an implementation encounters a construct inside a type body that is not a member category defined by this specification, the program is ill-formed.

#### 5.6.0.4 Member name uniqueness and overload rules

1. Field names MUST be unique within a type body. A type MUST NOT declare two fields with the same name.
2. Constant names MUST be unique within a type body.
3. A field name MUST NOT conflict with a constant name in the same type.
4. Function/method names MAY be overloaded subject to Section 5.4.2.
5. A field or constant name MUST NOT conflict with a function overload set name in the same type.
   1. If such a conflict exists, the program is ill-formed.
6. Nested type names MUST be unique within the containing type’s member scope.

#### 5.6.0.5 Static vs instance members

1. A member declaration with `static` belongs to the static domain and is associated with the type rather than any instance.
2. A member declaration without `static` belongs to the instance domain and is associated with each instance.
3. Static members MUST NOT access instance members without an explicit receiver expression.

#### 5.6.0.6 Visibility defaults

1. If a member declaration omits an explicit visibility modifier, the default visibility is determined by Section 3.4.4.
2. Visibility modifiers are enforced by the accessibility rules (Section 6).

#### 5.6.1 Fields and ownership markers

1. Unmarked instance fields are owned by the containing instance.
2. Borrowed fields MUST be declared using `&T`.
3. Shared-handle fields MUST be declared using `$T`.
4. Static members belong to the static domain.

#### 5.6.1.1 Field declaration constraints

1. A field declaration MUST declare a type for each field.
2. `var` MUST NOT be used for field type inference in edition 1.0.
3. Field names MUST be valid identifiers.
4. Field declarations MUST NOT appear inside `interface` bodies.
5. A borrowed field (`&T`) MUST NOT be declared as owned by construction; it is a borrowed reference and must satisfy lifetime constraints (Section 11).
6. A shared-handle field (`$T`) is a handle value governed by shared-domain rules (Section 11).

#### 5.6.1.2 Initialization requirements for fields

1. Owned instance fields MUST be definitely assigned before the instance becomes observable outside its constructor (Section 5.2.3 and Section 9).
2. Reading an uninitialized field is ill-formed.
3. Static fields follow static initialization requirements (Section 12).

#### 5.6.2 Constructors and initialization

1. Constructors MUST initialize all owned fields before the instance escapes.
2. A constructor MUST NOT read an uninitialized field.
3. Field initialization order is textual order unless a later section defines explicit initialization lists.

#### 5.6.2.1 Constructor declaration-site constraints

1. A constructor MUST be declared within a type body.
2. A constructor MUST have the same name as its declaring type unless a later edition defines alternate constructor naming.
3. A constructor MUST NOT be declared `static`.
4. Interfaces MUST NOT declare constructors.

#### 5.6.3 Destructors

1. Destructors run after owned children are destroyed (Section 11).
2. Destructor ordering between base and derived types is defined in Section 9.

#### 5.6.3.1 Destructor declaration-site constraints

1. A destructor MUST be declared within a type body.
2. Interfaces MUST NOT declare destructors.
3. A destructor MUST NOT be declared `static`.

#### 5.6.4 Type-declaration-specific required diagnostics

For the following type-declaration errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Two type declarations with the same name in the same module.
2. A duplicate field name in a type body.
3. A duplicate constant name in a type body.
4. A name conflict between field/constant and a function overload set name.
5. A field declared inside an `interface` body.
6. A `var`-typed field.
7. A constructor declared `static`.
8. A constructor declared within an `interface`.
9. A destructor declared `static`.
10. A destructor declared within an `interface`.

### 5.7 Required declaration diagnostics

For the following errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Redeclaration of a name in a scope where redeclaration is forbidden.
2. Use of `var` without an initializer.
3. Reading a variable before definite assignment.
4. Constant initializer that is not a constant-expression.
5. Function without an explicit return type.
6. Duplicate function identity within an overload set.
7. Default parameter referencing a later parameter.
8. Ill-formed ownership relationship markers at a declaration site.

#### 5.7.1 Diagnostic payload requirements (declarations)

For every diagnostic required by Section 5, the implementation MUST include:

1. A primary source span identifying the declaration site (or the earliest unambiguous token that determines the declaration form).
2. A short machine-stable error code or category identifier.
3. A human-readable message.
4. A reference to the governing clause number(s) in this document.
5. If the diagnostic arises from a name conflict, the diagnostic MUST include secondary spans for at least one conflicting declaration.

#### 5.7.2 Declaration diagnostic categorization

Declaration diagnostics fall into the following categories.

1. **Binding and scope errors**: violations of name uniqueness, visibility, and resolution constraints.
2. **Typing errors at declaration sites**: ill-formed types, prohibited inference forms, or initialization type mismatches.
3. **Ownership and lifetime errors**: invalid relationship markers, illegal moves/borrows at declaration boundaries.
4. **Initialization and definite-assignment errors**: missing initializers where required, reads before assignment, and constructor field initialization failures.
5. **Trait errors**: invalid trait placement, invalid trait arguments, or trait contract violations.

Implementations MAY report a more specific subcategory, but they MUST map every rejection to at least one of the categories above.

#### 5.7.3 Minimal required diagnostic set

The following list is the minimal required set of declaration-related errors that MUST be diagnosed and MUST be rejected.

##### 5.7.3.1 Name binding and conflicts

1. Redeclaration of a name in a scope where redeclaration is forbidden.
2. Duplicate field name within a type body (Section 5.6.0.4).
3. Duplicate constant name within a type body (Section 5.6.0.4).
4. Name conflict between field/constant and a function overload set name (Section 5.6.0.4).
5. Duplicate function identity within an overload set (Section 5.4.2).
6. Duplicate trait declaration name within a module (Section 5.8.11.8).

##### 5.7.3.2 Variable and initialization errors

1. Use of `var` without an initializer (Section 5.2.1).
2. Reading a variable before definite assignment (Section 5.2.3).
3. A `var` declarator list where not every declarator has an initializer (Section 5.2.1.1).
4. Local visibility modifiers applied to a local variable (Section 5.2.1.3).
5. An illegal variable modifier combination (for example `owned` with `shared`, or `atomic` with `shared`) (Section 5.2.1.5).

##### 5.7.3.3 Constant declaration errors

1. Constant initializer that is not a constant-expression (Section 5.3.2).
2. Constant dependency cycle (Section 5.3.2.5).
3. Instance constant initializer referencing a later field/constant in the same type (Section 5.3.3.1).

##### 5.7.3.4 Function and method declaration errors

1. Function without an explicit return type / return clause (Section 5.4.1.3).
2. Default parameter referencing a later parameter (Section 5.4.4).
3. Non-default parameter appearing after a default parameter (Section 5.4.4.1).
4. Abstract signature used outside an `interface` body, unless permitted by `#Trait Prototype` (Sections 5.4.1.2 and 5.8.9.1).
5. Function definition used inside an `interface` body (Section 5.4.1.2).
6. Duplicate parameter name in a parameter list (Section 5.4.3.1).
7. Non-`void` function missing a return along some control-flow path (Section 5.4.5.1).

##### 5.7.3.5 Receiver and member invocation errors

1. A static member function invocation performed through an instance receiver (Section 5.5.8).
2. An instance member function invocation performed without a receiver (Section 5.5.8).
3. Any attempt to declare a local binding named `this` (Section 5.5.1).
4. Any attempt to reference `this` in a static member function (Section 5.5.8).

##### 5.7.3.6 Type declaration structural errors

1. Two type declarations with the same name in the same module (Section 5.6.0.2).
2. A `var`-typed field (Section 5.6.1.1).
3. A field declared inside an `interface` body (Section 5.6.1.1).
4. A constructor declared `static` (Section 5.6.2.1).
5. A destructor declared `static` (Section 5.6.3.1).
6. A constructor or destructor declared within an `interface` body (Sections 5.6.2.1 and 5.6.3.1).

##### 5.7.3.7 Trait errors

1. A `#Trait` annotation not followed by a declaration (Section 5.8.10).
2. Duplicate application of the same trait to one declaration (Section 5.8.10).
3. `Prototype` without exactly one matching `Implementation` (Section 5.8.9.1).
4. `Implementation` without a matching `Prototype` (Section 5.8.9.2).
5. Applying a declared trait with missing required arguments (Section 5.8.11.8).
6. Applying a declared trait with an unknown argument name (Section 5.8.11.8).
7. Applying a declared trait with omitted parentheses when the declared trait has one or more parameters (Section 5.8.11.8).

#### 5.7.4 Multiple diagnostics and deduplication

1. If multiple rules are violated by the same declaration, the implementation MAY emit multiple diagnostics.
2. The implementation SHOULD avoid emitting multiple diagnostics that report the same root cause with the same primary span.
3. If later errors are a direct consequence of an earlier ill-formedness (for example, type checking after a missing symbol), the implementation MAY suppress downstream diagnostics and emit a single primary diagnostic.

#### 5.7.5 Diagnostic ordering

1. Diagnostic ordering is not semantically significant.
2. Implementations SHOULD order diagnostics by source location.
3. Implementations MUST NOT allow diagnostic ordering to affect acceptance or rejection of a program.

These rules guarantee that every declaration participates predictably in the ownership model, allowing compilers and tooling to enforce deterministic destruction, visibility, and type safety across the language.

### 5.8 Traits (attached declaration metadata)

Cloth traits are attached metadata applied to declarations using `#Trait` syntax. A trait annotation is a syntactic form that is preserved through parsing and name binding and that may participate in semantic validation, diagnostics, and code generation.

#### 5.8.1 Trait model

1. A **trait** is a named, structured annotation associated with exactly one **target declaration**.
2. A trait annotation is not a declaration by itself; it does not introduce names into scopes.
3. The presence of a trait MAY influence compilation only when this specification defines semantics for that trait.
4. Traits are part of the source-level AST and MUST be preserved by conforming tooling conformance profiles (formatters, indexers, refactoring tools) unless a tool explicitly declares that it discards non-semantic metadata.

#### 5.8.2 Trait application sites and targets

Traits MAY be applied to the following declaration categories:

1. Module declarations.
2. Type declarations (`class`, `struct`, `enum`, `interface`).
3. Trait declarations (`trait`).
4. Member declarations inside type bodies:
   1. Fields.
   2. Constants.
   3. Functions and methods.
   4. Constructors and destructors.
5. Parameters.
6. Local declarations (variables and constants).

Constraints:

1. A trait annotation MUST appear immediately preceding its target declaration, with only whitespace and comments permitted in between.
2. If a `#Trait` annotation is not followed by a declaration, the program is ill-formed.
3. The target declaration of a `#Trait` is the next declaration in the token stream as defined by the parser.

#### 5.8.3 Syntax and grammar

Trait annotations are parsed prior to the declaration they attach to.

```
trait-annotation      ::= '#Trait' trait-specifier
trait-specifier       ::= trait-name trait-arguments?
trait-name            ::= unqualified-trait-name | qualified-trait-name
unqualified-trait-name ::= identifier | keyword
qualified-trait-name  ::= module-path '.' identifier ('.' identifier)*
trait-arguments       ::= '(' trait-argument-list? ')'
trait-argument-list   ::= trait-argument (',' trait-argument)*
trait-argument        ::= identifier '=' constant-expression
```

Constraints:

1. Trait arguments are named; positional arguments are not permitted in edition 1.0.
2. `constant-expression` is defined by Section 5.3.2.
3. A trait name MUST be treated as case-sensitive.
4. `trait-name ::= identifier | keyword` permits built-in trait names that are lexed as keywords.

#### 5.8.3.1 Qualified trait names

1. A qualified trait name refers to a trait declaration exported from another module or nested module path.
2. The `module-path` component is resolved using the same module path rules as imports and qualified constant references (Sections 3 and 5.3.2.1).
3. Built-in compiler-known traits (Section 5.8.9) MAY be referenced only by unqualified names in edition 1.0.

#### 5.8.4 Ordering, stacking, and duplicate traits

Multiple traits MAY be stacked directly above the same declaration.

1. Trait annotations apply in source order.
2. The semantic effect of a set of traits MUST be independent of trait ordering unless a trait definition explicitly states otherwise.
3. Duplicate traits (same trait name) applied to the same declaration are ill-formed unless the trait is explicitly defined as repeatable.
4. No built-in trait in edition 1.0 is repeatable.

#### 5.8.5 Compiler-known traits vs user-defined/tooling traits

1. A **compiler-known trait** is a trait for which this specification defines semantic behavior or additional static constraints.
2. A **tooling trait** is any trait not known to the compiler conformance profile.
3. Unknown traits MUST be parsed and attached to the declaration.
4. Unknown traits MUST NOT cause program rejection.
5. The compiler SHOULD emit a warning for unknown traits, but it MUST provide a mechanism to suppress such warnings.

User-defined trait declarations (Section 5.8.11) define traits that are not compiler-known. Such traits MAY be used for tooling, documentation, and build-time policy, but they MUST NOT change core language semantics unless a later edition explicitly defines semantic hooks.

#### 5.8.6 Trait argument validation

For compiler-known traits:

1. The set of permitted argument names is fixed by the trait’s definition.
2. Each argument name MUST be unique within a single trait application.
3. Missing required arguments or the presence of an unknown argument name is ill-formed.
4. Each argument value MUST be a constant-expression and MUST be convertible to the required argument type.

For unknown traits:

1. Argument names and values are not validated by the compiler.
2. Tools MAY validate arguments according to external conventions.

For declared (user-defined) traits (Section 5.8.11):

1. Arguments MUST be provided according to the declared parameter list.
2. Argument values MUST be constant-expressions.
3. The mapping from declared parameters to supplied arguments is defined by Section 5.8.11.5.

#### 5.8.6.1 Argument presence rules

1. If a trait application omits `trait-arguments`, the trait is applied as a marker application.
2. Marker application is permitted only for:
   1. Built-in traits explicitly defined as marker traits in this specification, or
   2. Declared traits with zero parameters (Section 5.8.11.5).
3. If a trait application provides `trait-arguments` for a marker trait, the following rules apply:
   1. Empty parentheses `()` are permitted.
   2. Any non-empty argument list is ill-formed.

#### 5.8.7 Propagation and inheritance

1. Traits are local to their target declaration.
2. Traits are not inherited by derived types and are not implicitly propagated from a type to its members.
3. If a trait is intended to influence derived members (for example deprecation propagation), that behavior MUST be explicitly specified by the trait definition.

#### 5.8.8 Effects on code generation, diagnostics, and metadata

1. Traits MAY:
   1. Constrain where a declaration form is permitted.
   2. Require additional diagnostics.
   3. Affect code generation decisions.
   4. Contribute to emitted metadata for tooling.
2. Traits MUST NOT change parsing or lexical rules.
3. Traits MUST NOT retroactively make an ill-formed declaration well-formed unless this specification explicitly defines that trait as enabling a specific form.

#### 5.8.8.1 Trait metadata preservation

When an implementation emits any intermediate representation, metadata, or symbol index intended for tooling consumption, it MUST preserve the trait set associated with each declaration, subject to the following constraints:

1. The preserved representation MUST include:
   1. The trait name as written (qualified or unqualified).
   2. The resolved trait identity when resolution is performed (built-in, declared trait symbol, or unknown tooling trait).
   3. The argument map (argument name to constant value) for syntactically present arguments.
2. Tools MAY choose to display either the source spelling or the resolved identity; both MUST be available.

#### 5.8.8.2 Trait evaluation boundary

1. Trait argument expressions MUST NOT be evaluated at runtime.
2. Trait argument expressions MUST be evaluated only within constant evaluation as defined by Section 5.3.2.
3. Any trait argument that cannot be evaluated as a constant-expression renders the trait application ill-formed when validation is required (built-in traits and declared traits).

#### 5.8.8.3 Trait effects are explicit

1. A trait has no semantic effect unless:
   1. It is a compiler-known trait defined by this specification, or
   2. A later edition explicitly introduces a mechanism for user-defined semantic traits.
2. Implementations MUST NOT infer semantic meaning from unknown tooling trait names.

#### 5.8.9 Built-in traits (edition 1.0)

Edition 1.0 defines the following compiler-known traits.

##### 5.8.9.1 `Prototype`

`#Trait Prototype` declares that the annotated declaration is an intentionally unimplemented signature that MUST be satisfied by an implementation elsewhere.

Applicability:

1. `Prototype` MAY be applied to function and method declarations.
2. Applying `Prototype` to any non-function declaration is ill-formed.

Constraints:

1. A `Prototype` function MUST be an abstract signature (its function body MUST be `;`).
2. A `Prototype` function MUST NOT contain a body.
3. A function that is a `Prototype` is permitted at module scope, even though abstract signatures are otherwise forbidden there (Section 5.4.1.2).

Satisfaction rule:

1. For each `Prototype` function `P`, there MUST exist exactly one function definition `I` such that:
   1. `I` is in the same declaring scope as `P` (same module scope, or same declaring type).
   2. `I` has the same identity as `P` (Section 5.4.2).
   3. `I` is annotated with `#Trait Implementation`.
2. If no such `I` exists, the program is ill-formed.
3. If more than one such `I` exists, the program is ill-formed.

##### 5.8.9.2 `Implementation`

`#Trait Implementation` declares that the annotated definition satisfies a corresponding `Prototype`.

Applicability:

1. `Implementation` MAY be applied to function and method definitions.
2. Applying `Implementation` to any declaration without a body is ill-formed.

Constraints:

1. There MUST exist a corresponding `Prototype` in the same declaring scope with the same identity.
2. An `Implementation` MUST satisfy the `Prototype`’s signature exactly, including return type and `maybe` clause.

##### 5.8.9.3 `Deprecated(since: string, remove?: string, message?: string)`

`#Trait Deprecated(...)` marks a declaration as deprecated.

Arguments:

1. `since` is REQUIRED and MUST be a string literal.
2. `remove` is OPTIONAL and MUST be a string literal when present.
3. `message` is OPTIONAL and MUST be a string literal when present.

Semantics:

1. Referencing a deprecated declaration SHOULD produce a warning diagnostic.
2. The diagnostic SHOULD include:
   1. The `since` version.
   2. The `remove` version if present.
   3. The `message` if present.
3. Deprecation does not change overload identity, typing, or code generation.

##### 5.8.9.4 `Override`

`#Trait Override` declares that a method overrides a member from a base type.

Applicability:

1. `Override` MAY be applied only to instance methods.
2. Applying `Override` to a `static` function is ill-formed.

Constraints:

1. The method MUST override exactly one base member.
2. The overridden member MUST be eligible for overriding as defined by the type system (Section 9).
3. Signature compatibility is defined by Section 5.4.2.2.

##### 5.8.9.5 `Inline`

`#Trait Inline` requests inlining.

1. The compiler MAY inline the annotated function regardless of this trait.
2. The compiler SHOULD attempt to inline functions annotated with `Inline` when it does not increase code size beyond implementation-defined heuristics.
3. `Inline` MUST NOT change program semantics.

##### 5.8.9.6 `NoInline`

`#Trait NoInline` requests that a function not be inlined.

1. The compiler SHOULD respect `NoInline`.
2. The compiler MAY inline anyway only if required for correctness (for example, to satisfy ABI or calling-convention constraints defined by the implementation).

#### 5.8.10 Trait-specific required diagnostics

For the following trait errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. A `#Trait` annotation not followed by a declaration.
2. Duplicate application of the same trait to one declaration.
3. `Prototype` applied to a non-function declaration.
4. `Prototype` applied to a function with a body.
5. `Implementation` applied to a declaration without a body.
6. `Implementation` without a matching `Prototype`.
7. `Prototype` without exactly one matching `Implementation`.
8. `Deprecated` missing required argument `since`.
9. `Deprecated` with non-string argument values.
10. `Override` applied to a non-instance method.

#### 5.8.11 Trait declarations

Trait declarations introduce named trait schemas that may be referenced by `#Trait` applications.

Trait declarations are not type declarations. They do not introduce a nominal runtime type and they do not affect the single-top-level-type rule (Section 3.4.2).

##### 5.8.11.1 Syntax

```
trait-declaration          ::= visibility-modifier? 'trait' trait-identifier trait-parameter-list? trait-body
trait-identifier           ::= identifier
trait-parameter-list       ::= '(' trait-parameter (',' trait-parameter)* ')'
trait-parameter            ::= type identifier
trait-body                 ::= '{' '}'
```

##### 5.8.11.2 Placement and nesting

1. Trait declarations MAY appear only at module scope.
2. Trait declarations MUST NOT be nested inside type bodies, function bodies, or blocks.
3. If a trait declaration appears in a non-module scope, the program is ill-formed.

##### 5.8.11.3 Visibility and imports

1. A trait declaration introduces a symbol into the enclosing module.
2. Visibility modifiers govern whether other modules may reference the trait name.
3. Importing a module imports the ability to reference the trait declarations exported by that module under the same rules as other exported symbols.

##### 5.8.11.4 Trait name namespace

Trait names live in the normal declaration namespace.

1. A trait name MUST NOT conflict with another top-level declaration name in the same module.
2. If a conflict exists, the program is ill-formed.

##### 5.8.11.5 Parameters and argument mapping

Trait parameters define the permitted and required arguments when the trait is applied.

1. A trait with no parameters is a marker trait.
2. A trait parameter is **required** if its type is non-nullable.
3. A trait parameter is **optional** if its type is nullable (`T?`).
4. If an optional parameter is omitted at application sites, its value defaults to `null`.
5. Parameter names MUST be unique within the parameter list.

Argument forms at application sites:

1. For declared traits with one or more parameters, trait application MUST provide parentheses.
2. For marker traits, parentheses MAY be omitted.
3. For marker traits, empty parentheses `()` are permitted.
4. For traits with one or more parameters, omitting parentheses is ill-formed.

Edition 1.0 supports named arguments only:

1. Each supplied argument MUST be of the form `name = constant-expression`.
2. Positional arguments are not permitted.
3. Each argument name MUST refer to a declared parameter name.

##### 5.8.11.6 Semantic validation of declared trait applications

When applying a declared trait:

1. The trait name MUST resolve to either:
   1. A compiler-known built-in trait (Section 5.8.9), or
   2. A trait declaration visible in the current module/import environment.
2. If the trait name resolves to a declared trait:
   1. Every required parameter MUST be supplied.
   2. No unknown argument names may be supplied.
   3. Each argument expression MUST be a constant-expression.
   4. Each argument value MUST be convertible to the declared parameter type.

If a trait name does not resolve to a built-in or declared trait, the application is treated as an unknown tooling trait under Section 5.8.5.

##### 5.8.11.7 Overloading and bodies

1. Trait declarations MUST NOT be overloaded. Multiple trait declarations with the same name in the same module are ill-formed regardless of parameter lists.
2. Trait bodies are syntactically required but MUST be empty in edition 1.0.
3. Any non-empty trait body is ill-formed.

##### 5.8.11.8 Additional required diagnostics

For the following trait-declaration and application errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. A trait declaration in a non-module scope.
2. Duplicate trait declaration name within a module.
3. Duplicate parameter name within a trait parameter list.
4. Non-empty trait body.
5. Applying a declared trait with missing required arguments.
6. Applying a declared trait with an unknown argument name.
7. Applying a declared trait with an argument value that is not a constant-expression.
8. Applying a declared trait with omitted parentheses when the declared trait has one or more parameters.

#### 5.8.12 Trait name resolution

Trait name resolution determines whether a trait application refers to a built-in compiler-known trait, a declared trait symbol, or an unknown tooling trait.

Resolution MUST be deterministic and MUST occur after module/import resolution (Section 3) and before type checking of declaration bodies.

For each trait application `A` with name `N`:

1. If `N` is an unqualified name that matches a built-in trait name defined by Section 5.8.9, `A` resolves to that built-in trait.
2. Otherwise, attempt to resolve `N` as a declared trait symbol:
   1. If `N` is qualified, resolve the module path, then resolve the trait name from that module’s exported symbols.
   2. If `N` is unqualified, resolve it in the current module scope and then in imported scopes using the same deterministic import environment rules as other symbols (Section 3.3).
3. If resolution succeeds, `A` resolves to the declared trait symbol and is validated per Section 5.8.11.6.
4. If resolution fails, `A` is an unknown tooling trait and is handled per Section 5.8.5.

If a single unqualified trait name `N` could resolve to multiple declared trait symbols through imports, the program is ill-formed and the implementation MUST emit an ambiguous-trait diagnostic identifying the candidates.

## 6. Scope and Accessibility

Cloth uses lexical scoping: the textual structure of a source file determines where declarations are visible and how lifetimes are enforced. Accessibility modifiers further constrain which modules may reference a declaration. This section defines every rule governing block scope, function scope, type scope, name resolution, shadowing, and visibility.

### 6.0 Scope objects, environments, and terminology

This section describes name binding in terms of **environments** and **scopes**.

1. A **scope** is a syntactic region that introduces a name environment.
2. An **environment** is an ordered chain of scope frames consulted by name resolution.
3. A **binding** is the association of a name with a declaration and its symbol identity.
4. The binding of any name occurrence MUST be deterministic and MUST NOT depend on file traversal order, hash iteration order, or concurrency.

When this section uses the notation `Resolve(E, name)`, `E` denotes an environment chain and `Resolve` denotes the deterministic algorithm defined in Section 6.2.

### 6.1 Scope Model

#### 6.1.1 Lexical Principle

1. Scopes are established solely by syntax. There is no dynamic scope or implicit global lookup.
2. Entering a new lexical scope creates a fresh symbol table layered on top of the outer scope.
3. Leaving a scope destroys all owned values declared within it (subject to ownership transfers) and invalidates all borrows that target those values.

#### 6.1.1.1 Scope boundaries and declaration points

1. Every declaration has a **declaration point**, which is the source position of the first token that introduces the declared name.
2. Except where a rule explicitly permits otherwise, a declaration is visible only after its declaration point.
3. “Forward reference” means any name occurrence that is resolved to a declaration whose declaration point occurs later in the same scope frame.

#### 6.1.2 Block Scope

1. Every block `{ ... }` introduces a scope for locals, labels, and nested declarations.
2. A declaration is visible from its declaration point to the end of the block. Forward references to declarations later in the same block are illegal unless explicitly permitted (no hoisting).
3. Control-flow constructs (`if`, `for`, `while`, `switch`, `match`, `catch`, `finally`) implicitly form blocks. Conditions MUST be parenthesized. Tooling SHOULD enforce braces even for single-statement bodies to avoid ambiguity.
4. Lifetime behavior:
   - Owned locals are destroyed when the block exits unless ownership is moved out of the block.
   - Borrows become invalid when the referenced object leaves scope; compilers MUST diagnose potential dangling references.
   - Shared locals release their handles when the block terminates.
5. Variables declared in loop initialization clauses belong to the loop scope and are inaccessible outside the loop body.

#### 6.1.2.1 Block-local name uniqueness

1. Within a single block scope frame, a local declaration name MUST NOT be redeclared.
2. A later nested block MAY declare the same name (shadowing), subject to Section 6.3.

#### 6.1.3 Function Scope

1. Function scope encompasses parameters, the function body, nested local declarations, and nested functions/lambdas.
2. Parameters are in scope throughout the entire body. Default parameter expressions evaluate in the caller's context but may reference only earlier parameters.
3. Instance methods implicitly introduce `this` (owned for classes, borrowed for structs unless modified by `mutating`). Static methods do not have implicit receivers.
4. Captures obey Section 5: capturing an owned value moves it into the closure unless the capture explicitly borrows; capturing by reference borrows; capturing shared handles copies the handle. Captures that would outlive their source MUST be rejected.
5. Return statements may reference any identifier in function scope provided lifetime rules are satisfied.
6. Exception handlers (`catch`, `finally`) nest inside function scope but also create their own block scopes.

#### 6.1.3.1 Parameter scope and default expressions

1. Parameter names MUST be unique within a parameter list.
2. Parameter bindings are introduced in left-to-right order.
3. A default parameter expression is resolved in an environment containing:
   1. The module and import environment of the call site.
   2. Earlier parameters.
4. A default parameter expression MUST NOT reference:
   1. Later parameters.
   2. Locals inside the callee.
   3. The callee’s `this`.

#### 6.1.4 Type Scope

1. Each type creates a member scope containing its fields, methods, properties, constants, constructors, destructors, and nested types.
2. Members are visible throughout the entire type body. Field initializers may reference only fields declared earlier in the same type.
3. Nested types inherit access to the enclosing type's `private` members but remain independent nominal types with their own scopes.
4. Type scope is sealed: members do not automatically leak into the enclosing module or into instances. Access always requires qualification (`instance.member` or `Type.member`).

#### 6.1.4.1 Member declaration points

1. For the purpose of member lookup, all members are considered declared for the entirety of the type body.
2. For the purpose of initialization correctness:
   1. Field and instance constant initializers are evaluated in textual order.
   2. A field initializer MUST NOT reference a field or instance constant declared later in the same type body (Sections 5.3.3.1 and 5.6.1.2).

### 6.2 Name Resolution

Name resolution binds every identifier occurrence to exactly one declaration, or produces an error.

#### 6.2.1 Resolution phases

Implementations MUST perform name resolution in a deterministic sequence.

1. Construct module environments and imports (Section 3.3).
2. Bind top-level type declarations and trait declarations.
3. Bind member declarations within each type.
4. Bind function-local declarations while walking function bodies.

#### 6.2.2 Unqualified identifier resolution

Given an environment `E` at a source position, resolution proceeds from innermost to outermost scope frames.

The search order for an unqualified identifier `name` is:

1. Current block scope (innermost).
2. Enclosing blocks up to function scope.
3. Function parameters.
4. Implicit receiver `this` (if present).
5. Enclosing type member scope (if inside a type).
6. Enclosing module scope.
7. Imported symbols.
8. Built-in prelude names (primitive types and other specification-defined globals).

Resolution rules:

1. The first scope frame in the search order that contains a binding for `name` determines the binding.
2. If the selected scope frame contains multiple candidates for `name`, the occurrence is ill-formed.
3. If no binding exists in any frame, the occurrence is ill-formed.

#### 6.2.3 Qualified name resolution

Qualified forms bypass portions of the unqualified search order.

1. `modulePath.symbol` resolves `modulePath` as a module (Section 3) and then resolves `symbol` in that module’s exported scope.
2. `TypeName.member` resolves `TypeName` as a type name in the current environment and resolves `member` in the type’s member scope.
3. `expr.member` resolves `expr` as an expression and resolves `member` in the static type of `expr`.

If the leading component is ill-formed or ambiguous, the qualified name is ill-formed.

#### 6.2.4 Imported name conflicts

1. If two imports introduce the same unqualified name into the same module environment, the program is ill-formed unless the author disambiguates via renaming (Section 3.3.7).
2. An imported name MUST NOT shadow a declaration in the module scope or any nested scope.

### 6.3 Shadowing

Shadowing is the introduction of a binding in an inner scope that has the same name as a binding in an outer scope.

1. Local declarations MAY shadow outer local declarations.
2. A local declaration MUST NOT shadow a parameter binding.
3. A parameter binding MUST NOT shadow a type member name.
4. A local declaration inside a method MUST NOT shadow a member of the enclosing type.
5. A nested type declaration MUST NOT shadow a member name in the same type body.
6. Shadowing never changes accessibility: the shadowed declaration retains its own visibility rules.

### 6.4 Visibility and Accessibility

Visibility modifiers determine the set of contexts from which a declaration may be referenced after name resolution selects it.

#### 6.4.1 Visibility lattice

Visibility levels form a partial order:

`private` <= `internal` <= `public`

Where “`A <= B`” means “every context that may access `A` may also access `B`”.

#### 6.4.2 Meaning of visibility levels

1. **public**
   1. Accessible from any module.
   2. Public declarations participate in the declaring module’s export surface.
2. **internal**
   1. Accessible only within the declaring module.
   2. This is the default for top-level declarations.
3. **private**
   1. Accessible only within the declaring lexical container.
   2. For members, the container is the declaring type and its nested types.
   3. For locals, the container is the declaring block.

#### 6.4.3 Container visibility constraints

1. A nested declaration MUST NOT be more visible than its container.
   1. For a member declaration, the container is the declaring type.
   2. For a nested type, the container is the enclosing type.
   3. For a local, the container is the enclosing block.
2. If a declaration specifies a visibility that violates (1), the program is ill-formed.
3. Even if a declaration is `public`, it remains subject to scope: visibility never injects names into unrelated environments.

#### 6.4.4 Accessibility checking

1. Accessibility is checked after name resolution binds a name occurrence to a declaration.
2. If a reference violates accessibility, the program is ill-formed.
3. Diagnostics MUST identify both:
   1. The reference site.
   2. The declaration site and its visibility.

### 6.5 Required scope and accessibility diagnostics

For the following errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Use of an identifier that resolves to no declaration.
2. Ambiguous resolution of an identifier (including import conflicts).
3. Forward reference to a local declaration within the same block scope.
4. Illegal shadowing as defined by Section 6.3.
5. Accessibility violation (referencing a declaration not visible in the referencing context).
6. A declaration whose visibility is more permissive than its container.

These scoping and accessibility rules ensure that every identifier in a Cloth program has a well-defined lifetime, ownership context, and visibility boundary, enabling compilers and tools to reason about programs without ambiguity.


## 7. Expressions

Expressions produce values, references, or effects. Cloth evaluates expressions deterministically from left to right unless an operator specifies otherwise. Every expression has a static type (Section 4) and obeys the ownership semantics defined in Sections 5 and 11. This section defines expression formation, name binding within expressions, typing, evaluation order, and the ownership and lifetime effects of expression evaluation.

### 7.0 Expression model and evaluation obligations

#### 7.0.1 Expression classification

Every expression belongs to exactly one of the following evaluation result categories:

1. **Value expression**: yields an owned value of type `T`.
2. **Reference expression**: yields a borrow of type `&T`.
3. **Shared expression**: yields a shared handle of type `$T`.
4. **Void expression**: yields `void`.

The classification is derived from typing rules and is not a surface-syntax property.

#### 7.0.2 Evaluation order

1. Evaluation order is an observable part of program meaning.
2. Except where explicitly stated otherwise, evaluation proceeds left-to-right over syntactic subexpressions.
3. Implementations MUST NOT reorder side effects across expression boundaries in a way that changes observable behavior.

#### 7.0.3 Expression typing and conversions

1. Every expression `e` has a statically determined type `T` or the program is ill-formed.
2. Typing MUST be performed without executing user code.
3. Conversions are governed by Section 4.8.
4. If a construct would require an implicit conversion not permitted by Section 4.8, the program is ill-formed.

#### 7.0.4 Assignable expressions and storage locations

Some expressions denote assignable storage locations.

1. An **lvalue** is an expression that denotes a storage location that may be assigned.
2. An expression is assignable if and only if it is an lvalue and is not immutable due to `const` or other rules.
3. The set of lvalue forms is defined by the assignment rules in Section 7.3.

### 7.1 Categories

This subsection characterizes common expression forms.

1. **Value expressions** yield owned values (`T`). Ownership transfer rules apply to assignments, calls, and returns.
2. **Reference expressions** yield borrows (`&T`). Borrow validity is constrained by Section 11.
3. **Shared expressions** yield shared handles (`$T`). Handle copying and release follow shared-domain rules (Section 11).
4. **Constant expressions** are a syntactic/semantic subset that must evaluate at compile time (Section 5.3.2).
5. **Meta expressions** use `::META_KEYWORD` (Section 2.3.2) to query compile-time information.

Constant expressions and meta expressions are still expressions in the sense of this section; they are further restricted by their own governing clauses.

### 7.2 Operator Precedence and Associativity

Operators of the same precedence associate left-to-right unless noted.

1. Primary: member access, function calls, array indexing, literals, `expr :: META`.
2. Unary (right-to-left): `+`, `-`, `!`, `~`, `as`, `as?`.
3. Multiplicative: `*`, `/`, `%`.
4. Additive: `+`, `-`.
5. Bitwise AND: `&`.
6. Bitwise XOR: `^`.
7. Bitwise OR: `|`.
8. Comparison: `<`, `<=`, `>`, `>=`, `is`, `in`.
9. Equality: `==`, `!=`.
10. Logical AND: `and`.
11. Logical OR: `or`.
12. Null-coalescing (right-to-left): `??`.
13. Ternary (right-to-left): `?:`.
14. Assignment (right-to-left): `=`, `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`.

Operators not listed are reserved.

#### 7.2.1 Precedence and parse determinism

1. Parsing of expressions MUST be deterministic.
2. Operator precedence and associativity MUST be applied exactly as listed in Section 7.2.
3. If an operator token exists lexically but is not defined as an expression operator in this section, it is reserved and MUST be rejected.

#### 7.2.2 Parentheses

1. Parentheses override precedence.
2. Parentheses do not change evaluation order within the contained expression.

### 7.3 Assignment

Syntax: `target assignment-operator expression`.

#### 7.3.1 Assignment targets (lvalues)

An assignment target MUST be an lvalue. Edition 1.0 defines the following lvalue forms:

1. A local variable name.
2. A parameter name.
3. A field access expression `receiver.field`.
4. An index expression `receiver[index]` where indexing yields an assignable location.

Any other expression form used as an assignment target is ill-formed.

#### 7.3.2 Basic assignment semantics

1. Owned targets receive ownership of the right-hand side; the previous value is destroyed unless ownership has been transferred elsewhere.
2. Borrowed targets rebind to the new referent without affecting ownership.
3. Shared targets update their handles, releasing any previous handle via shared-domain rules.
4. If the target is immutable (`const` binding or otherwise), the assignment is ill-formed.

#### 7.3.3 Compound assignment

1. Compound assignments evaluate the target expression exactly once.
2. The compound operator is applied as if:
   1. The target were read once.
   2. The operator were applied.
   3. The result were assigned back to the same target.
3. If reading the target is ill-formed (for example, uninitialized), the compound assignment is ill-formed.

#### 7.3.4 Assignment expression result

1. The result of an assignment expression is the assigned value.
2. The result category (owned/borrowed/shared) matches the target’s binding category.

### 7.4 Comparison

Operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `is`, `in`.

- Equality compares primitives by value, strings by code units, references by identity, and shared handles by handle identity unless a type overrides equality via traits.
- Relational operators apply to numeric primitives and to types that opt in via comparison traits; attempting to compare unsupported types is a compile-time error.
- `is` performs runtime type checks and supports guarded bindings (`if (expr is Renderer renderer)`).
- `in` tests membership. Built-in collections rely on equality; user-defined collections may customize membership semantics.

#### 7.4.1 Comparison typing constraints

1. For `==` and `!=`, both operands MUST have the same type or be convertible to a common type under Section 4.8.
2. For relational operators, operands MUST be numeric or explicitly permitted by the type’s semantics.
3. Comparison operators yield `bool`.

### 7.5 Logical Expressions

Operators: `and`, `or`.

- Evaluation is short-circuited: `lhs and rhs` evaluates `rhs` only if `lhs` is `true`; `lhs or rhs` evaluates `rhs` only if `lhs` is `false`.
- Operands must be `bool`; no implicit conversions occur.

#### 7.5.1 Short-circuit and control flow

1. `and` and `or` introduce control-flow edges for definite assignment and other flow-sensitive analyses.
2. If `rhs` is not evaluated due to short-circuiting, its side effects do not occur.

### 7.6 Bitwise Expressions

Operators: `&`, `|`, `^`, `~`.

- Operands must be integer or `bit` types. Results use the wider operand type.
- `~` is unary and returns the same type as its operand.

#### 7.6.1 Bitwise operator typing

1. For binary bitwise operators, both operands MUST be integral types.
2. The result type is determined by numeric promotion rules when applicable; otherwise both operands must have the same type.

### 7.7 Arithmetic Expressions

Operators: `+`, `-`, `*`, `/`, `%`, unary `+`, unary `-`.

- Signed overflow is undefined behavior; unsigned arithmetic wraps modulo 2^n.
- Division by zero raises a runtime error for integers and follows IEEE 754 for floating-point (`NaN`, `+-Infinity`).
- Mixed-type arithmetic applies numeric promotions when available; otherwise an explicit cast is required.

#### 7.7.1 Arithmetic operator typing

1. Arithmetic operators require numeric operand types.
2. If operands differ in type, the program is ill-formed unless a numeric promotion exists or an explicit cast is provided.

### 7.8 Null-Coalescing

Syntax: `expr1 ?? expr2`.

- `expr1` must be nullable (`T?`). When non-null, the expression yields `expr1`; otherwise it evaluates and yields `expr2`.
- The operator is right-associative: `a ?? b ?? c` == `a ?? (b ?? c)`.
- Often paired with safe casts to provide defaults: `(value as? u32) ?? throw NegativeNumberError("negative");`.

#### 7.8.1 Typing and evaluation

1. If `expr1` has type `T?`, the result type is `T`.
2. `expr2` MUST be convertible to `T`.
3. `expr2` is evaluated only when `expr1` evaluates to `null`.

### 7.9 Ternary Operator

Syntax: `condition ? whenTrue : whenFalse`.

- `condition` must be `bool`.
- Both branches must convert to a common type.
- Only the selected branch evaluates, and ownership transfers according to the branch result.

#### 7.9.1 Common type and ownership

1. The two branches MUST be convertible to a single common result type determined statically.
2. If branch result categories differ (owned vs borrowed vs shared), the program is ill-formed unless a conversion yields a single category.

### 7.10 Lambda Expressions

Syntax:
```
(params) -> expression
(params) -> { statements }
```

Rules:

1. Parameter lists are always parenthesized, even for a single parameter.
2. Each parameter MUST declare a type and obey the ownership semantics described in Section 5.4.
3. Expression-bodied lambdas implicitly return the expression. Block-bodied lambdas MUST use explicit `return` statements.
4. Return types are inferred from the body unless the target type requires a specific signature.
5. Captures follow the same rules as other scoped captures: owned captures move ownership, borrowed captures reference existing objects, shared captures copy handles. Captures that would outlive their sources are rejected.
6. Lambdas may carry modifiers (`async`, `maybe`, etc.) consistent with function declarations.

#### 7.10.1 Lambda capture binding

1. Captured names are resolved at the lambda’s declaration point.
2. A capture that would create a borrow that outlives its source is ill-formed.

### 7.11 Cast Expressions

- `expr as TargetType` performs explicit casts (Section 4.8.1) and throws when the conversion fails.
- `expr as? TargetType` performs safe casts (Section 4.8.2) and yields `TargetType?`, returning `null` on failure.
- Casts bind tighter than multiplicative operators but looser than member access.

#### 7.11.1 Cast error behavior

1. A cast that is not permitted by Section 4.8 is ill-formed.
2. A cast that may fail at runtime MUST be expressed using the safe cast form where applicable (`as?`).

### 7.12 Call Expressions

Syntax: `callable(arguments)`.

- Evaluation order: evaluate the callable, evaluate arguments left-to-right, apply implicit conversions, then transfer ownership per parameter markers.
- Calls to functions with `maybe` clauses may signal errors; callers must handle or propagate them.
- Overload resolution occurs at compile time; unresolved ambiguities are errors.

#### 7.12.1 Callable resolution

1. The callable position MAY be:
   1. A free function name.
   2. A member access resolving to a function.
   3. A lambda expression value.
2. Overload resolution MUST be deterministic.

#### 7.12.2 `maybe` propagation obligation

If the selected callee has a `maybe` clause, the call site MUST satisfy the handling/propagation rules defined by Section 5.4.6.

### 7.13 Member Access

Syntax: `receiver.member`.

- `receiver` may be an expression, module, or type. Static members require the type name; instance members require an expression.
- Accessing nullable receivers requires prior null checks; there is no implicit safe-navigation operator.
- `::` remains reserved for selective imports and meta invocations, not general member access.

#### 7.13.1 Member access typing

1. `receiver.member` is ill-formed if the static type of `receiver` has no member named `member`.
2. If multiple members of the same name exist (for example overload sets), the member access yields an overload set that must be resolved at the call site.
3. Member access to a `private` or otherwise inaccessible member is ill-formed (Section 6.4).

### 7.14 Evaluation Order and Side Effects

1. Except where noted, Cloth evaluates expressions left-to-right.
2. Side effects occur immediately after each subexpression is evaluated. Compilers MUST NOT reorder side effects across sequence points defined by operator precedence.
3. Temporary values created during evaluation live until the end of the full expression unless ownership is moved earlier.

#### 7.14.1 Expression-required diagnostics

For the following expression errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Use of a reserved operator as an expression operator.
2. Use of a non-lvalue as an assignment target.
3. Assignment to an immutable target.
4. Ambiguous overload resolution at a call site.
5. Member access to a non-existent member.
6. Member access that violates accessibility.

These rules ensure that every expression in Cloth has predictable evaluation order, typing, and ownership behavior, enabling compilers and tools to reason about control flow and side effects without ambiguity.


## 8. Statements

Statements drive control flow, mutation, and structural composition. Unless a control-flow construct says otherwise, statements execute in source order. Every statement obeys the ownership, scope, and visibility rules in Sections 5 and 6 and inherits the lifetime guarantees summarized in Section 11.

### 8.0 Statement execution model

1. Statements execute sequentially in source order within a block.
2. Statement execution is deterministic.
3. A statement may introduce new bindings, mutate existing storage, or change control flow.
4. If statement execution triggers undefined behavior as defined elsewhere in this specification, the program is not a conforming program.

### 8.1 Categories

1. **Declaration statements** - Introduce new bindings (variables, constants, local types).
2. **Assignment statements** - Rebind existing storage locations.
3. **Expression statements** - Evaluate expressions for their side effects.
4. **Control-flow statements** - Direct execution (`if`, loops, jumps, exception handling).
5. **Block statements** - `{ ... }` groupings with their own scope.

#### 8.1.1 Statement grammar skeleton

This section specifies semantic requirements for statements. The detailed grammar for each form is defined by later subsections.

```
statement ::= declaration-statement
           | assignment-statement
           | expression-statement
           | control-flow-statement
           | block
```

Any token sequence in statement position that does not parse as one of the above forms is ill-formed.

### 8.2 Declaration Statements

#### 8.2.1 Local Variables

Local variable declarations are governed by Section 5.2.

1. Syntax is as defined by Section 5.2.
2. Local variable declarations introduce bindings into the current block scope (Section 6.1.2).
3. Definite assignment requirements apply (Section 5.2.3).
4. Ownership and destruction of locals follow Section 11.

#### 8.2.2 Constants

Local constant declarations are governed by Section 5.3.

1. A constant initializer MUST be a constant-expression (Section 5.3.2).
2. A local constant binding is immutable.

#### 8.2.3 Local Type Declarations

1. Local type declarations introduce a nested type symbol into the current block scope.
2. Local types obey the same structural constraints as module-scope types (Section 5.6), except that their visibility is limited to the declaring block.
3. Local type names MUST NOT conflict with other names in the same block scope.

### 8.3 Assignment Statements

Assignment statements apply the assignment expression semantics from Section 7.3 and discard the resulting value.

1. The target MUST be assignable (Section 7.3.1).
2. Ownership effects are as defined by Section 7.3.2.
3. Compound assignment evaluation rules are as defined by Section 7.3.3.
4. Assignment to an immutable target is ill-formed.

### 8.4 Expression Statements

An expression may appear as a statement.

1. If the expression has type `void`, the statement is well-formed.
2. If the expression has non-`void` type, the statement is ill-formed unless the result is explicitly discarded.
3. Explicit discard is written `_ = expression;`.
4. Discarding an owned value without transfer is ill-formed unless the value’s type is explicitly defined as discardable by a later section.

The discard form exists to make ownership effects explicit and to avoid silently dropping owned resources.

### 8.5 Control Flow

#### 8.5.1 Conditionals

```
if (condition) { ... } else if (condition) { ... } else { ... }
```

- `condition` must be `bool`.
- Each branch introduces its own scope.

1. `condition` MUST have type `bool`.
2. The `then` branch executes if and only if `condition` evaluates to `true`.
3. If present, the `else` branch executes if and only if `condition` evaluates to `false`.
4. Each branch introduces a block scope.
5. Definite assignment is flow-sensitive across branches (Section 5.2.3.1).

#### 8.5.2 Loops

- `while (condition) { ... }`
- `do { ... } while (condition);`
- `for (initializer; condition; iterator) { ... }`
  - Loop initializer may be a declaration or expression.
  - Loop variables belong to the loop scope and are destroyed at the end of the loop.

1. `while` evaluates its condition before each iteration.
2. `do ... while` evaluates its condition after each iteration.
3. `for` executes:
   1. The initializer (if present) once.
   2. The condition (if present) before each iteration; absence means `true`.
   3. The iterator (if present) after each iteration.
4. The loop body executes in a block scope.
5. Variables declared in a `for` initializer belong to the loop scope.
6. `break` and `continue` semantics are defined by Section 8.5.3.

#### 8.5.3 Jump Statements

- `break;` exits the nearest enclosing loop.
- `continue;` skips to the next iteration of the nearest enclosing loop.
- `return expression?;` exits the current function or lambda.
- `throw expression;` transfers control to the nearest enclosing `catch` (see 8.7).

1. `break` MUST appear within a loop body; otherwise it is ill-formed.
2. `continue` MUST appear within a loop body; otherwise it is ill-formed.
3. `return` MUST appear within a function or lambda body; otherwise it is ill-formed.
4. A `return` statement in a non-`void` function MUST provide an expression whose type is convertible to the function’s return type.
5. A `return;` statement is permitted only in a `void` function.
6. `throw` is governed by Section 8.7 and the enclosing function’s `maybe` clause (Section 5.4.6).

### 8.6 Block Statements

- Syntax: `{ statement* }`.
- Blocks create new scopes. Owned locals declared inside are destroyed in reverse order when the block exits unless moved elsewhere.

1. A block introduces a new block scope (Section 6.1.2).
2. Statements within a block execute in source order.
3. On normal exit from a block, owned locals are destroyed in reverse declaration order unless ownership has been moved out.
4. On abnormal exit (via `break`, `continue`, `return`, or `throw`), destruction still occurs for owned locals whose lifetimes end at that control-flow edge, subject to the ownership rules.

### 8.7 Exception Handling

#### 8.7.1 Throwing

- Syntax: `throw expression;`.
- The expression must evaluate to an error type allowed by the surrounding function's `maybe` clause.

1. `throw expression;` evaluates `expression` exactly once.
2. The type of `expression` MUST be one of the error types listed in the enclosing function’s `maybe` clause.
3. If the enclosing function has no `maybe` clause, `throw` is ill-formed.
4. Throwing transfers control to the nearest dynamically enclosing `catch` handler in the same call frame; if no handler exists, the error propagates to the caller.

#### 8.7.2 Handling

```
try {
    statements
} catch (ErrorType name) {
    handler
} catch (AnotherError name) {
    ...
} finally {
    cleanup
}
```

- `catch` clauses execute in order; the first matching clause handles the error.
- `finally` blocks run regardless of whether an error occurred.

1. The `try` block executes.
2. If the `try` block completes normally, no `catch` clause executes.
3. If the `try` block throws an error value `e`:
   1. The `catch` clauses are tested in source order.
   2. The first `catch (T name)` whose `T` matches the dynamic type of `e` is selected.
   3. The selected catch introduces a new block scope in which `name` is bound.
4. `finally`, if present, executes exactly once on any exit path (normal or exceptional).
5. If a `catch` clause rethrows, the rethrow is subject to the enclosing function’s `maybe` clause.

### 8.8 Call Statements

Call expressions used solely for their side effects may appear as standalone statements, subject to the expression-statement rules.

1. Evaluation order follows Section 7.12.
2. Ownership transfers follow the callee’s parameter markers (Section 5.4.3).

### 8.9 Required statement diagnostics

For the following statement errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Expression statement with non-`void` type without explicit discard.
2. Use of `break` outside a loop.
3. Use of `continue` outside a loop.
4. Use of `return` outside a function/lambda.
5. `return;` in a non-`void` function.
6. `return expr;` where `expr` is not convertible to the function return type.
7. Use of `throw` in a function without a `maybe` clause.
8. Throwing a value whose type is not listed in the enclosing function’s `maybe` clause.


## 9. Type Definitions and Behavior

Types define the structure, behavior, and lifetime semantics of Cloth programs. This section expands upon Sections 4–8 by specifying:

1. The runtime model of nominal types (`class`, `struct`, `enum`, `interface`).
2. The meaning of inheritance and interface implementation.
3. Member lookup, dispatch, and override validation.
4. Construction, initialization ordering, and destruction integration with the ownership model (Section 11).

Unless a clause explicitly permits underspecification, the rules in this section are normative.

### 9.0 Common requirements for nominal types

#### 9.0.1 Nominal identity and module ownership

1. Every nominal type has an identity determined by its declaring module and declared name (Section 5.6.0.2).
2. Type identity is stable across compilation units of the same module.
3. No construct in edition 1.0 permits reopening or partially declaring a type in multiple locations.

#### 9.0.2 Member sets and structural integrity

1. A type’s member set consists of:
   1. Its declared members.
   2. Inherited members from a base class (classes only).
   3. Required interface members (interfaces implemented by classes/structs).
2. All member binding and resolution MUST be deterministic.
3. Any member-level ambiguity that cannot be resolved by rules in this specification renders the program ill-formed.

#### 9.0.3 Type declaration modifiers

Edition 1.0 permits type declaration modifiers only where explicitly listed by the corresponding declaration form.

1. `const` MAY appear as a type declaration modifier.
2. `const` on a type declaration denotes additional constraints on inheritance and overriding, as specified by this section.
3. A `const` type declaration MUST NOT change the nominal identity of the type (Section 9.0.1).
4. A `const` class MUST NOT be used as a base class of any other class.
5. Because a `const` class cannot be used as a base class, no member declared within a `const` class may be overridden by another type.
6. Any modifier not explicitly permitted on a given declaration form is reserved and MUST be rejected.

### 9.1 Classes

#### 9.1.1 Class Structure

- Syntax:
  ```
  class-modifiers? class Name(primary-parameters?) :> BaseType? interfaces? {
      member*
  }
  ```
- Classes are reference types. Instance fields default to owned relationships unless annotated with `&` or `$`.
- Allowed members: fields, methods, properties, constructors, destructors, nested types, and constants.
- Modifiers:
  - `public`, `internal`, `private` - visibility.
  - `const` - const-qualified class declaration.
  - `abstract` - class cannot be instantiated directly; must provide abstract members for subclasses to override.
- Primary parameters initialize fields before the constructor body runs. Each primary parameter can be promoted to a field via `this.name = name;` or shorthand syntax (future extension).

##### 9.1.1.1 Class instance model

1. A class instance is a reference identity that may be compared by identity.
2. The representation of the reference (pointer, handle, fat pointer) is implementation-defined, but:
   1. It MUST be stable for the duration of the instance’s lifetime.
   2. It MUST uniquely identify the instance within the abstract machine.
3. The lifetime of a class instance is governed by ownership of the instance reference and the destruction rules in Section 11.

##### 9.1.1.2 Class field storage

1. Instance fields form part of the instance’s state.
2. Static fields belong to the static domain (Section 12).
3. Field layout in memory is implementation-defined unless explicitly fixed elsewhere; however, field initialization and destruction ordering is normative (Sections 9.8 and 11).

#### 9.1.2 Inheritance Model

- Cloth supports single inheritance using `:>`:
  ```
  class Child :> Parent { ... }
  ```
- A class may inherit from at most one concrete base class but can implement multiple interfaces (see Section 9.4).
- Constructors **MUST** invoke exactly one base constructor via `: base(arguments)`; omission defaults to the base parameterless constructor.
- Destructors run from most-derived to base after owned children are destroyed.

##### 9.1.2.1 Base type well-formedness

1. The base type of a class, if present, MUST resolve to a class type.
2. Inheritance cycles are ill-formed.
3. A class MUST NOT inherit from a `const` class.

##### 9.1.2.2 Dynamic dispatch boundary

1. Member access through a class reference performs member lookup on the static type.
2. If a selected member is subject to overriding as defined by Section 9.7 and the member is invoked dynamically, the invoked implementation is determined by the dynamic type of the receiver.
3. The mechanism (vtables, jump tables, etc.) is implementation-defined, but the observable behavior MUST match the override rules in this section.

#### 9.1.3 Prototype, Implementation, and Override Rules

- `#Trait Prototype` declares an intentionally unimplemented signature. Its semantics are defined by Section 5.8.9.1.
- `#Trait Implementation` declares that a definition satisfies a corresponding `#Trait Prototype`. Its semantics are defined by Section 5.8.9.2.
- `#Trait Override` declares that a method overrides an inherited member. Its semantics are defined by Section 5.8.9.4 and signature compatibility is defined by Section 5.4.2.2.
- If a member declaration is intended to override an inherited member, it MUST be annotated with `#Trait Override`. If a method is annotated with `#Trait Override` but no eligible base member exists, the program is ill-formed.

##### 9.1.3.1 Prototype/implementation obligations

1. `#Trait Prototype` and `#Trait Implementation` obligations apply equally to:
   1. Free functions (where permitted by Section 5.8.9.1).
   2. Member functions.
2. For member functions, the declaring scope for prototype satisfaction is the declaring type.

### 9.2 Structs

- Structs are value types stored inline. Syntax mirrors classes but omits inheritance (`struct Name { ... }`).
- Copy semantics:
  - Assigning a struct copies each field. For owned fields, the copy semantics follow the field type-if the type is not copyable, assignment is prohibited unless the struct implements a future copy trait (**OPEN ISSUE: Copy traits**).
- Structs cannot declare destructors; cleanup occurs when the struct's owning scope ends.
- Struct methods may be marked `mutating` (future feature) to indicate they modify `this`.

#### 9.2.1 Struct value model

1. A struct value is a value type.
2. Assignment of a struct performs a value copy of its fields.
3. Struct copying of owned fields is permitted only when the owned field type is copyable under the ownership rules (Section 11). If a copy would violate ownership invariants, the program is ill-formed.

#### 9.2.2 Struct receiver semantics

1. The default receiver for struct methods is borrowed (Section 5.5.2).
2. Edition 1.0 does not define a mutating receiver modifier; any spelling such as `mutating` is reserved unless explicitly defined by this specification.

### 9.3 Enums

- Enums are tagged unions with fixed cases:
  ```
  enum Result {
      Ok(i32),
      Error(NegativeNumberError)
  }
  ```
- Each case may include payloads. Payload ownership follows field rules (owned by the enum instance unless marked `&` or `$`).
- Enum values are value types; copying follows struct semantics.
- Pattern matching over enums (future section) must be exhaustive.

#### 9.3.1 Enum cases and discriminants

1. Each enum declares a finite set of cases.
2. The mapping from cases to discriminant values is implementation-defined unless a later section defines explicit discriminants.
3. Case order in source determines a canonical case ordering that MUST be preserved by tooling.

#### 9.3.2 Enum payload ownership

1. Payload values follow the same ownership rules as fields.
2. Moving an enum value moves ownership of any owned payloads.

### 9.4 Interfaces

- Interfaces declare method signatures, properties, and associated metadata without storage.
- Syntax: `interface Name { signature* }`
- Implementations:
  - Classes and structs declare `: interface1, interface2` to promise implementations.
  - Missing implementations are compile-time errors.
- Interfaces cannot contain fields. Default method bodies are not currently supported (**OPEN ISSUE: Interface default methods**).

#### 9.4.1 Interface member set

1. An interface body may declare method signatures and associated metadata.
2. An interface MUST NOT declare fields, constructors, or destructors.
3. An interface method declaration is an abstract signature (Section 5.4.1.2).

#### 9.4.2 Implementation obligation

When a class or struct declares that it implements an interface:

1. The implementing type MUST provide a corresponding implementation for every required interface member.
2. Correspondence is determined by function identity (Section 5.4.2).
3. If any required member is missing or ambiguous, the program is ill-formed.

The mechanism used for dispatch through interfaces is implementation-defined, but calls through an interface-typed reference MUST invoke the implementing type’s member as determined by correspondence above.

### 9.5 Members

#### 9.5.1 Fields

- Unannotated fields are owned by their containing type.
- `static` fields live in the static lifetime domain and obey static initialization rules (Section 9.8).
- Field initializers execute before the constructor body in declaration order.

1. Field initializers, if present, execute in textual order.
2. A field initializer MUST NOT read an instance field that is not definitely initialized at that point (Sections 5.6.1.2 and 9.8).

#### 9.5.2 Methods

- Instance methods implicitly receive `this`. The ownership of `this` depends on the declaration:
  - Regular methods receive an owned `this`.
  - Borrowed methods (future modifier) receive `&this`.

1. Method declarations are governed by Section 5.4.
2. Receiver semantics are governed by Section 5.5.
3. Edition 1.0 recognizes method modifiers only as specified by Section 5.4.1.1.

#### 9.5.3 Properties / Accessors

- Syntax:
  ```
  property Type Name {
      get { ... }
      set { ... }
  }
  ```
- `get` returns `&Type` by default to avoid implicit moves; `owned get` indicates that ownership is transferred.
- `set` receives owned values unless annotated otherwise.
- Auto-properties (future feature) are not yet defined.

1. `property` declarations are reserved unless a later section defines their full syntax and semantics.
2. Encountering `property` in edition 1.0 source is ill-formed unless the implementation explicitly supports it as a non-normative extension.

### 9.6 Member Lookup and Resolution

- Lookup order:
  1. Members declared in the current type.
  2. Members inherited from base classes (unless hidden).
  3. Interface-provided members (requires explicit implementation mapping).
- Ambiguities (e.g., two interfaces define the same signature) must be resolved using explicit implementation syntax (`impl Interface.Method { ... }` - **OPEN ISSUE: Explicit interface impls**).
- Static members are resolved via the type name (`Type.member`). Instance members require an instance expression.

#### 9.6.1 Deterministic lookup

1. Member lookup MUST be deterministic.
2. If a name resolves to multiple candidate members and no rule selects a unique target, the program is ill-formed.
3. Lookup respects accessibility (Section 6.4).

### 9.7 Shadowing and Overriding

- Declaring a member with the same name as an inherited member without `#Trait Override` hides the base member and triggers a warning.
- `#Trait Override` requires the base member be eligible for overriding as defined by Section 5.8.9.4 and Section 9.
- Shadowing within the same type (e.g., nested type defines the same member name) is disallowed.

#### 9.7.1 Override eligibility

1. A member is eligible to be overridden only if the type system defines it as overridable.
2. In edition 1.0, override eligibility beyond trait-marked override requirements is implementation-defined only where Section 5.8.9.4 delegates it.

### 9.8 Initialization Order

1. Static initialization:
   - Static fields initialize in textual order the first time the module is loaded.
   - Circular static initialization is undefined behavior (**OPEN ISSUE: Detecting static cycles**).
2. Instance initialization:
   - Base constructor runs before derived field initializers and constructor body.
   - Field initializers execute in declaration order.
   - Constructor body executes last.

#### 9.8.1 Static initialization determinism

1. Static initialization order is textual within a module.
2. If static initialization depends on a cycle, the behavior is undefined unless a later section defines cycle rejection.

### 9.9 Construction Model

#### 9.9.1 Primary Parameters

- Primary parameters on the class declaration provide a concise way to capture constructor arguments:
  ```
  public class Point(i32 x, i32 y) {
      public const i32 X = x;
      public const i32 Y = y;
  }
  ```
- Each primary parameter is available within the constructor scope.

1. Primary parameters are treated as constructor parameters for the purposes of name binding and default values.
2. Primary parameters are in scope for field initializers that occur after the parameter is introduced.

#### 9.9.2 Default Values

- Constructors may supply default parameter values:
  `public class Button(string label = "OK") { ... }`
- Defaults are evaluated at call site and must be constant expressions or references to static immutable data.

1. Default constructor parameter evaluation follows the default parameter rules (Section 5.4.4).
2. If a default argument expression is required to be constant, it MUST satisfy the constant-expression rules (Section 5.3.2).

#### 9.9.3 Factory Patterns

- Factory methods (`public static func create(...)`) encapsulate construction. They must return owned instances and may reuse cached shared objects when appropriate.
- Factories may enforce invariants before exposing instances, aligning with the deterministic destruction model.

Factories are ordinary static functions; they must obey the same ownership transfer obligations as any function returning an owned value.

### 9.10 Meta Accessors (Objects and Primitives)

- Meta keywords (`TYPEOF`, `SIZEOF`, `ALIGNOF`, etc.) may be applied to class, struct, enum, or interface types.
- For objects:
  - `MyClass::SIZEOF` returns the size of an instance including owned fields that live inline.
  - `MyClass::ALIGNOF` returns alignment requirements consistent with the target ABI.
- For primitives, meta accessors provide compile-time constants used in low-level code (e.g., buffer sizing, serialization).

### 9.11 Examples

```
public class Engine(Renderer renderer) :> Subsystem {
    private Renderer renderer = renderer;
    private $Texture sharedTexture;

    public Engine($Texture texture) :> this(new Renderer()) {
        this.sharedTexture = texture;
    }

    public func run() :> void {
        renderer.draw();
    }

    public ~Engine {
        println("Engine destroyed");
    }
}

public struct Point {
    public i32 x;
    public i32 y;
}

public enum Result {
    Ok(i32),
    Error(NegativeNumberError)
}

public interface Runnable {
    public func run() :> void;
}
```

### 9.12 Required type-system diagnostics (Section 9)

For the following type-definition errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Inheritance cycle.
2. A class inheriting from a non-class base.
3. A class inheriting from a `const` class.
4. A type claiming to implement an interface but missing at least one required member.
5. An interface declaring a field, constructor, or destructor.
6. An override marked with `#Trait Override` that has no eligible base member.


## 10. Functions and Methods

Functions and methods define reusable behavior. They bind parameter lists to executable bodies, participate in overload resolution, and transfer ownership according to the rules established in Sections 4, 5, and 11.

Unless stated otherwise, every rule in this section applies equally to:

1. Free functions declared at module scope.
2. Methods declared inside type bodies.

All function typing, overload resolution, and call binding MUST be deterministic.

### 10.1 Declaration Grammar

```
function-declaration ::= function-modifiers? 'func' Identifier '(' parameter-list? ')' return-spec maybe-clause? function-body
function-modifiers ::= visibility-modifier? storage-modifier*
return-spec ::= ':>' type | ':> void'
maybe-clause ::= 'maybe' error-type (',' error-type)*
function-body ::= block | ';' // semicolon indicates an external or abstract declaration
```

- Visibility modifiers are `public`, `internal`, and `private` (Section 6.4).
- Storage modifiers include `static` (module- or type-level) and `async`. Implementations may define additional modifiers only when this specification is amended.
- Dispatch behavior and other semantic metadata are specified via traits (Section 5.8).
- A declaration that ends with `;` and omits a body is abstract and must be satisfied by a concrete implementation elsewhere when permitted by the surrounding declaration context and by any attached traits (Sections 5.4 and 5.8).

#### 10.1.1 Declarations vs definitions

1. A function that has a block body is a **definition**.
2. A function that ends with `;` is a **declaration without a definition**.
3. A declaration without a definition is permitted only where the surrounding declaration context and attached traits permit an abstract signature (Sections 5.4.1.2 and 5.8.9.1).

### 10.2 Signatures and Identity

A function's signature consists of its fully qualified name, ordered parameter types (including ownership markers), and its `maybe` clause. Return types do not participate in signature identity. Overloads **MUST** differ in at least one of these elements, otherwise the compiler rejects the redeclaration as ambiguous.

#### 10.2.1 Function identity and overload sets

1. Every name resolves to either:
   1. A single function, or
   2. An overload set.
2. An overload set is a set of functions with the same fully qualified name.
3. A function declaration adds an element to an overload set if and only if its signature is distinct under the signature definition above.
4. If two declarations would introduce the same signature, the program is ill-formed.

### 10.3 Parameters and Ownership

- Parameter syntax mirrors declarations: `Type name`, `&Type name`, or `$Type name`.
- Owned parameters (`Type`) transfer ownership from caller to callee. The callee must either consume the value, transfer it further, or return ownership explicitly.
- Borrowed parameters (`&Type`) grant read/write access without transferring ownership. The callee **MUST NOT** store the reference beyond the lifetime of the call unless the reference targets a field of `this` or a static object guaranteed to outlive the call.
- Shared parameters (`$Type`) follow the shared-domain semantics. The callee increments the shared handle count upon entry and decrements it when the handle leaves scope.
- Default arguments are permitted. Each default expression is evaluated in the caller's context immediately before the function body executes, observing the same left-to-right order as explicit arguments.
- Cloth does not provide pass-by-reference (`var`/`inout`) parameters in this revision. Declaring such parameters is a compile-time error.

Parameters are immutable bindings. Reassigning a parameter name is forbidden; introduce a local variable instead.

#### 10.3.1 Default argument binding

1. Default arguments are bound by parameter position and name.
2. Default argument expressions are resolved and evaluated at the call site.
3. A default argument expression MUST NOT refer to locals of the callee.

### 10.4 Evaluation Order and Bodies

- Arguments are evaluated left to right. Side effects in argument expressions observe this ordering.
- The callable expression (left side of `()`) is evaluated before any argument.
- Function bodies are blocks enclosed in `{}`. A body may contain local variable declarations, nested type definitions, and nested function declarations. Nested functions obey the same rules as top-level functions but are scoped to the enclosing function.
- Execution reaches the end of the body only if every code path returns, throws via a declared `maybe` error, or diverges (e.g., loops forever). The compiler **MUST** enforce definite return: if a function declares a non-`void` return type, every control path must return a value of that type.

#### 10.4.1 Control-flow obligations

1. If a function declares a non-`void` return type, every control-flow path through the body MUST:
   1. Execute a `return` statement that returns a value convertible to the declared return type, or
   2. Exit by throwing an error permitted by the function’s `maybe` clause, or
   3. Diverge.
2. If a function declares `:> void`, reaching the end of the body is permitted.

### 10.5 Return Semantics

- Every function declares exactly one return type or `void`.
- Returning an owned value transfers ownership to the caller.
- Returning `&Type` requires proving that the referent outlives the call. For instance methods, returning `&Type` tied to `this` is permitted only when the returned reference points to a field whose lifetime is guaranteed beyond the call.
- Returning `$Type` hands the caller a shared handle whose reference count has already been adjusted.
- Cloth does not support implicit multiple return values. Use tuple return types when multiple values must be produced.

#### 10.5.1 Return conversions

1. The returned expression MUST be convertible to the declared return type under Section 4.8.
2. If the conversion requires an explicit cast and no explicit cast is present, the program is ill-formed.

### 10.6 Maybe Clauses and Error Flow

`maybe` clauses declare the set of errors that a function may signal in lieu of producing a normal return value.

- Syntax: `maybe ErrorTypeA, ErrorTypeB`.
- Errors listed in the clause propagate through `throw` statements or by rethrowing errors caught from callees.
- Attempting to throw an error not listed in the clause is a compile-time error unless the function declares `maybe any`, which explicitly opts into dynamic error sets.
- Callers must handle `maybe` functions using one of the following:
  - Propagate the clause by declaring the same error(s) in the caller's signature.
  - Wrap the invocation in `try/catch` blocks.
  - Convert to a value using expression-level constructs such as `??`, `as?`, or an explicit match.
- When a `maybe` function throws, deterministic destruction still applies: all owned locals initialized before the throw are destroyed in reverse order before the error propagates.

#### 10.6.1 `maybe any`

1. `maybe any` indicates that the function may throw any error value.
2. A caller that does not handle the call site MUST itself declare `maybe any`.
3. `maybe any` MUST NOT weaken other typing rules; it only changes the permitted error set.

### 10.7 Overloading and Resolution

- Overload resolution considers the function name, arity, parameter ownership markers, generic arguments (when defined), and the `maybe` clause.
- Ambiguity is resolved via the usual precedence: exact type match > implicit widening > user-defined conversions (where permitted). If two overloads remain viable after ranking, the compiler emits an error and requires explicit qualification.
- Overloads cannot be distinguished solely by visibility or by default parameter presence.
- When selective imports bring multiple overload sets into scope, the programmer **MUST** use fully qualified names to disambiguate.

#### 10.7.1 Deterministic overload selection

1. Overload resolution MUST be deterministic.
2. If multiple candidates remain applicable after ranking, the call is ill-formed.
3. If no candidate is applicable, the call is ill-formed.

### 10.8 Invocation Semantics

- A function call expression `callee(args...)` produces a value of the callee's return type or triggers one of its declared `maybe` errors.
- For owned parameters, argument values move into the call. The caller may not use those values afterward unless the callee returns them.
- Borrowed arguments remain valid only as long as the caller can prove the referent outlives the call. The compiler enforces this using the lifetime model.
- Shared arguments increment the handle count before invocation and decrement when the call returns, even if the call throws.
- Tail-call optimization is permitted but not required. When performed, it **MUST** preserve observable ownership semantics (no double destruction, etc.).

#### 10.8.1 Argument-to-parameter binding

1. Arguments bind to parameters by name when named arguments are used; otherwise by position.
2. An argument value is converted as required by parameter type conversion rules.
3. Ownership transfer for owned parameters is performed at the call boundary.

### 10.9 Methods and Receivers

Methods are functions declared inside types. They obey all the rules above plus the following:

- Instance methods receive an implicit receiver as defined by Section 5.5.
- Static methods lack `this` and behave like free functions namespaced inside the type.
- Methods that override inherited members MUST be annotated with `#Trait Override` (Section 5.8.9.4).
- Interface methods are dispatched through interface tables. Implementations bind each interface member explicitly; ambiguous implementations are rejected.
- Method references take two forms: `Type::method` (unbound) produces a callable that expects an explicit receiver as its first argument, while `instance::method` captures `this` and yields a zero-argument callable.

#### 10.9.1 Method reference typing

1. `Type::method` produces a callable whose first parameter is the receiver type.
2. `instance::method` captures the receiver value and produces a callable that does not require an explicit receiver argument.
3. Capturing a receiver obeys the ownership and borrowing rules; capturing an owned receiver moves it.

### 10.10 Recursion, Generics, and Async Execution

- Recursive functions are permitted. Implementations **SHOULD** detect and warn about immediately recursive functions that lack a base case when such detection is decidable.
- When generic parameters are introduced (future revision), they form part of the signature and participate in overload resolution. Until the generic system is formalized, any attempt to declare type parameters on functions is a compile-time error.
- `async` functions execute on the runtime's asynchronous scheduling facilities. An `async` function's return type is implicitly wrapped in the runtime's future/promise type (implementation-defined name) and may not mix synchronous and asynchronous return paths.

These rules ensure that functions and methods integrate cleanly with Cloth's ownership, visibility, and type systems, enabling predictable dispatch, analyzable error propagation, and deterministic resource management.


## 11. Ownership & Lifetime Reference

Ownership determines when objects are created, transferred, and destroyed.

Although the **Cloth Ownership & Lifetime Model** document remains the canonical source for low-level proofs and algorithms, this section restates the essential contract that every compiler, runtime, and program author **MUST** honor when writing or executing Cloth code.

This section defines:

1. The observable meaning of ownership transfer (moves), duplication (copies), and destruction (drops).
2. The lifetime domains and their invariants.
3. The borrowing model and its exclusivity rules.
4. Required diagnostics and undefined behavior conditions.

Unless stated otherwise, violations of the rules in this section make the program ill-formed and MUST be diagnosed.

### 11.1 Scope and Authority

1. The Ownership & Lifetime Model defines the semantics of relationship markers (`Type`, `&Type`, `$Type`) and the lifetime domains (owned, shared, static).
2. When a contradiction arises between this specification and the lifetime model, the stricter interpretation prevails. Toolchains **MUST** emit diagnostics explaining which clause wins and why.
3. Implementations that introduce extensions (e.g., new relationship markers) **MUST** document how those extensions map back to the same principles of exclusive ownership, explicit borrowing, and deterministic destruction.

#### 11.1.1 Core terms

1. A **move** transfers ownership of an owned value from one binding/location to another.
2. A **copy** duplicates a value such that both the source and result remain usable.
3. A **drop** destroys a value and releases any resources owned by it.
4. A value is **live** at a program point if it may be used without triggering undefined behavior.
5. A value is **moved-from** after a move; any use of a moved-from value is undefined behavior.

### 11.2 Lifetime Domains

- **Owned domain** - Every heap-allocated instance (class object, array, etc.) belongs to exactly one owner. The domain forms a rooted tree whose root is the entrypoint instance described in Section 12. Destroying an owner recursively destroys all children.
- **Shared domain** - Shared handles (`$Type`) reference objects outside the ownership tree. The runtime maintains reference counts or equivalent mechanisms so shared objects persist as long as at least one handle remains. Shared objects **MUST NOT** own non-shared children unless those children also live in the shared domain.
- **Static domain** - Static data (fields, constants, manifest-level singletons) exists for the lifetime of the process. Static data never changes owners and is initialized exactly once following the ordering guarantees in Section 9.8.

#### 11.2.1 Domain invariants

1. Every owned object MUST have exactly one owner at every time it exists.
2. A program MUST NOT create an ownership cycle in the owned domain.
3. Shared handles MAY participate in cycles.
4. Values in the static domain MUST be initialized exactly once and MUST remain live until process shutdown.

### 11.3 Relationship Markers

- `Type` (owned) expresses exclusive ownership. Assigning or passing such a value transfers responsibility for destruction.
- `&Type` (borrowed) creates a temporary view into an existing object. Borrowed values may alias each other but cannot outlive the object they reference.
- `$Type` (shared) represents a reference-counted or otherwise managed handle. The handle itself is a small value that may be copied freely; the underlying object persists until the last handle is released.
- `static` members exist in the static domain and never participate in ownership moves.
- Conversions between markers are explicit: `Type -> &Type` via borrowing, `Type -> $Type` via promotion into the shared domain, etc. Implicit conversions are prohibited unless defined elsewhere (e.g., Section 4.8).

#### 11.3.1 Marker-preserving operations

1. Reading from an owned location produces an owned value only when the read is defined to move; otherwise it produces a borrow.
2. Passing an owned argument to an owned parameter moves ownership at the call boundary.
3. Passing a borrowed argument to a borrowed parameter does not change ownership.
4. Copying a shared handle copies the handle value and updates the shared-domain accounting.

### 11.4 Ownership Tree

1. Each owned instance records its owner as metadata created at allocation time.
2. Ownership relationships form a tree without cycles. Attempting to introduce a cycle (e.g., object `A` owning `B` while `B` owns `A`) is a compile-time error unless both edges are promoted into the shared domain.
3. The destruction algorithm walks the tree depth-first, releasing children before their parent. Destructors (Section 9.1.4) execute after all children have been destroyed, ensuring user code observes a consistent teardown order.
4. Moving an object from one owner to another updates the tree atomically: the old parent releases the child before the new parent adopts it.

#### 11.4.1 Ownership transfer obligations

1. The compiler MUST enforce that ownership transfers are explicit and analyzable.
2. After a move, the source location becomes moved-from and MUST NOT be used.
3. A moved-from location may be reinitialized by assignment, after which it becomes live again.

### 11.5 Transfers and Moves

- **Assignments** - `owner = expression;` destroys the previous value (if any) after evaluating `expression` and before storing the new child. Self-assignment is optimized into a no-op but still performs the necessary checks to avoid double destruction.
- **Parameter passing** - Owned parameters move into the callee. Borrowed and shared parameters leave the caller's ownership tree untouched.
- **Return values** - Returning an owned value transfers it to the caller. Returning a borrow or shared handle preserves the original ownership.
- **Collections** - Containers such as arrays own their elements unless the element type itself is a reference or shared handle. Copying a container performs element-wise moves.
- **Temporaries** - Temporaries created during expression evaluation live until the end of the full expression unless moved earlier. The compiler inserts implicit drops at the end of the expression to enforce deterministic cleanup.

#### 11.5.1 Copyability

1. A type is **copyable** only if this specification or the standard library defines a copy operation that preserves ownership invariants.
2. If an operation requires copying a non-copyable owned value, the program is ill-formed.
3. Implementations MUST NOT silently substitute moves for copies or vice versa.

### 11.6 Borrowing Rules

1. A borrow may not outlive its referent. The compiler tracks scopes so that any attempt to store `&Type` beyond the lifetime of the referenced value triggers a diagnostic.
2. Multiple immutable borrows may coexist.
3. At most one **mutable borrow** (a borrow that permits mutation) may exist at a time for a given object, and it MUST be exclusive with any other borrow of that object.
3. Borrows obtained from shared handles act like immutable borrows unless the shared type provides synchronized mutation primitives.
4. Reborrowing (borrowing from an existing borrow) shortens the lifetime to the shorter of the two scopes.

#### 11.6.1 Borrow creation sites

Borrows may be created only by:

1. Explicit borrow expressions.
2. Receiver binding for methods whose receiver kind is borrowed, as defined by Section 5.5.
3. Parameter passing into a borrowed parameter.

#### 11.6.2 Escape and capture restrictions

1. A borrow MUST NOT escape the lifetime of its referent.
2. Storing a borrow into:
   1. A heap-allocated object,
   2. A static location, or
   3. A closure capture

is ill-formed unless the compiler can prove the referent outlives the storage duration of that location.

### 11.7 Shared Handles

- Creating a `$Type` increments the handle count of the target object. Destroying or letting the handle go out of scope decrements the count.
- When the count reaches zero, the shared object is destroyed immediately using the same deterministic order as owned objects.
- Shared handles may reference other shared handles, enabling cyclic graphs that would be illegal in the owned domain. Programs **MUST** rely on shared handles whenever cycles are required.
- Converting from shared to owned (`$Type -> Type`) is only legal when the caller proves it holds the sole handle (e.g., by invoking `try_unwrap`-style APIs defined in the standard library). The language itself does not provide an implicit conversion.

#### 11.7.1 Shared handle safety

1. Copying and dropping shared handles MUST update shared-domain accounting deterministically.
2. Implementations MUST guarantee that dropping the last handle triggers destruction exactly once.

### 11.8 Static Domain

- Static fields initialize exactly once before any instance of their declaring type is constructed.
- Static data cannot reference owned instances directly. To reference runtime data, a static field must store either a shared handle or a factory capable of creating fresh owned objects on demand.
- Shutting down the process triggers static destruction in reverse initialization order. Implementations **MUST** ensure no static destruction runs while user threads are still accessing the data.

#### 11.8.1 Static references

1. A borrow that refers to a static location may be treated as having static extent.
2. A borrow that refers to a non-static location MUST NOT be stored into a static binding.

### 11.9 Scope Integration

- Section 5 ties declarations to domains; Section 6 establishes lexical scopes. Together they define when destruction occurs: leaving a block destroys all owned locals declared inside it, in reverse declaration order.
- Captured variables in lambdas obey the same lifetime rules. Capturing an owned variable transfers ownership into the lambda's closure object, which in turn becomes part of the ownership tree rooted at the capturing scope.
- Exception handling (`try/catch/finally`) does not change destruction order. When control transfers out of a block prematurely, all owned values are still destroyed before the transfer completes.

#### 11.9.1 Drop order

1. Within a single lexical scope, owned locals are dropped in reverse declaration order.
2. On any control transfer that exits a scope (normal or exceptional), drops occur before the transfer completes.

### 11.10 Diagnostics and Undefined Behavior

#### 11.10.1 Required diagnostics

For the following ownership and lifetime errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. Use of a moved-from value.
2. Use of a value after it has been dropped.
3. Attempting to copy a non-copyable owned value.
4. Attempting to create an ownership cycle in the owned domain.
5. Creating overlapping borrows that violate the exclusivity rules.
6. A borrow that escapes its permitted lifetime.

#### 11.10.2 Undefined behavior

The following behaviors are undefined behavior:

1. Using an object after it has been moved.
2. Using an object after it has been dropped.
3. Data races or unsynchronized mutation through aliases, where the program violates the borrow exclusivity or synchronization requirements.

#### 11.10.3 Advisory warnings

1. Shared handles that form reference cycles without an explicit breaking strategy may leak memory.
2. Implementations MAY emit warnings when they can statically detect such patterns.

Tooling (linters, compilers, formatters) SHOULD surface ownership-related diagnostics using clause references (e.g., "violates Section 11.6.2") to keep reports actionable.

Collectively, these rules ensure that every Cloth program presents a predictable lifetime graph: ownership trees remain acyclic, shared graphs manage their own lifetimes, and static data stays isolated. By following this contract, implementations can provide deterministic destruction without garbage collection while still enabling expressive patterns such as borrowing, sharing, and factory-driven construction.


## 12. Program Execution Model

The execution model defines how compiled Cloth artifacts start, run, and terminate. It ties together module organization (Section 3), ownership semantics (Section 11), and manifest configuration (Section 13) so that every conforming runtime produces identical observable behavior in equivalent circumstances.

This section is normative for:

1. Entrypoint selection and validation.
2. Initialization sequencing, including static initialization.
3. The boundary between runtime-provided behavior and user code.
4. Shutdown ordering and error exit behavior.

Unless explicitly stated as implementation-defined, the orderings and obligations in this section MUST be preserved.

### 12.1 Objectives and Responsibilities

1. Initialization, steady-state execution, and shutdown MUST occur in a well-defined order, regardless of host platform.
2. Implementations MUST provide deterministic destruction by respecting the ownership tree rooted at the entrypoint instance.
3. Toolchains MUST surface diagnostics whenever the manifest, module graph, or code violates these rules before emitting a runnable artifact.

#### 12.1.1 Determinism requirements

1. The runtime MUST NOT depend on file system enumeration order, hash iteration order, or host thread scheduling for any semantic decision.
2. When this section allows implementation-defined behavior (for example exit codes), the implementation MUST document the choice.

### 12.2 Entrypoint Discovery

1. The build configuration supplies the canonical entry type via `[project].entry` (Section 13.2.1). When a specific target overrides the entry (Section 13.3.3), that value replaces the project-level entry only for that target.
2. If neither the project nor the target specifies an entry, the compiler searches the root module for a public class named `Main`.
3. Exactly one candidate MUST remain after applying these rules. Multiple candidates or no candidates are compile-time errors.
4. Entrypoint discovery occurs after module resolution so that fully qualified names are available and unambiguous.

#### 12.2.1 Entrypoint resolution algorithm

Given an entry specifier string `S`:

1. `S` MUST parse as a qualified type name.
2. The module path portion of `S` MUST resolve to an existing module under the import and module rules (Section 3).
3. The terminal identifier of `S` MUST resolve to a type symbol exported by that module.
4. The resolved type symbol MUST then be validated by Section 12.3.

### 12.3 Main Class Requirements

The resolved entry type, referred to as `Main`, MUST satisfy all of the following:

- Declared as a top-level `public class` (not a struct, enum, interface, or trait) with no type parameters.
- Visible to the build target under the usual visibility rules (Section 6.4).
- Non-abstract unless every abstract member is satisfied by prototypes/traits whose implementations are provided directly on `Main`.
- Contains at least one constructor accessible to the runtime (Section 12.4).

Additional constraints:

1. If `Main` declares a base class, that base class MUST be a class and MUST NOT be `const` (Section 9.1.2.1).
2. The inheritance hierarchy reachable from `Main` MUST be acyclic.
3. `Main` MUST NOT be a `const` class.

### 12.4 Entry Constructors

- Exactly one constructor is designated as the entry constructor. When the class defines multiple public constructors, the parameterless one is selected unless the manifest explicitly names another via tooling metadata (implementation-defined). If ambiguity remains, the compiler emits an error.
- The runtime guarantees only one standardized argument: `string[] args`, populated from the process command line. Constructors that require additional parameters must obtain them indirectly (e.g., via dependency injection or static factories) after instantiation.
- Entry constructors MAY declare a `maybe` clause. If the constructor throws an error listed in that clause, the runtime treats initialization as failed, destroys any partially initialized state, and exits with a non-zero status.
- Constructors MUST call exactly one base constructor before executing their own field initializers (Section 9.8). Failure to do so is ill-formed.

#### 12.4.1 Constructor selection

Given the set of constructors declared by `Main`:

1. The runtime-visible constructor set is the subset of constructors that are accessible under Section 6.4.
2. If the manifest specifies an explicit entry constructor selection, the selection mechanism is implementation-defined but MUST be deterministic and MUST uniquely identify a constructor.
3. Otherwise, if there exists exactly one parameterless runtime-visible constructor, that constructor is selected.
4. Otherwise, the program is ill-formed.

#### 12.4.2 `args` parameter binding

1. The runtime supplies the command line as a value of type `string[]`.
2. If the selected entry constructor has a single parameter of type `string[]`, that parameter is bound to the supplied `args` value.
3. If the selected entry constructor has zero parameters, `args` is not passed.
4. Any other entry constructor parameter list is ill-formed in edition 1.0.

### 12.5 Initialization Sequence

Implementations MUST execute the following phases in order. Each phase completes entirely before the next begins.

1. **Manifest preparation** - Validate the manifest, resolve targets, and collect dependency graphs (Section 13).
2. **Module loading** - Parse all source files, resolve modules, imports, and cyclic dependencies (Section 3). Emit diagnostics for insoluble cycles.
3. **Static initialization** - For each module, evaluate static field and constant initializers in textual order. Implementations MUST detect and reject static initialization cycles.
4. **Entrypoint binding** - Apply Section 12.2 to bind the `Main` class and verify the selected constructor satisfies Section 12.4.
5. **Instance construction** - Allocate the `Main` instance, supply standardized parameters, run base constructors, execute field initializers, then run the entry constructor body.
6. **Post-construction verification** - After the constructor returns successfully, the runtime treats the resulting instance as the root of the ownership tree and begins steady-state execution.

#### 12.5.1 Static initialization cycle rejection

1. If static initialization forms a dependency cycle, the program is ill-formed.
2. Implementations MUST diagnose the cycle and MUST NOT attempt to break it by choosing an arbitrary order.

### 12.6 Runtime Environment

- `string[] args` contains the exact command-line arguments passed by the hosting process. Arguments are UTF-8 encoded and immutable.
- Environment data (working directory, environment variables, clocks) is host-specific but MUST be observable through the standard library; the execution model itself does not prescribe APIs.
- Implementations MAY spawn additional threads or event loops on behalf of the program only after the entry constructor completes. Doing so earlier risks accessing partially initialized state.

#### 12.6.1 Host interaction boundary

1. The only required runtime-provided input to the program is `args`.
2. All other host interaction is mediated through the standard library or implementation-defined libraries.

### 12.7 Steady-State Execution

- Once construction finishes, control transfers entirely to user code. The runtime does not impose a main loop; programs may block inside `Main`, spawn worker tasks, or immediately return.
- Owned objects created during this phase join the ownership tree beneath `Main` or whichever owner allocates them. Shared objects behave according to Section 11.7.
- Asynchronous operations, futures, and background tasks are all part of steady state. Hosts MUST ensure that any runtime services (e.g., thread pools) remain alive until shutdown begins.

#### 12.7.1 Ownership root

1. The successfully constructed `Main` instance is the root owner for the owned domain (Section 11.2).
2. All subsequently allocated owned instances MUST be reachable from this root by following ownership edges, unless explicitly promoted into the shared domain.

### 12.8 Error Propagation and Process Exit

- When an uncaught error escapes from user code, the runtime searches outward for the nearest handler. If the error propagates all the way to `Main` and is not handled, shutdown begins immediately using the failure path described below.
- Successful completion occurs when the entry constructor returns and all foreground work finishes (typically when `Main` returns or explicitly calls a termination API). The process exits with status `0`.
- Failure completion occurs when an uncaught error escapes or the host requests termination. The runtime records the error (if available), begins deterministic destruction, and exits with a non-zero status chosen by the implementation (commonly `1`).

#### 12.8.1 Uncaught errors

1. If an error escapes the entry constructor and is not handled within it, the program terminates with failure completion.
2. If an error escapes steady-state user code and is uncaught, the runtime initiates shutdown.

### 12.9 Shutdown Semantics

Shutting down a Cloth program, whether due to success or failure, adheres to these rules:

1. Destroy owned objects in reverse ownership order: children first, parents last. Destructors run according to Section 9.1.4.
2. Shared handles decrement their reference counts. Objects whose counts reach zero during shutdown are destroyed immediately; others persist until remaining handles are released.
3. Static fields are destroyed last, in reverse order of initialization. Implementations MUST wait until all user threads terminate before tearing down static data.
4. Runtimes MUST flush buffered I/O, logs, and profiling streams before returning control to the host OS.
5. Shutdown callbacks registered via standardized APIs (e.g., `defer app::shutdown { ... }` if introduced in future revisions) execute after owned objects are destroyed but before static teardown.

#### 12.9.1 Shutdown determinism

1. Shutdown MUST be idempotent: initiating shutdown multiple times MUST NOT cause double-destruction.
2. The runtime MUST complete all mandatory drops for owned and shared handles before returning control to the host.

### 12.10 Re-entrancy and Embedding

- A single process MAY instantiate multiple Cloth runtimes, but each runtime instance MUST maintain its own ownership root and manifest context. No two runtimes may share owned objects or static state without using shared handles or explicit host mediation.
- Re-entering the same runtime (e.g., by invoking generated functions from native code) is permitted as long as the re-entry obeys ownership rules. Hosts MUST ensure they do not call back into Cloth while the runtime is in the middle of deterministic destruction.
- Embedders MUST honor the initialization and shutdown sequences described above even when the program is not launched as a standalone executable.

### 12.11 Required execution-model diagnostics

For the following execution-model errors, a conforming implementation MUST emit a diagnostic and MUST reject the program:

1. `[project].entry` does not resolve to a type.
2. The resolved entry type is not a top-level `public class`.
3. The entry type is `const`.
4. The entry type declares a base class that is not a class.
5. The entry type declares a base class that is `const`.
6. No runtime-visible entry constructor exists.
7. Entry constructor selection is ambiguous.
8. The selected entry constructor has an invalid parameter list under Section 12.4.2.
9. Static initialization contains a dependency cycle.

These guarantees ensure that every conforming Cloth program starts predictably, observes a single coherent ownership tree, and shuts down without resource leaks or order-dependent surprises. By coupling manifest-driven entrypoint resolution with deterministic destruction, the language preserves the transparency required for systems programming without imposing a garbage collector or hidden runtime services.


## 13. Build System

Conforming toolchains rely on a manifest named `build.toml` to describe every aspect of a Cloth project: identity, layout, dependencies, targets, and reproducibility guarantees. This section defines the required structure of that manifest so that different compilers, IDEs, and build services can interoperate without hidden metadata.

### 13.1 Manifest Placement and Encoding

1. `build.toml` MUST reside at the root of the workspace passed to the compiler or build driver. Relative paths inside the manifest are resolved against this directory.
2. The manifest MUST be valid TOML 1.0 encoded as UTF-8 without a byte-order mark. Parsers **MUST** reject malformed files before reading any source code.
3. When multiple manifests exist (for example, a top-level workspace plus nested packages), the path supplied via CLI or tool configuration selects the active manifest. Implementations **MUST** fail when no manifest is found rather than guessing.
4. Unknown tables or keys MAY be ignored, but tooling **MUST NOT** reinterpret standardized keys; doing so would break cross-tool reproducibility.

#### 13.1.1 Key and value normalization

1. Table names and keys are case-sensitive and MUST be interpreted exactly as written.
2. Implementations MUST treat unknown keys inside standardized tables as errors when doing so is required by later clauses (for example Section 13.3.3 profile fields).
3. All string values representing paths MUST be interpreted as UTF-8.

#### 13.1.2 Path resolution and containment

1. Any path `p` in the manifest is resolved as:
   1. If `p` is absolute, use `p`.
   2. Otherwise resolve `p` relative to the directory containing `build.toml`.
2. Implementations MUST normalize paths by resolving `.` and `..` segments.
3. Unless a clause explicitly permits it, normalized paths MUST remain within the workspace root.
4. A manifest that refers to a path that does not exist is ill-formed.

### 13.2 Required Sections

Every manifest includes `[project]` and `[build]`. Omitting either section makes the manifest invalid.

#### 13.2.1 `[project]`

The `[project]` table establishes package identity and the default entry target.

- `name` (required) - Non-empty identifier used in diagnostics, dependency graphs, and cache directories. It MUST obey the identifier grammar from Section 2.5; dots are permitted to mimic namespaces (e.g., `cloth.examples.hello`).
- `version` (required) - Semantic-version string. Changing the version MUST NOT alter compilation semantics beyond what is implied by referencing a different release.
- `entry` (required) - Fully qualified `module.path.Type` consumed by Section 12 when resolving the runtime entrypoint. No other field may contradict this value.
- Optional metadata: `edition`, `authors`, `description`, `license`, `repository`, `homepage`. These keys are informational only and MUST NOT influence compilation.
- `module_root` (optional) - Overrides the default module search root. When omitted, the compiler assumes `module_root = build.source_dir`.

Manifests MUST NOT attempt to describe the entrypoint through file-based settings (e.g., `main_file`). Any such field MUST produce a diagnostic referencing `[project].entry` as the sole source of truth.

##### 13.2.1.1 Entrypoint specifier format

1. `[project].entry` MUST be a non-empty string.
2. It MUST parse as a qualified type name as required by Section 12.2.1.
3. Toolchains MUST NOT accept file paths, relative file references, or unqualified identifiers as entrypoint specifiers.

#### 13.2.2 `[build]`

`[build]` tells the compiler where to find sources and where to place outputs.

- `source_dir` (required) - Directory scanned for modules. Implementations **MUST** auto-discover modules inside this tree; manual file enumeration is never required.
- `output_dir` (required) - Directory for build artifacts and intermediates. Toolchains MAY create subdirectories under this path but MUST keep all generated files within it unless explicitly configured otherwise.
- Optional keys:
  - `profile` (default `"debug"`)
  - `target` (default `"native"`)
  - `emit` (default `["binary"]`)
  - `artifact_dir`, `cache_dir`, `warnings_as_errors`
  - `main_file` (tooling hint only; MUST NOT participate in entrypoint selection).

All paths are interpreted relative to the manifest unless marked absolute. Paths **MUST NOT** escape the workspace root unless the user opts in via a documented allowlist.

#### 13.2.3 Build configuration determinism

1. `source_dir` discovery and module mapping MUST be deterministic.
2. Toolchains MUST NOT depend on directory enumeration order; when ordering is required, toolchains MUST sort by normalized path.

### 13.3 Optional Core Tables

Manifest authors may add optional tables to refine behavior. Each optional table is independent; omitting one simply falls back to defaults.

#### 13.3.1 `[dependencies]`

Dependencies describe additional packages required to compile the project.

- Each dependency **MUST** use an inline table `name = { ... }`; string shorthand is forbidden to preserve future extensibility.
- Exactly one source attribute is allowed per dependency:
  - `version` - Registry or package-index release expressed as a semantic version range.
  - `path` - Workspace-relative path to another manifest. Paths outside the workspace require an explicit opt-in (implementation-defined flag) and MUST point to an existing manifest.
  - `git` - Remote repository URL. Optional `rev`, `tag`, or `branch` keys may accompany `git`.
- Optional attributes:
  - `features` (array of strings) enables dependency features.
  - `optional` (boolean) marks the dependency as disabled until a feature activates it.
  - `side = "tool"` marks tooling-only dependencies that do not enter the runtime module graph.
- Version resolution MUST be deterministic. When multiple releases satisfy all ranges, the compiler selects the highest compatible version unless a lock file (Section 13.5) pins a specific revision.
- Circular dependencies are prohibited unless every edge in the cycle is marked `side = "tool"`. The compiler **MUST** report other cycles before code generation.

##### 13.3.1.1 Dependency identity

1. A dependency is identified by its manifest `[project].name` and `[project].version`.
2. A dependency key in `[dependencies]` MUST be a valid identifier (Section 2.5) and MUST be treated as the local package alias.
3. Two dependencies with different identities MUST NOT resolve to the same local alias in a single build.

##### 13.3.1.2 Deterministic version solving

1. Version solving MUST be performed over the full transitive dependency graph.
2. When multiple versions satisfy the constraints, the solver MUST select the maximal version under semantic version ordering.
3. If constraints admit no solution, the program is ill-formed.

#### 13.3.2 `[features]`

The `[features]` table gates optional code paths.

- Keys are feature names; values are arrays listing dependencies or other features to enable when the feature is active.
- The reserved feature `default` defines the feature set applied when the user does not specify `--features` explicitly.
- Activating a feature MAY pull in optional dependencies or toggle conditional compilation flags. Tooling MUST apply feature effects before dependency resolution completes so that manifests remain deterministic.

##### 13.3.2.1 Feature activation semantics

1. Feature sets are computed before version solving.
2. A feature name MUST resolve to a key in `[features]` or be rejected.
3. Activating a feature MUST activate every element listed in that feature’s array.
4. The reserved feature `default` MUST be treated as active when no explicit feature list is provided.

#### 13.3.3 `[profiles.<name>]`

Profiles customize compiler behavior without duplicating manifests.

- Every profile may override any `[build]` key. Unspecified keys inherit from `[build]`.
- Conforming toolchains MUST recognize at least `debug` (default) and `release` profiles.
- Typical fields: `optimization`, `debug_symbols`, `strip`, `incremental`, `overflow_checks`, `warnings_as_errors`.
- Introducing an unknown field inside a profile MUST trigger a diagnostic instead of silent ignore.
- Toolchains MAY expose CLI switches (e.g., `--profile release`) that override `[build].profile`.

#### 13.3.4 `[targets.<name>]`

Targets describe discrete build artifacts.

- `kind` identifies the artifact (`"executable"`, `"library"`, `"test"`, `"docs"`, etc.). Unsupported kinds MUST produce diagnostics.
- `entry` overrides `[project].entry` for that target. Executable targets MUST provide either this field or rely on the project-level entry.
- Targets may override `source_dir`, `output_dir`, `emit`, and any `[build]` key for the duration of that target's build.
- `dependencies` (inline table) declares target-specific dependencies merged into the root `[dependencies]` set before resolution.
- When multiple targets exist, build tooling MUST require the caller to specify which target to build; otherwise the default executable target derived from `[project].entry` is used.

##### 13.3.4.1 Target selection

1. If a build command specifies a target name, exactly one `[targets.<name>]` table MUST exist.
2. If no target is specified:
   1. If exactly one executable target exists, it is selected.
   2. Otherwise, the default target is an implementation-defined selection that MUST be deterministic and MUST be documented.
3. A selected executable target’s effective entrypoint is:
   1. `[targets.<name>].entry` if present, otherwise
   2. `[project].entry`.

Manifests MUST NOT define `[[units]]` or other non-standard partitioning tables. Until a future revision standardizes compilation units, toolchains rely solely on module auto-discovery guided by `[build]` and `[targets.*]`.

### 13.4 Dependency Resolution Flow

Implementations MUST follow this deterministic pipeline:

1. Parse `[dependencies]`, apply `[features]`, and filter out optional dependencies that remain inactive.
2. Expand transitive dependencies by reading their manifests recursively. Each dependency inherits the caller's active features unless it defines its own `default` set.
3. Solve version constraints to pick exactly one release per package (excluding `side = "tool"` dependencies, which may resolve separately).
4. Detect conflicts (duplicate modules, incompatible editions, etc.) and emit diagnostics before compiling any source.
5. Record the resolved graph for tooling (e.g., in `build.lock`).

#### 13.4.1 Graph canonicalization

1. The resolved dependency graph MUST have a canonical serialization.
2. Toolchains MUST order dependencies by `(package name, selected version, source kind)` when emitting lock files or build plans.

### 13.5 Reproducibility and Lock Files

- Toolchains MAY create `build.lock` (or another implementation-defined lock file) to pin exact dependency versions, git revisions, and binary artifacts.
- When a lock file is present, the compiler **MUST** honor it unless the user explicitly requests an update (e.g., `--update-lock`).
- Lock files belong to the workspace root and MUST be encoded as UTF-8 TOML for easy auditing.

#### 13.5.1 Lock file authority

1. When a lock file is present, it is the authoritative record of resolved dependency identities.
2. A toolchain MUST reject a lock file that contradicts the manifest’s dependency constraints.

### 13.6 Workspaces and Nested Packages

- A workspace is a directory containing one or more member packages, each with its own `build.toml`.
- The root manifest may declare a `[workspace]` table (implementation-defined keys such as `members = ["libs/math", "apps/viewer"]`). Members inherit shared configuration but still provide their own `[project]`/`[build]` tables.
- When building a workspace, toolchains resolve dependencies across all members simultaneously to ensure a single version of each package unless marked `side = "tool"`.
- Nested manifests detected outside the workspace membership list are ignored unless referenced via `[dependencies]`.

### 13.7 Validation and Diagnostics

- Missing required fields, conflicting entries, or unsupported optional sections MUST produce diagnostics that cite the offending key and the relevant clause in this section.
- Files referenced by the manifest (source directories, dependency paths) MUST exist. Nonexistent paths trigger errors before compilation.
- Implementations SHOULD warn when:
  - Two files declare the same module name within `source_dir`.
  - Optional dependencies are declared but never referenced by any feature.
  - Targets override `entry` with a type that does not exist.
- Diagnostics MUST be deterministic: identical manifests yield identical error ordering.

#### 13.7.1 Required diagnostics

For the following manifest errors, a conforming implementation MUST emit a diagnostic and MUST reject the build:

1. Missing `[project]` or `[build]`.
2. Missing required keys in `[project]` or `[build]`.
3. `[project].entry` that does not satisfy Section 13.2.1.1.
4. Any referenced path that does not exist.
5. A dependency entry with multiple source attributes.
6. A dependency graph cycle not permitted by Section 13.3.1.
7. A version solve failure.
8. An unknown field inside a profile table.
9. A target that specifies an unsupported `kind`.

### 13.8 Minimal Manifest Example

A project that relies solely on defaults may provide the following manifest:

```
[project]
name = "notebook"
version = "0.1.0"
entry = "app.main.Main"

[build]
source_dir = "src"
output_dir = "build"
```

Any attempt to declare multiple entrypoints (for example, conflicting `entry` values across `[project]` and `[targets.app]`) **MUST** trigger a diagnostic identifying the duplicate definitions.

These manifest rules ensure that Cloth builds remain predictable across toolchains: sources are discovered consistently, dependencies resolve deterministically, and artifacts map directly to declarative targets without hidden state.
