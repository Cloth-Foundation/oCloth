# Cloth Language Specification (Draft)

> Status: Draft / evolving  
> This document defines the normative behavior of the Cloth language.

---

## Table of Contents

1. Introduction
   1. Goals and Non-Goals
   2. Conformance Language (MUST/SHOULD/MAY)
   3. Terminology
2. Lexical Structure
   1. Source Text and Encoding
   2. Tokens
   3. Meta Tokens
   4. Comments and Whitespace
   5. Identifiers
   6. Keywords
   7. Operators and Punctuation
   8. Literals
      1. Integer Literals
      2. Floating-Point Literals
      3. Byte Literals
      4. Bit Literals
      5. Character Literals
      6. String Literals
      7. Boolean, Null, and Special Literals
      8. Future Literal Forms
3. Program Structure
   1. Parsing Model and Expectations
   2. Compilation Model (Two-Pass Overview)
   3. Modules
      1. Module Declarations
      2. Module Naming Rules
      3. Reserved Namespaces
   4. Imports
      1. Import Resolution
      2. Cyclic Dependencies
   5. Top-Level Declarations
   6. File Structure and Organization
4. Type System
   1. Overview of the Type System
   2. Primitive Types
      1. Integer Types
      2. Floating-Point Types
      3. Boolean Type
      4. String Type
   3. Composite Types
      1. Arrays
      2. Tuples
   4. Nullable Types
   5. Type Modifiers
      1. atomic
      2. Other Modifiers
   6. Type Identity and Equality
   7. Type Inference Rules
   8. Casting and Conversion
      1. Explicit Casting (as)
      2. Safe Casting
      3. Implicit Conversions
5. Declarations
   1. General Declaration Rules
   2. Variable Declarations
   3. Constant Declarations
   4. Function Declarations
   5. Type Declarations
      1. Class Declarations
      2. Struct Declarations
      3. Enum Declarations
      4. Interface Declarations
6. Scope and Accessibility
   1. Scope Rules
      1. Block Scope
      2. Function Scope
      3. Type Scope
   2. Name Resolution
   3. Shadowing Rules
   4. Visibility Modifiers
      1. public
      2. private
      3. internal
   5. Accessibility Constraints
7. Expressions
   1. Expression Categories
   2. Operator Precedence and Associativity
   3. Assignment Expressions
   4. Comparison Expressions
   5. Logical Expressions
   6. Bitwise Expressions
   7. Arithmetic Expressions
   8. Null-Coalescing / Fallback Expressions
   9. Ternary Expressions
   10. Lambda Expressions
   11. Cast Expressions
   12. Call Expressions
   13. Member Access Expressions
8. Statements
   1. Statement Categories
   2. Declaration Statements
   3. Assignment Statements
   4. Expression Statements
   5. Control Flow Statements
      1. Conditional Statements
      2. Iteration Statements
      3. Jump Statements
   6. Block Statements
   7. Exception Handling
      1. Throwing
      2. Handling
   8. Function and Method Calls as Statements
9. Type Definitions and Behavior
   1. Classes
      1. Class Structure
      2. Inheritance Model
      3. Final and Override Rules
   2. Structs
   3. Enums
   4. Interfaces
   5. Members
      1. Fields
      2. Methods
      3. Properties / Accessors
   6. Member Lookup and Resolution
   7. Shadowing and Overriding
   8. Initialization Order
   9. Construction Model
      1. Primary Parameters
      2. Default Values
      3. Factory Patterns
   10. Meta Accessors (Objects and Primitives)
   11. Examples
10. Functions and Methods
    1. Function Signature
    2. Return Types
    3. Maybe Clauses
    4. Parameter Passing
    5. Function Overloading
    6. Method Binding and Dispatch
11. Ownership and Memory Management
    1. Ownership Model Overview
    2. Object Ownership Rules
    3. Transfer of Ownership
    4. Static Lifetime Domain
    5. Deterministic Destruction
    6. Allocation Model
    7. Lifetime Rules
    8. Cycles and Limitations
    9. Interaction with static
12. Program Execution Model
    1. Entrypoint Resolution
    2. Main Class
    3. Main Constructor
    4. Initialization Flow
13. Build System
    1. build.toml Overview
    2. Project Configuration
    3. Module Resolution
    4. Dependency Management
    5. Compilation Units

## 1. Introduction

This specification defines the canonical semantics of the Cloth programming language, including its lexical grammar, static semantics, runtime behavior, and observable side-effects. It is the final authority for how a conforming Cloth implementation parses, analyzes, and executes source text. While companion guides explain how to _use_ Cloth, this document normatively states how code _must behave_ when compiled and run.

Cloth targets high-performance, object-oriented systems programming. Programs are organized around modules and classes, execute with deterministic destruction guaranteed by a hierarchical ownership model, and avoid garbage collection in favor of explicit lifetime management. Implementations are expected to map these semantics onto predictable machine code without inserting hidden runtime services beyond what is mandated here.

This draft is intentionally exhaustive. Each clause either (a) imposes requirements on compilers, static tooling, and runtime environments, or (b) describes consequences that every valid Cloth program can rely upon. Informative notes call out rationale, examples, or background context; clauses prefixed with **OPEN ISSUE** identify areas that require further clarification before the specification is finalized.

### 1.1 Goals and Non-Goals

#### Goals

- Ensure **predictable execution**: object construction, destruction, and memory reclamation MUST follow the ownership tree rooted at `Main`, enabling deterministic cleanup without garbage collection.
- Provide **maintainable large-scale structure**: modules, explicit imports, and class-based declarations SHOULD make dependencies explicit and enable tooling to reason about codebases at build time.
- Preserve **low-level control**: value representations, calling conventions, and side-effects SHOULD remain visible to implementers so that generated code can integrate with other systems languages and operating system APIs.
- Deliver **strong compile-time guarantees**: type checking, visibility rules, and `maybe`-annotated failure paths MUST be enforced before execution to minimize runtime surprises.
- Support **tooling interoperability**: error messages, diagnostics, and symbol metadata SHOULD be precise enough for debuggers, linters, and IDEs to consume without re-implementing language semantics.

#### Non-Goals

- Defining the entire standard library. Only language constructs required to compile and execute Cloth code are specified here; library APIs are documented separately.
- Mandating a specific compiler architecture, optimizer pipeline, or intermediate representation. Implementations MAY innovate internally provided externally observable behavior matches this specification.
- Specifying platform packaging, installer workflows, or project layout conventions. Those remain out of scope for the core language.
- Providing dynamic code loading, runtime reflection, or just-in-time compilation semantics. Such features are currently undefined; programs must not rely on them until an extension is standardized.
- Exhaustively describing concurrency or parallel execution guarantees. **OPEN ISSUE:** the synchronization model will be captured in a later draft once the ownership rules for threads have been validated.

### 1.2 Conformance Language (MUST/SHOULD/MAY)

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119). These keywords describe requirements placed on:

1. **Implementations** — compilers, linkers, analyzers, and runtime environments that accept Cloth source text.
2. **Programs** — any sequence of Cloth source files forming a module or whole application.
3. **Program authors** — obligations that well-formed source text must satisfy to be considered valid.

Statements without these keywords are informative. When ambiguous, normative text takes precedence over examples or notes. If two normative clauses appear to conflict, the more restrictive requirement wins unless an **OPEN ISSUE** explicitly delays resolution.

### 1.3 Terminology

- **Implementation** — a toolchain component that ingests Cloth source text and produces diagnostics, object code, or executable artifacts. Unless stated otherwise, "implementation" implies a fully conforming compiler.
- **Program** — the transitive closure of modules reachable from the declared entry module that will be evaluated starting at `Main`'s construction.
- **Module** — the top-level namespace unit introduced by the `module` declaration; it defines the compilation scope for imports, visibility, and symbol resolution.
- **Type Declaration** — any top-level construct that introduces a class, interface, struct, enum, function, or other type-like entity (future sections define the precise set). Types are the unit of visibility and, by default, own their members.
- **Instance** — a runtime allocation created by executing a constructor; every instance participates in exactly one ownership tree rooted at the entry-point instance of `Main`.
- **Static Member** — a declaration marked `static`, existing in the root lifetime domain and therefore not owned by any instance.
- **Ownership Tree** — the hierarchy produced when objects create or contain other objects; destruction walks this tree from leaves to root, ensuring deterministic cleanup.
- **Diagnostic** — any message an implementation emits to report success, failure, warnings, or informational details. Diagnostics MUST identify the relevant source span whenever possible.
- **Undefined Behavior (UB)** — program constructs for which this specification imposes no requirements on the implementation. Programs MUST avoid UB to be considered conforming.
- **Reserved** — syntax or keywords that are unavailable to user programs in this revision but may be specified later. Implementations MUST reject use of reserved constructs.

Additional terminology specific to ownership, concurrency, and type inference will be introduced in later sections where the concepts first become normative.

## 2. Lexical Structure

Lexical analysis converts normalized source text into a stream of tokens consumed by the parser. This stage is purely syntactic: it is not allowed to perform name lookup, type checking, or macro expansion. Unless explicitly stated, all rules in this section apply uniformly to module headers, declarations, expressions, and embedded snippets such as attribute arguments.

### 2.1 Source Text and Encoding

#### 2.1.1 Encoding Requirements

- Source files **MUST** be encoded as UTF-8. Implementations **MUST** accept UTF-8 sequences without a byte-order mark (BOM) and **MAY** accept BOM-prefixed files by silently discarding the BOM before lexing.
- Any byte sequence that is not well-formed UTF-8 is ill-formed source text; implementations **MUST** issue a diagnostic and **MUST NOT** continue with implicit replacement characters.
- The logical source text is defined as the sequence of Unicode scalar values produced after decoding. Toolchains operating on other encodings (for example editors saving in UTF-16) **MUST** transcode to UTF-8 before invoking a Cloth compiler.

#### 2.1.2 Line Terminators and Normalization

- The line terminator set consists of LF (`U+000A`), CR (`U+000D`), and the two-character sequence CR LF. During decoding the implementation **MUST** normalize every CR LF pair to a single LF token and **MAY** normalize lone CR characters to LF for internal bookkeeping. Other Unicode line separators (e.g., `U+2028`) are not currently recognized; encountering them outside of string literals is **undefined behavior** until §7 clarifies the Unicode profile (**OPEN ISSUE**).
- The logical line number counter increments after each LF produced by normalization. Column numbers reset to `1` immediately after incrementing the line number.

#### 2.1.3 Permitted Control Characters

- Horizontal tab (`U+0009`), carriage return, line feed, and space (`U+0020`) are the only control characters recognized by the lexer outside of string literals. Vertical tab, form feed, NUL, and other C0 controls are **forbidden** and **MUST** trigger diagnostics identifying the offending code point.
- Non-ASCII Unicode scalars (e.g., emoji) are currently **not** permitted in identifiers or operators. They may appear only inside string literals. Extending the identifier grammar to the Unicode `XID_Start`/`XID_Continue` sets is tracked as **OPEN ISSUE: Unicode Identifiers**.

#### 2.1.4 File Boundaries and Concatenation

- Each physical file constitutes an independent tokenization unit. The lexer **MUST** append a single `EndOfFile` meta token after consuming the last code point of the unit.
- Tooling that synthesizes source text (e.g., REPLs) **MAY** present virtual buffers; however, they **MUST** obey the same encoding and normalization rules.
- Implementations **MAY** expose command-line options that concatenate multiple files before lexing (e.g., `-cat`). When they do, concatenation occurs byte-wise before normalization so that no phantom newline is inserted between files unless one already exists.

### 2.2 Tokens

- Tokens are maximal munch units: the lexer **MUST** always select the longest lexeme that matches any valid token category at the current position. When two categories match the same length, the precedence is _Identifier → Keyword → Literal → Operator/Delimiter → Meta_ unless overridden by explicit rules below.
- Every token carries a `span` consisting of the start (inclusive) and end (exclusive) byte offsets together with line/column metadata. These coordinates allow tools to reconstruct the original lexeme losslessly.
- The core token categories are:
  1. **Identifiers** (`Identifier`) — user-defined names subject to the grammar in §2.5.
  2. **Keywords** — reserved lexemes listed in §2.6; these also reuse the identifier grammar but are reclassified after lookup in the keyword table.
  3. **Literals** — numeric and string forms described in §2.8.
  4. **Operators and punctuation** — fixed symbol sequences defined in §2.7.
  5. **Meta tokens** — either sentinels synthesized by the lexer (`EndOfFile`, recovery markers) or identifier-derived meta keywords (see §2.3) that carry semantic meaning during later compilation phases.
- Tokenization **MUST** be deterministic: repeatedly lexing identical source text produces identical token streams, including whitespace spans associated with diagnostics.

### 2.3 Meta Tokens

Cloth exposes a dedicated meta-token channel for compile-time reflection and tooling coordination. Meta tokens never participate directly in expression grammar; later compilation phases consume them to drive meta-programming semantics or to report structured diagnostics.

#### 2.3.1 End-of-file and recovery sentinels

- `EndOfFile` **MUST** be emitted after the final real token of each source unit. Its span starts and ends at the logical end position of the buffer and its lexeme is the empty string.
- Implementations **MAY** introduce additional meta tokens to support error recovery (for example, `InsertedSemicolon`). Any such token **MUST** be documented and **MUST NOT** leak beyond diagnostic contexts. The reference implementation currently emits only `EndOfFile`; the design of recovery tokens is tracked as **OPEN ISSUE: Meta Recovery Tokens**.

#### 2.3.2 Meta keywords

- Meta keywords are recognized only when two conditions hold simultaneously: (1) the identifier lexeme matches one of the following uppercase strings exactly (case-sensitive comparison) and (2) the immediately preceding non-whitespace tokens are `::` (an `OP_ColonColon`). When both conditions are satisfied the lexer emits a `Meta` token whose lexeme equals the source spelling; otherwise the same lexeme is emitted as a normal keyword token and carries no meta semantics.

| Lexeme      | Summary                                          |
|-------------|--------------------------------------------------|
| `ALIGNOF`   | Query the alignment of a type or expression.     |
| `DEFAULT`   | Request a type’s default value.                  |
| `LENGTH`    | Retrieve the length of an aggregate.             |
| `MAX`       | Query the maximum representable value.           |
| `MEMSPACE`  | Refer to an implementation-defined memory space. |
| `MIN`       | Query the minimum representable value.           |
| `SIZEOF`    | Query the size of a type or expression.          |
| `TO_BITS`   | Convert a value to its raw bit pattern.          |
| `TO_BYTES`  | Convert a value to byte form.                    |
| `TO_STRING` | Convert a value to a string representation.      |
| `TYPEOF`    | Reflect the type of an expression.               |

- Recognition is strictly uppercase. For example, `alignof` or `AlignOf` lexemes remain ordinary identifiers.
- When a listed lexeme is not immediately preceded by `::`, it behaves like any other reserved keyword: it cannot be used as an identifier and, unless additional grammar assigns meaning, it has no effect.
- These keywords remain reserved regardless of context so that tooling can highlight improper use, but the meta semantics described below apply only to the `value-or-type :: META_KEYWORD` form.

#### 2.3.3 Meta invocation syntax

- Meta tokens participate in expressions via the _meta invocation_ form:

  `meta-invocation ::= primary-expression '::' META_KEYWORD`

  where `primary-expression` may be any value expression, literal, temporary, type designator, or object reference. If the parser does not observe the exact `primary-expression :: META_KEYWORD` shape, the trailing uppercase word is treated as an ordinary keyword token and **MUST NOT** be interpreted as meta.
- The `::` sequence is the normal `OP_ColonColon` token. The parser **MUST** keep the meta keyword as a separate `Meta` token so later stages can distinguish `value::TYPEOF` from qualified identifiers.
- Each meta invocation produces a value whose type is dictated by the keyword being invoked. For example, `"Hello" :: LENGTH` evaluates to an `i32` constant with the value `5`. Future sections will define the exact return type: implementers **MUST** follow those definitions once published.
- Meta invocations are pure queries: they cannot mutate the operand and **MUST NOT** depend on hidden global state. When the operand is a compile-time constant, the result **SHOULD** be constant-folded.
- Because meta keywords are reserved, attempting to reinterpret them as identifiers (e.g., `foo::TYPEOF` where `TYPEOF` was redefined) **MUST** be rejected before semantic analysis proceeds.

### 2.4 Comments and Whitespace

- Outside of string literals, whitespace consists of the characters identified in §2.1.3. The lexer **MUST** treat any contiguous sequence of whitespace as a separator between tokens and **MUST NOT** emit whitespace tokens.
- **Line comments** begin with `//` and extend to, but do not include, the next LF or the end of the file. Line comments do not nest and may appear after other tokens on the same line.
- **Block comments** begin with `/*` and terminate at the first subsequent `*/`. They **MUST NOT** nest; encountering a second `/*` before the closing `*/` keeps the original comment open. If the end of file occurs before `*/`, the implementation **MUST** emit an unterminated-comment diagnostic whose span starts at the initial `/*`.
- The characters inside comments are ignored for all syntactic purposes but **DO** participate in line/column accounting so that diagnostics inside comments point to the correct line.
- Cloth does not yet define doc-comment syntax distinct from the above. Specialized comment markers (e.g., `///`) remain reserved for future tooling integrations (**OPEN ISSUE: Documentation Comments**).

### 2.5 Identifiers

- Identifiers are case-sensitive and follow the grammar<br>
  `identifier ::= identifier-start identifier-part*`<br>
  `identifier-start ::= 'A'..'Z' | 'a'..'z' | '_'`<br>
  `identifier-part ::= identifier-start | '0'..'9' | '$'`
- The dollar sign may appear only after the first character. It exists to unblock generated symbol names (e.g., `MyType$meta`). Human-authored code **SHOULD** avoid `$` unless interoperating with generated artifacts.
- A single underscore (`_`) is a legal identifier and typically denotes an intentionally unused binding; later sections may apply additional semantics.
- Keywords listed in §2.6 **MUST NOT** be used as identifiers. The lexer determines keyword-ness through direct lexeme comparison prior to emitting the token.
- Cloth currently restricts identifiers to ASCII per §2.1.3. Non-ASCII letters, digits beyond `0-9`, combining marks, and escape sequences inside identifiers are prohibited until Unicode identifiers are ratified (**OPEN ISSUE: Unicode Identifiers**).

### 2.6 Keywords

Keywords are reserved lexemes that always produce dedicated token kinds, even when they appear where an identifier would otherwise be expected. Cloth keywords are case-sensitive; `import` is a keyword while `Import` is an identifier. The current keyword set is grouped below for readability:

| Category                     | Lexemes                                                                                                                                                                                                                                                                                                        |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Boolean & Nullity            | `true`, `false`, `null`, `NaN`                                                                                                                                                                                                                                                                                 |
| Control flow                 | `if`, `else`, `switch`, `case`, `default`, `for`, `while`, `do`, `break`, `continue`, `yield`, `return`, `throw`, `try`, `catch`, `finally`, `defer`, `await`                                                                                                                                                  |
| Expression keywords          | `and`, `or`, `is`, `in`, `as`, `maybe`                                                                                                                                                                                                                                                                         |
| Modifiers & ownership        | `public`, `private`, `internal`, `static`, `shared`, `owned`, `const`, `var`, `get`, `set`, `async`, `atomic`                                                                                                                                                                                                  |
| Type & declaration forms     | `module`, `import`, `class`, `struct`, `enum`, `interface`, `trait`, `type`, `func`, `new`, `delete`, `this`, `super`, `bit`, `bool`, `char`, `byte`, `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `float`, `double`, `real`, `long`, `short`, `int`, `uint`, `unsigned`, `void`, `any` |
| Traits (compiler directives) | `Override`, `Implementation`, `Prototype`, `Deprecated`                                                                                                                                                                                                                                                        |

Notes:

1. Synonyms such as `int`/`i32`, `long`/`i64`, `short`/`i16`, `uint`/`u32`, and `real`/`f64` all map to the same token kinds. Implementations **MUST** treat these lexemes identically during semantic analysis.
2. The trait-related lexemes intentionally start with uppercase letters to visually distinguish directive blocks (e.g., `trait Override { ... }`). They remain reserved words even outside of trait contexts.
3. The logical negation operator is spelled `!`; there is no `not` keyword today. If a textual alternative is desired, it **MUST** be added through the keyword table (**OPEN ISSUE: `not` keyword**).

### 2.7 Operators and Punctuation

The following symbol sequences form individual tokens. The lexer **MUST** apply longest-match semantics; for example, encountering `...` yields `OP_DotDotDot`, not three consecutive `OP_Dot` tokens.

| Lexeme                           | Token                                                                                                    | Description                                |
|----------------------------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------|
| `...`                            | `OP_DotDotDot`                                                                                           | Variadic placeholder / spread operator.    |
| `..`                             | `OP_DotDot`                                                                                              | Range operator (exact semantics TBD).      |
| `::`                             | `OP_ColonColon`                                                                                          | Qualified name separator.                  |
| `:>`                             | `OP_ReturnArrow`                                                                                         | Function return type introducer.           |
| `->`                             | `OP_Arrow`                                                                                               | Lambda or flow arrow depending on context. |
| `??`                             | `OP_Fallback`                                                                                            | Null-coalescing / fallback operator.       |
| `++`, `--`                       | `OP_PlusPlus`, `OP_MinusMinus`                                                                           | Increment / decrement.                     |
| `+=`, `-=`, `*=`, `/=`, `%=`     | compound assignment operators.                                                                           |
| `==`, `!=`, `<`, `>`, `<=`, `>=` | comparison operators.                                                                                    |
| `+`, `-`, `*`, `/`, `%`          | arithmetic operators.                                                                                    |
| `&`, `                           | `, `^`, `~`                                                                                              | bitwise operators.                         |
| `!`                              | logical negation.                                                                                        |
| `.`                              | member access.                                                                                           |
| `,`                              | list separator.                                                                                          |
| `;`                              | statement terminator.                                                                                    |
| `:`                              | label / clause separator.                                                                                |
| `(` `)`                          | parentheses.                                                                                             |
| `{` `}`                          | braces.                                                                                                  |
| `[` `]`                          | brackets.                                                                                                |
| `@`                              | attribute introducer.                                                                                    |
| `#`                              | compiler directive introducer (future use).                                                              |
| `$`                              | special symbol used inside identifiers; as a standalone token it is reserved for future meta-constructs. |
| `?`                              | ternary introducer / placeholder token (semantics defined in §7).                                        |
| `` ` ``                          | template or meta binding introducer (future use).                                                        |

Any character not listed above and not part of another token category is illegal outside string literals and **MUST** raise a diagnostic.

### 2.8 Literals

#### 2.8.1 Integer Literals

- An integer literal is a sequence of digits optionally preceded by a radix prefix and optionally terminated with a single-letter type suffix.
- The supported radix prefixes are summarized below (letters are case-sensitive):

  | Prefix                | Base | Allowed digits      |
  |-----------------------|------|---------------------|
  | _none_ or `0d` / `0D` | 10   | `0-9`               |
  | `0b` / `0B`           | 2    | `0-1`               |
  | `0o` / `0O`           | 8    | `0-7`               |
  | `0x` / `0X`           | 16   | `0-9`, `a-f`, `A-F` |

  Implementations **MUST** reject digits that do not belong to the selected radix, and they **MUST** report an error when a literal mixes multiple prefixes.
- Digit separators remain reserved (**OPEN ISSUE: Digit Separators**); inserting `_` inside a literal is currently invalid.
- The optional **type suffix** is a single ASCII letter chosen from `{ b, B, i, I, l, L, u, U }` and indicates the canonical type prior to contextual conversions:

  | Suffix    | Canonical type | Notes                                                                        |
  |-----------|----------------|------------------------------------------------------------------------------|
  | `b` / `B` | `byte`         | Value **MUST** be in `[0, 255]`; see §2.8.3 for details.                      |
  | `i` / `I` | `int`          | Default when no suffix is present.                                           |
  | `l` / `L` | `long`         | Distinct semantic intent but not a different bit-width at the lexical stage. |
  | `u` / `U` | `uint`         | Marks the literal as unsigned.                                               |

  The suffix affects the literal’s _declared_ type but **does not** change its width; overload resolution and type inference may still widen or narrow the literal to match its target type. For example, `i32 x = 10i;` parses `10i` as an `int` literal whose value is `10`; assignment then widens it to `i32` during type checking.
- Lexers **SHOULD** evaluate the literal into a canonical integer value after stripping the prefix and suffix. Overflow detection still occurs during semantic analysis; if the computed value cannot fit any representable target type the implementation **MUST** emit a diagnostic.

#### 2.8.2 Floating-Point Literals

- A floating-point literal matches the grammar:<br>
  `float-literal ::= digits? '.' digits? type-suffix?` where `digits` is one or more decimal digits and `type-suffix` is described below. At least one side of the decimal point **MUST** contain digits, enabling forms such as `.5`, `123.`, and `123.456`. Exponent notation (`1.0e+3`) remains unspecified (**OPEN ISSUE: Exponent Notation**).
- Literals may optionally carry a single-letter type suffix chosen from `{ f, F, d, D }`:

  | Suffix    | Canonical type                       |
  |-----------|--------------------------------------|
  | `f` / `F` | `float` (single precision)           |
  | `d` / `D` | `double` (double precision, default) |

  Absence of a suffix defaults to `double`. As with integers, the suffix selects the literal’s canonical type but does not freeze its width; contextual conversion may widen or narrow the literal if required by the target expression.
- Because trailing-only or leading-only digits are legal, the lexer **MUST** treat `123.` and `.123` as single float literals rather than `Integer`/`OP_Dot` combinations. When neither side contains digits (i.e., a bare `.`), the token remains `OP_Dot`.
- The literal is represented as `Float(value)` where `value` is the IEEE double produced by interpreting the textual lexeme (after removing the suffix). Implementations **MUST** reject strings that their runtime cannot parse.

#### 2.8.3 Byte Literals

- A byte literal is an integer literal terminated with suffix `b` or `B`. Regardless of radix, the literal’s numeric value **MUST** be in `[0, 255]`; otherwise the implementation **MUST** issue an error.
- The canonical type of a byte literal is `byte`, defined as an unsigned 8-bit two’s-complement integer (i.e., zero-extended arithmetic). Assigning a byte literal to a wider integer implicitly zero-extends it; assigning to a narrower type is illegal unless an explicit conversion exists.
- Radix prefixes from §2.8.1 are permitted: `255b`, `0xFFb`, and `0b1111_1111b` (once separators are standardized) all denote the same value. The suffix attaches to the literal after all digits and before any whitespace or comments.
- Byte literals participate in overload resolution like other typed literals. When no context is provided they default to the `byte` type.

#### 2.8.4 Bit Literals

- A bit literal represents a single binary digit with the grammar:<br>
  `bit-literal ::= ('0' | '1') ('t' | 'T')`
- The canonical type `bit` occupies one binary digit and can convert losslessly to `bool`, `byte`, or any larger integer type. Converting from a wider type to `bit` requires explicit operators defined in §7.
- Implementations **MUST** reject any attempt to apply radix prefixes or multi-digit forms to bit literals. Only `0t`, `0T`, `1t`, or `1T` are valid spellings.

#### 2.8.5 Character Literals

- Character literals are enclosed in single quotes (`'A'`). Exactly one Unicode scalar value **MUST** appear between the quotes, either directly or via an escape sequence.
- Supported escapes mirror string literals: `\\n`, `\\r`, `\\t`, `\\\"`, `\\\\`, and `\\'`. Implementations **MAY** additionally recognize hexadecimal escapes (`\\xNN`) or Unicode escapes (`\\u{XXXX}`); expanded coverage is **OPEN ISSUE: Unicode Escape Coverage**.
- The literal’s canonical type is `char`. It promotes to `int`, `byte`, or `u32` via zero-extension of the scalar’s code point.
- Unescaped control characters prohibited by §2.1.3, stray surrogate halves, and multi-code-point grapheme clusters **MUST** be rejected.

#### 2.8.6 String Literals

- String literals are enclosed in double quotes (`"`). The closing quote **MUST** appear on the same logical line unless explicitly escaped; encountering a newline before the closing quote is currently diagnosed as `unterminated string literal`. Multiline string syntax is **OPEN ISSUE: Multiline Strings**.
- Backslash escapes supported today are `\n`, `\r`, `\t`, `\"`, and `\\`. Any other character following `\` results in that character being inserted literally; the reference implementation does not yet reject unknown escapes, but the specification treats them as reserved and **recommends** emitting diagnostics so that future escape sequences can be added without changing runtime meaning.
- Strings may contain arbitrary Unicode scalar values except unescaped control characters forbidden by §2.1.3. Implementations **MUST** track the original span so that diagnostics within strings (e.g., invalid escape) can pinpoint the problematic character.

#### 2.8.7 Boolean, Null, and Special Literals

- The lexemes `true` and `false` produce keyword tokens that participate in expression grammar as boolean literals.
- `null` denotes the absence of an object reference. Its nullability semantics are governed by §7.
- `NaN` is a keyword literal that maps to the IEEE Not-a-Number value. It is case-sensitive and **MUST** appear with capital `N`.

#### 2.8.8 Future Literal Forms

- Byte-array literals, template strings, numeric separators, exponent notation, and additional escape forms are intentionally unspecified. Each feature will describe its own lexical form before becoming part of this section. Until then, any use of such syntax **MUST** produce a diagnostic so that programs do not silently depend on unstable behavior.

## 3. Program Structure

Cloth compilation is organized around modules and predictable file layouts so that tooling, build systems, and developers can reason about codebases without scanning every file. This section introduces the structural rules that every compilation unit **MUST** satisfy.

### 3.1 Parsing Model and Expectations

- Each compilation unit follows the grammar<br>
  `compilation-unit ::= module-declaration import-section? declaration-block`
- The `module` declaration **MUST** be the first non-comment token in a file. Leading comments or whitespace are allowed; any other construct before `module` is ill-formed.
- The `import-section` consists of zero or more `import` directives. Implementations **SHOULD** require these directives to form a contiguous block; interleaving imports with declarations **SHOULD** produce a diagnostic because it obscures dependency ordering.
- Parsers **MAY** process files in any order and even in parallel, but diagnostic reporting **MUST** remain deterministic (e.g., file order followed by source span).
- Local error recovery (e.g., inserting a missing brace) is encouraged so that multiple diagnostics can be reported, yet compilers **MUST** still treat the underlying error as fatal unless the user explicitly requests otherwise.

### 3.2 Compilation Model (Two-Pass Overview)

- Conceptually the compiler performs two logical passes:
  1. **Structural pass** — parses syntax, records modules, collects declarations, and builds symbol tables without performing name binding beyond module-level references.
  2. **Semantic pass** — performs type checking, ownership validation, meta-token evaluation, and code generation using the immutable symbol tables from pass one.
- Implementations **MAY** subdivide these passes internally, but observably they **MUST** behave as if all modules and declarations were discovered before semantic analysis begins. Diagnostics from later stages **MUST** cite spans produced during the structural pass.

### 3.3 Modules

Modules act as the first-level namespace boundary and define which declarations are packaged together. Multiple files can contribute to a module; together they define the module’s public API.

#### 3.3.1 Module Declarations

- Syntax:<br>
  `module-declaration ::= 'module' module-path ';'`<br>
  `module-path ::= identifier ('.' identifier)*`
- Every compilation unit **MUST** declare exactly one module. Files lacking a module declaration or declaring more than one are invalid.
- Module segments obey the identifier grammar in §2.5. Keywords, meta keywords, and empty segments are prohibited.
- All files that share the same module path belong to the same module and **MUST** be merged before semantic analysis. Conflicting definitions are errors unless a future “partial type” feature explicitly allows them (**OPEN ISSUE: Partial type definitions**).

#### 3.3.2 Module Naming Rules

- Module names are case-sensitive. `example.net` and `Example.Net` are distinct modules even if they live in the same directory.
- The directory structure **SHOULD** mirror the module hierarchy (e.g., `cloth/net/http/Main.co` contains `module cloth.net.http;`). Tooling relies on this convention to locate files deterministically.
- Module segments **MUST** start with a letter or `_` and may include digits or `$` thereafter. Characters such as `-`, spaces, or Unicode punctuation are forbidden.
- Sharing a prefix with another module (e.g., `cloth.out` vs. `cloth.out.io`) does not imply visibility or inheritance. Access still depends on imports and visibility modifiers.

#### 3.3.3 Reserved Namespaces

- The prefixes `cloth.*`, `compiler.*`, and `std.*` are reserved for the official distribution, compiler tooling, and the standard library respectively. User code **MUST NOT** declare modules rooted at these prefixes unless explicitly authorized by project configuration.
- Platform vendors **MAY** reserve additional prefixes (e.g., `vendor.*`). Such reservations **MUST** be documented alongside the build tooling so that conflicts can be diagnosed consistently.
- Build systems **SHOULD** warn when user modules attempt to shadow a reserved namespace even if the build technically allows it; behavior would otherwise depend on link order.

### 3.4 Imports

Imports establish which external symbols are visible inside the current module. They affect compile-time name lookup only; Cloth does not perform runtime module loading.

#### 3.4.1 Import Resolution

- General syntax:<br>
  `import-directive ::= 'import' module-path ('.' identifier)* ('::{' import-list '}')? ';'`
- Plain imports expose the entire module namespace for qualified use (e.g., `import cloth.out;` allows `cloth.out.println`). Selective imports bring specific symbols into the local scope (`import cloth.out::{println};`).
- Each entry in `import-list` may be renamed via `as`: `import foo::{Thing as FooThing};`. Duplicate local names **MUST** produce a diagnostic even if they come from different modules.
- The `::` separator between the module path and brace list is mandatory for selective imports. `import cloth.out { println };` is invalid.
- During resolution the compiler verifies that the module exists, is reachable, and exports the requested symbols with sufficient visibility. Missing modules or symbols **MUST** result in errors at this stage rather than later in semantic analysis.

#### 3.4.2 Cyclic Dependencies

- Cloth permits cyclic type dependencies. Modules `A` and `B` may declare types that refer to each other so long as the declarations can be resolved during the structural pass.
- Owned object relationships **MUST** remain acyclic unless every participant resides in a shared lifetime region. Attempting to introduce an ownership cycle outside of a shared region is a compile-time error enforced by the ownership analysis.
- Import directives participate in compile-time name lookup only. They do not imply runtime loading order or ownership relationships.
- Implementations **MUST** collect and merge top-level declarations before resolving bodies so that mutually dependent modules can be analyzed consistently.
- A module import cycle is invalid only when it prevents unambiguous resolution of declarations, initialization ordering, or other compile-time requirements. When a cycle must be rejected, the compiler **SHOULD** emit a diagnostic that identifies the path.

### 3.5 Top-Level Declarations

- Only type declarations (`class`, `struct`, `interface`, `trait`, `enum`, `type` alias) may appear at the top level. Free-standing variables, statements, or expressions outside a type declaration are ill-formed.
- Top-level types default to `internal` visibility unless annotated otherwise. Member declarations inside a type default to `private`.
- Attributes, doc comments, and meta invocations that annotate a type **MUST** immediately precede the type keyword with no intervening declarations or imports.
- Multiple top-level types may appear in a single file. Their lexical order affects only forward-reference constraints described later in this specification.

### 3.6 File Structure and Organization

- Files **MUST** follow this canonical order:
  1. Optional license or tooling comments.
  2. `module` declaration.
  3. Contiguous block of `import` directives (preferably sorted lexicographically).
  4. Top-level type declarations grouped by responsibility.
- Declaring multiple modules per file, placing imports after declarations, or mixing statements with the module declaration is forbidden and **MUST** be diagnosed.
- Generated files **MUST** adhere to the same structure so that they can be compiled alongside handwritten sources without special flags.

## 4. Type System

Cloth is statically typed and nominal. Every expression has a compile-time type, and programmers must declare the types of all storage locations unless a specific inference rule applies. This section enumerates the canonical type categories and the rules that govern conversions between them.

### 4.1 Overview of the Type System

- Types are grouped into primitives, composites, nullable forms, and user-defined declarations (classes, structs, interfaces, traits, enums). User-defined types are nominal: equality depends on the fully qualified name, not structure.
- `any` is the universal reference type. Any reference type may implicitly upcast to `any`, but the reverse requires a cast.
- `void` denotes the absence of a value and may appear only as the return type of functions or as the type of `Main` constructors. Variables cannot have type `void`.
- Nullability is explicit. Non-nullable types **MUST NOT** receive `null`, and the compiler enforces checks before dereferencing nullable values.

### 4.2 Primitive Types

Primitive types have fixed binary representations. They are always available without imports and participate directly in arithmetic and logical operations.

#### 4.2.1 Integer Types

- Signed integers: `i8`, `i16`, `i32`, `i64`.
- Unsigned integers: `u8`, `u16`, `u32`, `u64`.
- Synonyms:
  - `byte` = `u8`
  - `short` = `i16`
  - `int` = `i32`
  - `long` = `i64`
  - `uint` = `u32`
  - `bit` = single-bit numeric type (logical `0` or `1`)
- All integers use two's-complement encoding. Arithmetic that leaves the destination range is **undefined behavior** until checked-arithmetic intrinsics are standardized (**OPEN ISSUE: Checked arithmetic**).
- Implicit conversions are limited to widening conversions (e.g., `i16` → `i32`). All other conversions require an explicit cast (§4.8.1).

#### 4.2.2 Floating-Point Types

- `f32` (alias `float`) follows IEEE-754 single-precision semantics.
- `f64` (aliases `double`, `real`) follows IEEE-754 double-precision semantics.
- Literal suffixes `f/F/d/D` select the canonical float type (§2.8.2). Without a suffix, literals default to `double`.
- Only `f32` → `f64` is implicitly allowed. Downcasts require explicit casts, which may round or overflow per IEEE rules.

#### 4.2.3 Boolean Type

- `bool` stores the logical values `true` and `false`. It is distinct from `bit`; automatic conversion between them is prohibited.
- Conditionals (`if`, `while`, `switch`) require `bool`. Using any other type without an explicit conversion is a compile-time error.

#### 4.2.4 String Type

- `String` represents an immutable UTF-8 sequence. Length is measured in bytes; APIs expose code-point iteration for locale-aware operations.
- String literals produce `String` instances whose storage is owned by the declaring module unless explicitly copied.
- The standard library defines concatenation, slicing, and interning semantics; the core language guarantees only immutability and UTF-8 encoding.

### 4.3 Composite Types

Composite types are derived from other types but remain first-class citizens.

#### 4.3.1 Arrays

- Syntax: `T[]`.
- Arrays are reference types that own their elements. Destroying the array destroys contained elements following the ownership tree rules.
- Length is fixed at construction. Access is bounds-checked unless the implementation provides a documented `unsafe` escape hatch.

#### 4.3.2 Tuples

- Syntax: `(T0, T1, ..., Tn)` for `n ≥ 1`.
- Tuples are value types. Equality and hashing are structural and consider each component in order.
- Tuple elements are accessed via positional selectors (`value.0`) or pattern destructuring.

### 4.4 Nullable Types

- `T?` denotes an optional value of type `T`. The value set is `{ null } ∪ { v | v ∈ T }`.
- Nullable references default to `null`; nullable value types default to the zero-initialized value of `T`.
- Converting `T?` to `T` requires an explicit null check (`??`, `if`, pattern matching). Assigning `null` to a non-nullable `T` is a compile-time error.

### 4.5 Type Modifiers

Modifiers refine how a type behaves regarding concurrency, storage, or ownership.

#### 4.5.1 `atomic`

- `atomic T` guarantees that reads and writes of `T` occur atomically with respect to other threads.
- Only types whose sizes fit the platform's native atomic widths may be marked `atomic`. Otherwise, the compiler **MUST** emit an error.
- Atomics use sequentially consistent ordering until weaker modes are standardized (**OPEN ISSUE: Memory ordering modifiers**).

#### 4.5.2 Other Modifiers

- `shared` marks instances that exist in the shared lifetime domain (§Ownership Model). Shared instances cannot own non-shared children.
- `owned` documents that a member participates in the owner's destruction order (the default for most instance fields).
- `const` prohibits mutation after initialization. The compiler **MUST** enforce this for both value and reference members.
- Additional modifiers such as `static` and future concurrency tags **MUST** be specified before use. Implementations **MUST NOT** invent modifiers without specification backing.

### 4.6 Type Identity and Equality

- Primitive types are identical if they share the same canonical name (aliases map to their canonical forms).
- User-defined types are identified by their fully qualified module path and name.
- Array types are identical when their element types are identical. Tuple types require identical arity and component types in order.
- Nullable types form distinct identities: `T? ≠ T` even when `T` admits `null`.
- Type aliases do not create new identities; they simply introduce alternate spellings.

### 4.7 Type Inference Rules

- `var` enables local inference: `var x = expr;` infers `x`'s type from `expr`. The initializer is mandatory.
- Generic inference selects type arguments that satisfy all constraints at the call site. When inference fails, the program is ill-typed and the compiler **MUST** request explicit type arguments.
- Inference is never bidirectional; usage sites do not retroactively affect declaration types.
- Public APIs **SHOULD** spell out explicit types to maintain stability across compilation units.

### 4.8 Casting and Conversion

Conversions move values between types. Unless stated otherwise, conversions occur at compile time; runtime checks are injected only when required for safety.

#### 4.8.1 Explicit Casting (`as`)

- Syntax: `expr as TargetType`.
- Used for narrowing numeric conversions, reference downcasts, and interface/class rebindings.
- If the conversion cannot be proven safe at compile time, a runtime check occurs. Failing the check throws a `CastError` (**OPEN ISSUE: precise exception name**).

#### 4.8.2 Safe Casting (`as?`)

- Syntax: `expr as? TargetType`.
- Evaluation yields `TargetType?`. If `expr` is compatible with `TargetType`, the result is the converted value (non-null). Otherwise the result is `null`; the cast never throws.
- Safe casts are typically paired with `??` to supply fallback behavior. Example:<br>
  `const u32 value = (input as? u32) ?? throw new NegativeNumberError("Negative number");`
- Implementations **MAY** desugar `as?` into `is` checks followed by conditional `as` operations, but the observable semantics **MUST** match the nullable result contract.
- Because the result is nullable, subsequent use **MUST** discharge the `null` case via `??`, pattern matching, or explicit guards before treating it as non-nullable `TargetType`.

#### 4.8.3 Implicit Conversions

- Allowed cases:
  - Numeric widening (`i8` → `i16`, `f32` → `f64`).
  - Reference upcasting along inheritance or interface implementation edges.
  - Adding nullability (`T` → `T?`).
- Any other conversion (including nullable-to-non-nullable, signed-to-unsigned, or custom user-defined conversions) **MUST** be explicit.

## 5. Declarations

Declarations introduce names, tie them to types, and establish how values participate in Cloth’s ownership and lifetime model. This section builds on §3 (structure) and §4 (type system) by specifying the rules every declaration obeys regardless of its location.

### 5.1 General Declaration Rules

- **Explicit typing** — Every declaration **MUST** state its type (or use `var` where local inference is permitted). The compiler never infers visibility, ownership domain, or modifiers from usage.
- **Storage domains** — Declarations belong to one of three domains:
  1. **Static** — Prefixed with `static`; lifetime equals the entire program and bypasses the ownership tree.
  2. **Instance** — Fields and members owned by an object; they participate in the ownership hierarchy described in the Ownership & Lifetime Model.
  3. **Local scope** — Variables declared within a block; lifetime equals the lexical scope.
- **Relationship markers** — `Type`, `&Type`, and `$Type` express owned, non-owning, and shared relationships respectively. Unless a marker appears, the declaration is owned by default.
- **Visibility defaults** — Top-level declarations default to `internal`; members default to `private`. Programmers **SHOULD** spell modifiers explicitly for public APIs.
- **Definite assignment** — A declaration is not available for use until it has been definitively assigned along all control paths. Constructors must initialize all owned fields before the instance escapes.
- **Transfer checks** — Assigning an owned value to a new owner implicitly transfers ownership. The compiler **MUST** reject assignments that would create cycles or cause two owners to reference the same owned instance simultaneously.

### 5.2 Variable Declarations

- Syntax:<br>
  `storage-modifiers? type declarator ('=' expression)? ';'`
- Storage modifiers include `static`, `shared`, `owned`, `const`, `atomic`, etc., and apply to the entire declaration list.
- Local variables declared with `var` must have an initializer so the type can be inferred. Example:<br>
  `var renderer = new Renderer(); // inferred as Renderer (owned)`
- **Owned locals** — `Renderer renderer;` allocates an owned instance whose destruction occurs when the scope exits unless ownership is transferred outward.
- **Reference locals** — `&Renderer rendererRef = this.renderer;` points to an existing object without affecting its lifetime. The compiler **MUST** ensure the reference cannot outlive the target.
- **Shared locals** — `$Texture cache = textureManager.acquire("menu");` resides in the shared lifetime domain; releasing it follows the shared-domain protocol (reference counting, handles, etc.).
- Variables declared without initializers enter an uninitialized state. Access before assignment is a compile-time error except for `shared` handles explicitly allowed to represent `null`.

### 5.3 Constant Declarations

- Syntax:<br>
  `const modifiers? type identifier '=' constant-expression ';'`
- Constants are immutable after initialization and **MUST** be initialized with compile-time evaluable expressions. When declared inside a class, they share the instance’s ownership domain unless also marked `static`.
- Constants can inhabit any storage domain:
  - `public static const i32 Version = 3;` lives in the static domain.
  - `const Renderer renderer = new Renderer();` makes an owned field that cannot be reassigned but still follows deterministic destruction.
- Referencing a non-owning or shared type in a `const` declaration freezes the binding (the reference target may still change internally if it is shared/mutable).

### 5.4 Function Declarations

- Syntax:<br>
  `function-modifiers? func name(parameter-list) :> return-type maybe clause? body`
- Parameter semantics:
  - Unmarked parameter types are owned inputs; ownership transfers into the function scope. The function **MUST** either consume or return ownership before exit.
  - `&Type` parameters borrow references; the caller retains responsibility for lifetime.
  - `$Type` parameters share handles and follow the shared domain rules.
- Return values:
  - Returning `Type` transfers ownership to the caller.
  - Returning `&Type` borrows from the callee’s state; the compiler **MUST** ensure the referenced object outlives the call.
  - Returning `$Type` yields a shared handle; lifetime is governed by the shared domain.
- Functions may declare `maybe` clauses to signal error-aware returns. All ownership guarantees still apply when a function returns via an error path.
- `static` functions reside in the module or type scope without implicit `this`. Instance methods receive `this` as an owned (`this`) or non-owning (`&this`) receiver depending on modifiers defined in §9.

### 5.5 Type Declarations

Type declarations define new nominal types and establish the ownership semantics for their members. This section focuses on the canonical forms listed in the table of contents; traits and aliases will be specified later.

- **Fields** — Unmarked object fields are owned by the containing instance. Use `&Type` for non-owning references or `$Type` for shared handles.
- **Constructors** — Must initialize all owned fields before returning. Missing initialization is a compile-time error.
- **Destructors** — Execute after owned children are destroyed (deterministic destruction per the Ownership & Lifetime Model).
- **Static members** — Live in the static domain and never participate in the ownership tree.
- **Nested types** — Inherit the enclosing type’s visibility defaults but form independent ownership domains when instantiated.

#### 5.5.1 Class Declarations

- Syntax:<br>
  `class-modifiers? class Name(primary-parameter-list?) base-clause? { member* }`
- Classes are reference types that participate in inheritance via `:>` and may implement interfaces/traits once those sections are defined.
- Ownership defaults:
  - Instance fields of type `Type` are owned by the class instance.
  - Constructors accept owned parameters unless annotated `&` or `$`.
  - Returning `this` (explicitly or implicitly) transfers ownership to the caller constructing the instance.
- Constructors must call exactly one base constructor (if a base exists) before accessing inherited fields.
- Destructors (`~Name`) run after all owned fields and base destructors complete.
- Accessors (`get`, `set`) inherit the field’s ownership semantics; a `get` on an owned field returns `&Type` unless explicitly annotated to transfer ownership.

#### 5.5.2 Struct Declarations

- Syntax mirrors classes but structs are value types stored inline.
- Copy semantics:
  - Struct assignment copies every field. If a field is owned, the copy becomes a transfer (the original field is invalidated) unless the field type explicitly permits duplication (e.g., bitwise-copyable primitives). **OPEN ISSUE: Copy traits** will formalize duplicable types.
  - Structs cannot contain `$Type` fields unless the shared handle is copyable.
- Because structs live inline, their destructors (if any) run when the containing scope releases the struct (end of local scope, owning field destruction, etc.).
- Structs cannot participate in inheritance but may implement interfaces/traits once specified.

#### 5.5.3 Enum Declarations

- Enums are nominal tagged unions with a fixed set of cases. Syntax:<br>
  `enum Name { CaseA, CaseB(ValueType), ... }`
- Cases may carry payloads. Payload ownership follows the same rules as fields: unmarked payload types are owned by the enum instance.
- Enums are value types; copying behaves like structs (payloads are duplicated or transferred depending on their types).
- Pattern matching exhaustiveness will be enforced in §7. For now, the declaration must list every case explicitly; forward declarations are not allowed.

#### 5.5.4 Interface Declarations

- Interfaces declare method signatures and property contracts without providing storage.
- Syntax:<br>
  `interface Name { signature* }`
- Interfaces do not participate directly in ownership. Methods defined by an interface adopt the ownership semantics spelled out in §5.4 when implemented by a concrete type.
- A class or struct may implement multiple interfaces. The compiler **MUST** verify that implementations satisfy every signature exactly once.
- Interfaces cannot declare fields. They may declare associated types in a future revision (**OPEN ISSUE: Interface associated types**).

These subsections ensure each type form has clear lifetime responsibilities, enabling the compiler to enforce deterministic destruction and ownership transfer consistently across the language.

## 6. Scope and Accessibility

Scope determines which declarations are visible at a given source location, while accessibility controls whether those declarations can be used outside their visibility domain. Cloth enforces lexical scoping: the textual structure of the program alone determines scope boundaries.

### 6.1 Scope Rules

Scope boundaries in Cloth are determined purely by source structure. Every identifier belongs to exactly one scope, and scopes nest lexically. The subsections below correspond directly to the table of contents items.

#### 6.1.1 Block Scope

- A block scope begins at `{` and ends at the matching `}`. Each block creates a fresh symbol table for locals, labels, and nested declarations.
- Declarations within a block are visible from their declaration point to the end of the block. Forward references to later declarations in the same block are not allowed unless the construct explicitly supports hoisting (e.g., function prototypes when introduced).
- Control-flow statements (`if`, `for`, `while`, `switch`, `match`, `catch`, `finally`) implicitly form blocks. Conditions for these constructs **MUST** be parenthesized (`if (condition)`, `while (condition)`, `for (...; condition; ...)`). Braces are required in formal documentation examples and **SHOULD** be enforced by tooling to avoid ambiguity, even for single-statement bodies.
- Lifetime behavior:
  - Owned locals (`Type name;`) are destroyed when the block exits unless ownership is moved out of the block.
  - Reference locals (`&Type`) become invalid the moment the referenced object leaves scope; the compiler **MUST** diagnose potential dangling references.
  - Shared locals (`$Type`) release their handle according to the shared-domain rules when the block terminates.
- Variables declared in initialization clauses (`for (var i = 0; ...)`) belong to the loop’s block scope and are invisible outside the loop body.

#### 6.1.2 Function Scope

- Function scope encompasses:
  1. The parameter list (including default argument expressions).
  2. The function body.
  3. Any nested declarations (local functions, lambdas, local classes) introduced inside the function.
- Parameters are in scope throughout the entire body, regardless of their textual position. Default argument expressions evaluate in the caller’s context but may only reference earlier parameters.
- Instance methods implicitly introduce `this` (owned or borrowed depending on modifiers) into function scope. Static methods do not have implicit `this`.
- Captures:
  - Lambdas or local functions may capture variables from enclosing scopes. Capturing an owned variable transfers or borrows ownership based on the capture syntax (**OPEN ISSUE: Capture modes**). Regardless, the compiler **MUST** ensure the capture cannot outlive the owned value’s scope.
- Return statements may reference any identifier in function scope subject to lifetime rules. Returning `&Type` requires proof that the referenced object outlives the caller.
- Exception handlers (`catch`, `defer`, `finally`) nest inside function scope but may introduce their own block scopes per §6.1.1.

#### 6.1.3 Type Scope

- Each type (class, struct, interface, enum, trait when defined) defines a member scope that includes:
  - Fields, properties, and constants.
  - Methods, constructors, destructors.
  - Nested types and aliases.
- Members declared inside a type are visible throughout the type body unless a specific rule restricts forward references (e.g., field initializers referencing later fields is an **OPEN ISSUE: Field initializer order**).
- Nested types inherit access to the enclosing type’s `private` members but remain separate nominal types with their own scopes.
- Type scope is sealed: members do not automatically leak into the enclosing module or into instances. Access requires qualification (`instance.member` or `Type.member` for static members).
- Partial declarations (future feature) **MUST** merge their member scopes as if they were authored in a single block, while respecting visibility and shadowing rules.

These scope definitions ensure every identifier’s lifetime and visibility are determined unambiguously by the program’s lexical layout.

### 6.2 Name Resolution

Name resolution searches scopes from innermost to outermost:

1. Current block scope.
2. Enclosing blocks up to the function scope.
3. Function parameters and implicit `this` (for instance members).
4. Type members (fields, methods, nested types).
5. Module-level declarations within the same compilation unit.
6. Imported symbols (first selective imports, then fully qualified module names).
7. Global built-ins (primitive types, meta keywords), which are always accessible.

- Qualified names (`module.symbol`, `object.member`) bypass lexical lookup for the leading component and start resolving from the specified container.
- If a name resolves to multiple candidates (e.g., through selective imports), the compiler **MUST** produce an ambiguity error and require explicit qualification.
- `this` is implicitly available inside instance members and resolves to the owning type. Static members have no implicit `this` and cannot access instance members without an explicit receiver.

### 6.3 Shadowing Rules

- Local variables may shadow names from outer block scopes, but shadowing **MUST NOT** occur across different storage domains when it would cause ownership ambiguity. For example, a local variable cannot shadow a field of the same name within the same method; the compiler **MUST** reject such redeclarations.
- Parameters may not shadow fields of the same type scope. Use `this.field` to disambiguate rather than redeclaring names.
- Type names cannot be shadowed within the same module. Attempting to declare a class `Renderer` inside a module that already contains `Renderer` is an error even if the declarations appear in different files.
- Imports cannot shadow local declarations. If an imported name conflicts with a local declaration, the import **MUST** be aliased using `as`.

### 6.4 Visibility Modifiers

Visibility specifies whether a declaration can be accessed from other scopes or modules. Cloth defines three primary modifiers plus block-scoped defaults:

- **public** — Accessible from any module. Public declarations form the module’s exported surface. Changing a public member’s signature is a breaking change.
- **internal** — Accessible only within the declaring module (all compilation units sharing the same `module` statement). This is the default for top-level declarations.
- **private** — Accessible only within the declaring type or block. This is the default for members declared inside a type.

Rules:

- A declaration may not increase visibility relative to its container. For example, a `private` nested class cannot contain a `public` field that references the enclosing private type if that field would leak the private type outside its allowed visibility.
- Visibility is orthogonal to scope: a `public` field still requires qualification (`instance.field`) and obeys scope rules when referenced.
- Attributes defined by this specification may refine visibility (e.g., `shared`, `owned`, `static` when used as annotations). Implementations **MUST NOT** introduce additional access modifiers beyond those enumerated here without a future revision of the language spec.
- When multiple partial declarations of a type exist (future feature), they must agree on visibility for overlapping members.


## 7. Expressions

Expressions produce values, references, or effects. Cloth evaluates expressions deterministically from left to right unless an operator states otherwise. Every expression has a static type (see Section 4) and follows the ownership semantics in Section 5 and in the Ownership & Lifetime Model.

### 7.1 Expression Categories

- **Value expressions** yield owned values (`Type`).
- **Reference expressions** yield `&Type` borrows; the referenced object must outlive the expression using it.
- **Shared expressions** yield `$Type` handles in the shared lifetime domain.
- **Constant expressions** evaluate entirely at compile time and may initialize `const` members, enum discriminants, and annotations.
- **Meta expressions** use `expr :: META_KEYWORD` (see Section 2.3.3) to query compile-time information. They must be deterministic and side-effect free.

### 7.2 Operator Precedence and Associativity

Highest precedence first (operators on the same row associate left-to-right unless noted):

1. Primary: `expr.member`, `call()`, literals, `expr :: META`
2. Unary (right-to-left): `+`, `-`, `!`, `~`, `as`, `as?`
3. Multiplicative: `*`, `/`, `%`
4. Additive: `+`, `-`
5. Bitwise AND: `&`
6. Bitwise XOR: `^`
7. Bitwise OR: `|`
8. Comparison: `<`, `<=`, `>`, `>=`, `is`, `in`
9. Equality: `==`, `!=`
10. Logical AND: `and`
11. Logical OR: `or`
12. Null-coalescing (right-to-left): `??`
13. Ternary (right-to-left): `?:`
14. Assignment (right-to-left): `=`, `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`

Operators not listed are reserved for future revisions.

### 7.3 Assignment Expressions

- Syntax: `target assignment-operator expression`.
- Owned targets receive ownership of the right-hand side; the previous value is destroyed unless ownership moved elsewhere.
- Reference targets (`&Type`) rebind to the new referent without affecting ownership.
- Shared targets (`$Type`) update their handle, releasing the prior handle via the shared-domain protocol.
- Compound assignments evaluate the target once before applying the arithmetic or bitwise operator.
- Assignment expressions evaluate to the assigned value, enabling chains (e.g., `a = b = 0`).

### 7.4 Comparison Expressions

- Operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `is`, `in`.
- Equality compares primitives by value, strings by code units, references by identity, and shared handles by pointer equality unless overridden via traits.
- Relational operators apply to numeric primitives and to types that opt in via comparison traits (future Section 9). Unsupported usage is a compile-time error.
- `is` performs runtime type checks and supports guarded bindings (`if (value is Renderer renderer)`).
- `in` tests membership (e.g., `value in array`). Built-in collections rely on equality; user-defined collections may customize membership semantics.

### 7.5 Logical Expressions

- Operators: `and`, `or`.
- `lhs and rhs` evaluates `rhs` only if `lhs` is `true`; `lhs or rhs` evaluates `rhs` only if `lhs` is `false`.
- Operands must be `bool`; no implicit conversions occur.

### 7.6 Bitwise Expressions

- Operators: `&`, `|`, `^`, `~`.
- Operands must be integer or `bit` types. Results use the wider operand type.
- `~` is unary and returns the same type as its operand.

### 7.7 Arithmetic Expressions

- Operators: `+`, `-`, `*`, `/`, `%`, unary `+`, unary `-`.
- Signed overflow is **undefined behavior**; unsigned arithmetic wraps modulo 2^n (where *n* is the bit width).
- Division by zero raises a runtime error for integers and follows IEEE rules (`NaN`, `±Infinity`) for floating-point.
- Mixed-type arithmetic applies numeric promotions; otherwise an explicit cast is required.

### 7.8 Null-Coalescing / Fallback Expressions

- Operator: `expr1 ?? expr2`.
- `expr1` must be nullable (`T?`). If non-null, the expression yields `expr1`; otherwise it evaluates and yields `expr2`.
- Right-associative: `a ?? b ?? c` == `a ?? (b ?? c)`.
- Frequently paired with safe casts: `(input as? u32) ?? throw new NegativeNumberError("Negative number");`.

### 7.9 Ternary Expressions

- Syntax: `condition ? whenTrue : whenFalse`.
- `condition` must be `bool`. The other operands must convert to a common type; otherwise the expression is ill-typed.
- Only the selected branch evaluates. Ownership transfers according to the branch result.

### 7.10 Lambda Expressions

- Syntax (preview): `|params| expression` or `|params| { statements }`.
- Lambdas evaluate to delegates inferred from context (function pointer, interface, trait). **OPEN ISSUE: Callable traits** will finalize typing rules.
- Capturing owned values moves them into the lambda unless explicitly borrowed; capturing references borrows them subject to lifetime checks.
- Lambdas may include modifiers such as `async` or `maybe`, mirroring normal functions.

### 7.11 Cast Expressions

- `expr as TargetType` performs explicit casts (see Section 4.8.1) and throws when the conversion fails.
- `expr as? TargetType` performs safe casts (see Section 4.8.2) and yields `TargetType?`, returning `null` on failure.
- Cast expressions bind tighter than multiplicative operators but looser than member access.

### 7.12 Call Expressions

- Syntax: `callable(arguments)`.
- Evaluation order: evaluate the callable, evaluate arguments left-to-right, apply implicit conversions, then transfer ownership based on parameter markers (`Type`, `&Type`, `$Type`).
- Functions declared with `maybe` may signal errors; callers must handle these paths explicitly.
- Overload resolution occurs at compile time; ambiguous calls are errors.

### 7.13 Member Access Expressions

- Syntax: `receiver.member`.
- `receiver` may be an expression, module, or type. Static members require the type name; instance members require an expression.
- Accessing nullable receivers requires prior null checks; no implicit safe-navigation operator exists yet.
- `::` remains reserved for selective imports and meta invocations, not general member access.

These expression rules define parsing, evaluation order, and ownership interactions, paving the way for the statement semantics in Section 8.
