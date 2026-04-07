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
      6. string Literals
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
      3. Final, Prototype, Implementation, and Override Rules
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

This specification is the authoritative contract for the Cloth programming language. It defines the lexical grammar, static semantics, runtime behavior, and observable side effects that every conforming compiler, linker, diagnostics tool, and runtime environment MUST honor. Companion documents such as the **Cloth Ownership & Lifetime Model** and **Cloth Compiler Specification** focus on specialized domains; this document binds those domains together so that any conforming artifact behaves predictably when executed.

Cloth targets high-performance, object-oriented systems programming. Programs organize behavior into modules and types, execute under deterministic destruction enforced by an explicit ownership tree, and avoid garbage collection in favor of lexical and structural lifetimes. Implementations are expected to surface these semantics directly—generated code MUST NOT introduce hidden services beyond what is prescribed here, ensuring that developers can reason about memory, control flow, and binary layout at every step.

The scope of this specification includes:

- The syntactic and lexical rules that transform Unicode source files into tokens (Sections 2-3).
- The static semantics governing types, declarations, visibility, ownership, and lifetime (Sections 4-11, together with the ownership companion document).
- The runtime execution, build manifest contracts, and observable diagnostics emitted by conforming toolchains (Sections 12-13).

Each clause either imposes a normative requirement or documents a guaranteed consequence. Informative notes are clearly labeled and never weaken the adjacent normative language. Statements marked as requirements remain in force until this document is revised; there are no unresolved placeholders within Section 1.

### 1.1 Goals and Non-Goals

#### Goals

- **Predictable execution:** Object construction, destruction, and memory reclamation MUST follow the ownership tree rooted at the entrypoint instance of `Main`. Deterministic destruction replaces garbage collection and lets code reason about when resources are reclaimed.
- **Maintainable structure:** Modules, explicit imports, class-based declarations, and manifest-driven builds SHOULD expose dependency relationships so that large projects can be analyzed incrementally by compilers and auxiliary tooling.
- **Low-level control:** Value representations, calling conventions, layout rules, and meta queries (e.g., `TYPEOF`, `SIZEOF`) MUST remain visible, letting Cloth integrate with other systems languages and platform ABIs without hidden adapters.
- **Strong compile-time guarantees:** Type checking, visibility enforcement, ownership validation, and `maybe`-annotated error paths MUST succeed or fail before execution begins, minimizing runtime surprises.
- **Tooling interoperability:** Diagnostics, symbol metadata, and manifest semantics SHOULD be precise and machine-readable so that editors, linters, debuggers, and build systems can share a consistent understanding of a Cloth project.
- **Cross-document coherence:** Requirements in this specification MUST remain synchronized with the Ownership & Lifetime Model and Compiler Specification. When multiple documents describe the same construct, the stricter rule prevails to avoid contradictory interpretations.

#### Non-Goals

- Defining the entire standard library. This document limits itself to language constructs; library APIs are versioned separately.
- Mandating an internal compiler architecture. Implementations MAY select any pipeline or intermediate representation as long as externally visible behavior matches the rules herein.
- Prescribing installer workflows, packaging formats, or project layout conventions beyond the manifest requirements in Section 13.
- Providing dynamic code loading, runtime reflection, or just-in-time compilation semantics. Programs MUST assume such facilities are unavailable unless a future revision explicitly standardizes them.
- Guaranteeing concurrent execution ordering. Until dedicated concurrency rules are standardized, Cloth code executes as if on a single-threaded scheduler; implementations MAY offer extensions, but conforming programs MUST treat cross-thread interaction as undefined behavior.

### 1.2 Conformance Language (MUST/SHOULD/MAY)

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** follow [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119). In this specification they apply to three audiences simultaneously:

1. **Implementations** (compilers, linkers, analyzers, runtime loaders) that ingest Cloth source text or intermediate outputs.
2. **Programs** (the transitive closure of modules that form an application or library) whose correctness is being assessed.
3. **Program authors** who produce or maintain Cloth source code.

Normative statements always identify the subject either explicitly or by context. When two requirements appear to conflict, the stricter requirement wins, and implementations MUST produce diagnostics explaining the conflict. If behavior is intentionally unspecified, the text calls it out as "unspecified" or "implementation-defined"; any construct not covered by those terms but also not permitted is treated as undefined behavior.

Informative examples, notes, and rationale never soften a preceding or following normative paragraph. Readers MUST rely on the normative text when deciding conformance, and tooling that surfaces documentation SHOULD reference the exact clause number when emitting a diagnostic or recommendation.

### 1.3 Terminology

- **Implementation:** A fully or partially conforming tool that consumes Cloth source code and produces diagnostics, artifacts, or both. Unless noted otherwise, "implementation" refers to a tool that strives for full conformance.
- **Program:** The closure of modules reachable from the declared entry module (or manifest-provided entry), evaluated beginning with the construction of `Main` as defined in Section 12.
- **Module:** The top-level namespace introduced with the `module` declaration. Modules determine import boundaries, visibility scopes, and how files map into compilation units.
- **Compilation Unit:** The set of source files compiled together as a single semantic entity. Units are formed either implicitly from the module graph or explicitly via `[[units]]` in Section 13.
- **Type Declaration:** Any top-level construct that introduces a class, struct, enum, interface, trait, or other type-like entity. The precise categories are defined in Sections 4-5.
- **Instance:** A runtime allocation produced by invoking a constructor; every instance participates in exactly one ownership tree rooted at the entrypoint object unless it resides in the shared or static lifetime domains.
- **Static Member:** A declaration marked `static`, which exists in the root lifetime domain and is initialized according to Section 9.8 rather than by an owning instance.
- **Ownership Tree:** The hierarchy induced when objects own other objects. Destruction walks this tree from leaves to root, guaranteeing deterministic cleanup per Section 11.
- **Lifetime Domain:** One of the ownership, shared, or static domains defined by the Ownership & Lifetime Model. Domain transitions carry explicit rules described in Section 11.
- **Diagnostic:** Any machine- or human-readable message emitted by an implementation to report success, failure, or auxiliary information. Diagnostics SHOULD include precise source spans and clause references when available.
- **Undefined Behavior (UB):** Program constructs for which this specification imposes no requirements. Conforming programs MUST avoid UB; implementations MAY reject or accept UB constructs but are not obligated to diagnose them.
- **Reserved Syntax:** Keywords or grammatical forms held for future revisions. Implementations MUST reject attempts to use reserved constructs, and tooling SHOULD surface actionable guidance.
- **Manifest:** The `build.toml` file that provides project-level configuration, target selection, and dependency declarations (Section 13).
- **Entrypoint:** The type identified by manifest configuration or inference that defines the root `Main` instance and initiates execution per Section 12.

Additional specialized terminology (e.g., borrowing, shared handles, maybe clauses) is introduced in the sections where it first becomes normative so that readers encounter each concept alongside its governing rules.

## 2. Lexical Structure

Lexical analysis converts normalized source text into a stream of tokens consumed by the parser. It is purely syntactic—no name lookup, type checking, or macro expansion may occur during this stage. Unless explicitly noted, every rule below applies equally to module headers, declarations, expressions, attribute arguments, and embedded code snippets.

### 2.1 Source Text and Normalization

#### 2.1.1 Encoding

- Source files **MUST** be encoded as UTF-8. Implementations **MUST** accept UTF-8 without a byte-order mark (BOM) and **MAY** accept BOM-prefixed files by discarding the BOM before lexing.
- Any byte sequence that is not well-formed UTF-8 is ill-formed source text. Implementations **MUST** issue a diagnostic and **MUST NOT** silently recover by inserting replacement characters.
- Tooling that edits Cloth code in another encoding (for example UTF-16 editors) **MUST** transcode to UTF-8 prior to invoking a compiler or formatter.

#### 2.1.2 Line Terminators

- The only recognized line terminators are LF (`U+000A`), CR (`U+000D`), and the two-character sequence CR LF. Compilers **MUST** normalize CR LF to a single LF token. Lone CR characters MAY be normalized to LF for internal bookkeeping but retain the same line number semantics.
- Other Unicode separators (`U+2028`, `U+2029`, etc.) are illegal outside of string literals. Encountering one **MUST** produce a diagnostic that identifies the offending code point.
- Logical line numbers increment after each normalized LF. Columns reset to `1` immediately afterward.

#### 2.1.3 Control Characters

- Outside of string literals the only permitted control characters are horizontal tab (`U+0009`), carriage return, line feed, and space (`U+0020`). Vertical tab, form feed, NUL, and other C0 controls are forbidden and **MUST** trigger diagnostics.
- Non-ASCII Unicode scalars are not permitted in identifiers or operators. They may appear only inside string literals or character literals where their encoding is explicit.

#### 2.1.4 Logical Files

- Each physical file forms its own token stream. After consuming the final code point the lexer **MUST** append a single `EndOfFile` meta token whose span starts and ends at the logical end position.
- Tooling that synthesizes buffers (REPLs, notebooks, IDE snippets) **MUST** enforce the same decoding, normalization, and `EndOfFile` rules as disk-backed files.
- Concatenation options (for example, `compiler -cat file1 file2`) operate on bytes before normalization. No extra newline is inserted between files unless one is already present.

### 2.2 Tokenization Model

1. **Determinism** — Lexing the same source text twice **MUST** produce the same token sequence, including whitespace spans used for diagnostics.
2. **Maximal munch** — The lexer **MUST** choose the longest lexeme that matches any token category at the current position. When two categories tie, the precedence order is Identifier → Keyword → Literal → Operator/Delimiter → Meta.
3. **Spans** — Every token carries its start/end byte offsets plus line and column numbers. Tools rely on these spans to reconstruct lexemes and emit precise diagnostics.
4. **Whitespace** — Whitespace and comments never become standalone tokens; they are separators only.

The core token categories are identifiers, keywords, literals, operators/punctuation, and meta tokens (Section 2.3).

### 2.3 Meta Tokens

Meta tokens model compile-time queries and sentinel values independently from ordinary identifiers.

#### 2.3.1 Sentinels

- `EndOfFile` **MUST** be emitted exactly once per logical file. No additional recovery tokens are standardized; implementations **MAY NOT** invent new sentinel kinds without a future revision of this document.

#### 2.3.2 Meta Keywords

Meta keywords are recognized only when both conditions hold:

1. The identifier lexeme matches one of the uppercase strings in the table below (case-sensitive).
2. The immediately preceding non-whitespace token is `OP_ColonColon`.

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

Lexemes that fail either condition are treated as ordinary keywords. Because these words are reserved, user code **MUST NOT** redeclare them as identifiers.

#### 2.3.3 Invocation Semantics

```
meta-invocation ::= primary-expression '::' META_KEYWORD
```

- `primary-expression` may be any value expression, literal, temporary, type designator, or object reference.
- The parser **MUST** preserve the meta keyword as a distinct `Meta` token so later phases can distinguish `value::TYPEOF` from qualified identifiers.
- Meta invocations are pure queries: they have no side effects and **MUST NOT** depend on hidden global state. When the operand is a compile-time constant, implementations **SHOULD** fold the meta query to a constant.

### 2.4 Comments and Whitespace

- Outside of literals, whitespace is limited to the characters described in Section 2.1. The lexer treats any contiguous sequence as a separator and never emits whitespace tokens.
- **Line comments** begin with `//` and extend through the next LF (excluded). They do not nest.
- **Block comments** begin with `/*` and end with the first subsequent `*/`. Nested block comments are illegal; encountering a second `/*` before the closing delimiter keeps the original comment open. Reaching end of file before `*/` **MUST** report an unterminated-comment diagnostic.
- Comment contents participate in line/column accounting so diagnostics inside comments still pinpoint the correct source location.
- Doc comments use the same lexical forms; there is no special syntax such as `///`. Future documentation annotations will be introduced explicitly rather than via comment conventions.

### 2.5 Identifiers

- Grammar:
  ```
  identifier ::= identifier-start identifier-part*
  identifier-start ::= 'A'..'Z' | 'a'..'z' | '_'
  identifier-part  ::= identifier-start | '0'..'9' | '$'
  ```
- Identifiers are ASCII only. Any attempt to embed non-ASCII scalars, escape sequences, or combining characters **MUST** be diagnosed.
- `$` may appear only after the first character. It exists to support tooling-generated symbols (e.g., `MyType$meta`). Human-authored code SHOULD avoid `$` unless interoperating with generated artifacts.
- `_` by itself is a legal identifier and conventionally denotes an intentionally unused binding.
- Keywords listed in Section 2.6 **MUST NOT** be used as identifiers.

### 2.6 Keywords

Keywords always produce dedicated token kinds, even when used where an identifier would otherwise be legal. Cloth keywords are case-sensitive; `import` is a keyword while `Import` is not.

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
3. The logical negation operator is spelled `!`; no textual alternative exists in this revision.

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
| `&`, `|`, `^`, `~`               | `OP_BitAnd`, `OP_BitOr`, `OP_BitXor`, `OP_BitNot`                                                        | Bitwise operators.                         |
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
| `?`                              | ternary introducer / placeholder token (semantics defined in Section 7).                                 |
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
- Digit separators are not supported. Introducing `_` (or any other separator) inside a literal is a lexical error.
- The optional **type suffix** is a single ASCII letter chosen from `{ b, B, i, I, l, L, u, U }` and indicates the canonical type prior to contextual conversions:

  | Suffix    | Canonical type | Notes                                                                        |
  |-----------|----------------|------------------------------------------------------------------------------|
  | `b` / `B` | `byte`         | Value **MUST** be in `[0, 255]`; see Section 2.8.3 for details.              |
  | `i` / `I` | `int`          | Default when no suffix is present.                                           |
  | `l` / `L` | `long`         | Distinct semantic intent but not a different bit-width at the lexical stage. |
  | `u` / `U` | `uint`         | Marks the literal as unsigned.                                               |

  The suffix affects the literal’s _declared_ type but **does not** change its width; overload resolution and type inference may still widen or narrow the literal to match its target type. For example, `i32 x = 10i;` parses `10i` as an `int` literal whose value is `10`; assignment then widens it to `i32` during type checking.
- Lexers **SHOULD** evaluate the literal into a canonical integer value after stripping the prefix and suffix. Overflow detection still occurs during semantic analysis; if the computed value cannot fit any representable target type the implementation **MUST** emit a diagnostic.

#### 2.8.2 Floating-Point Literals

- Grammar:<br>
  `float-literal ::= digits? '.' digits? type-suffix?`

  At least one side of the decimal point **MUST** contain digits, enabling forms such as `.5`, `123.`, and `123.456`. Scientific/exponent notation is currently unsupported; attempting to write `1.0e+3` is a lexical error.
- Literals may optionally carry a single-letter type suffix chosen from `{ f, F, d, D }`:

  | Suffix    | Canonical type                       |
  |-----------|--------------------------------------|
  | `f` / `F` | `float` (single precision)           |
  | `d` / `D` | `double` (double precision, default) |

  Absence of a suffix defaults to `double`. As with integers, the suffix selects the literal’s canonical type but does not freeze its width; contextual conversion may widen or narrow the literal if required by the target expression.
- Because trailing-only or leading-only digits are legal, the lexer **MUST** treat `123.` and `.123` as single float literals rather than `Integer`/`OP_Dot` combinations. When neither side contains digits (i.e., a bare `.`), the token remains `OP_Dot`.
- The literal is represented as `Float(value)` where `value` is the IEEE double produced by interpreting the textual lexeme (after removing the suffix). Invalid decimal spellings **MUST** be rejected.

#### 2.8.3 Byte Literals

- A byte literal is an integer literal terminated with suffix `b` or `B`. Regardless of radix, the literal’s numeric value **MUST** be in `[0, 255]`; otherwise the implementation **MUST** issue an error.
- The canonical type of a byte literal is `byte`, defined as an unsigned 8-bit two’s-complement integer (i.e., zero-extended arithmetic). Assigning a byte literal to a wider integer implicitly zero-extends it; assigning to a narrower type is illegal unless an explicit conversion exists.
- Radix prefixes from Section 2.8.1 are permitted: `255b`, `0xFFb`, and `0b1111_1111b` (once separators are standardized) all denote the same value. The suffix attaches to the literal after all digits and before any whitespace or comments.
- Byte literals participate in overload resolution like other typed literals. When no context is provided they default to the `byte` type.

#### 2.8.4 Bit Literals

- A bit literal represents a single binary digit with the grammar:<br>
  `bit-literal ::= ('0' | '1') ('t' | 'T')`
- The canonical type `bit` occupies one binary digit and can convert losslessly to `bool`, `byte`, or any larger integer type. Converting from a wider type to `bit` requires explicit operators defined in Section 7.
- Implementations **MUST** reject any attempt to apply radix prefixes or multi-digit forms to bit literals. Only `0t`, `0T`, `1t`, or `1T` are valid spellings.

#### 2.8.5 Character Literals

- Character literals are enclosed in single quotes (`'A'`). Exactly one Unicode scalar value **MUST** appear between the quotes, either directly or via an escape sequence.
- Supported escapes mirror string literals: `\\n`, `\\r`, `\\t`, `\\\"`, `\\\\`, and `\\'`. Hexadecimal (`\\xNN`) and Unicode (`\\u{XXXX}`) escapes are accepted; invalid sequences are diagnosed.
- The literal’s canonical type is `char`. It promotes to `int`, `byte`, or `u32` via zero-extension of the scalar’s code point.
- Unescaped control characters prohibited by Section 2.1.3, stray surrogate halves, and multi-code-point grapheme clusters **MUST** be rejected.
#### 2.8.6 string Literals

- string literals are enclosed in double quotes (`"`). The closing quote **MUST** appear on the same logical line unless escaped. Encountering a newline before the closing quote is diagnosed as an unterminated string literal.
- Backslash escapes supported today are `\n`, `\r`, `\t`, `\"`, and `\\`. Any other character following `\` results in that character being inserted literally; the reference implementation does not yet reject unknown escapes, but the specification treats them as reserved and **recommends** emitting diagnostics so that future escape sequences can be added without changing runtime meaning.
- string literals may contain arbitrary Unicode scalar values except unescaped control characters forbidden by Section 2.1.3. Implementations **MUST** track the original span so that diagnostics within strings (e.g., invalid escape) can pinpoint the problematic character.

#### 2.8.7 Boolean, Null, and Special Literals

- The lexemes `true` and `false` produce keyword tokens that participate in expression grammar as boolean literals.
- `null` denotes the absence of an object reference. Its nullability semantics are governed by Section 7.
- `NaN` is a keyword literal that maps to the IEEE Not-a-Number value. It is case-sensitive and **MUST** appear with capital `N`.

#### 2.8.8 Unsupported Literal Forms

Byte-array literals, template strings, numeric separators, additional float notations, and new escape sequences are not part of this revision. Any attempt to use such syntax **MUST** produce a diagnostic so programs do not rely on undefined behavior.

## 3. Program Structure

Source files, modules, and compilation units form the backbone of every Cloth program. This section defines how source files map to modules, how modules resolve one another, and how top-level declarations are organized so that tooling can analyze large codebases deterministically.

### 3.1 Compilation Units

- A **compilation unit** (Section 1.3) consists of one physical file after lexing and normalization (Section 2). Unless the manifest explicitly groups files via future mechanisms, each source file is treated as one compilation unit.
- The grammar for a compilation unit is
  ```
  compilation-unit ::= module-declaration import-section? declaration-block
  ```
  Free-standing statements before the `module` declaration are invalid.
- The `module` declaration **MUST** be the first non-comment token. Leading comments, shebangs, or whitespace are allowed; any other construct before `module` is ill-formed.
- The `import-section` is a contiguous block of `import` directives. Implementations SHOULD flag imports that appear after declarations because they obscure dependency ordering.
- Compilers MAY process units in any order or in parallel, but diagnostics MUST remain deterministic (for example, sorted by file path and source span).

### 3.2 Two-Pass Model

Implementations may structure their front end however they wish, but observably a Cloth compiler behaves as though it executes two logical passes:

1. **Structural pass** — parses syntax, records module memberships, collects declarations, and builds symbol tables. No type checking or ownership analysis occurs in this pass.
2. **Semantic pass** — performs name binding, type checking, ownership validation, meta-token evaluation, and code generation using the immutable results of the structural pass.

Even if an implementation merges these passes internally, diagnostics emitted during later phases MUST cite spans discovered during the structural pass so tooling can navigate precisely.

### 3.3 Modules

A module is the first-level namespace boundary. All compilation units that share the same module path are merged before semantic analysis.

#### 3.3.1 Module Declarations

- Syntax:
  ```
  module-declaration ::= 'module' module-path ';'
  module-path        ::= identifier ('.' identifier)*
  ```
- Each compilation unit **MUST** declare exactly one module. Files lacking a module declaration (or declaring more than one) are rejected.
- Module segments obey the identifier grammar from Section 2.5. Keywords, meta keywords, empty segments, and non-ASCII characters are prohibited.
- All units that declare `module cloth.net.http;` belong to the same module and are merged before semantic analysis. If two units introduce conflicting declarations, the compiler MUST emit a diagnostic citing both locations unless a future standard describes partial-type composition.

#### 3.3.2 Naming Conventions

- Module names are case-sensitive. `example.net` and `Example.Net` refer to different modules even if they reside in the same directory.
- Directory structure SHOULD mirror module hierarchies (e.g., `cloth/net/http/Main.co` contains `module cloth.net.http;`). Tooling relies on this convention to locate files and compute import paths.
- Module segments MUST start with a letter or `_` and may include digits or `$`. Characters such as `-`, whitespace, or Unicode punctuation are forbidden.
- Sharing a prefix with another module (e.g., `cloth.out` vs. `cloth.out.io`) has no semantic effect. Visibility still depends on imports and modifiers.

#### 3.3.3 Reserved Namespaces

- The prefixes `cloth.*`, `compiler.*`, and `std.*` are reserved for the official distribution, compiler tooling, and the standard library. User code MUST NOT declare modules rooted at these prefixes unless authorized by project configuration.
- Platform vendors MAY document additional reserved prefixes (e.g., `vendor.*`). Compilers should warn when user modules attempt to shadow these namespaces even if the build technically allows it.

### 3.4 Imports

Imports control compile-time visibility. They do not load code at runtime.

#### 3.4.1 Syntax

```
import-directive ::= 'import' module-path ('.' identifier)* ('::{' import-list '}')? ';'
import-list      ::= import-entry (',' import-entry)*
import-entry     ::= identifier ('as' identifier)?
```

- A plain import (`import cloth.out;`) exposes the module for qualified use (e.g., `cloth.out.println`).
- A selective import (`import cloth.out::{println};`) brings specific symbols into scope. The `::` introducer is mandatory; omitting it is a syntax error.
- Each selective entry MAY rename the imported symbol using `as`. After renaming, the new identifier MUST follow the identifier grammar.
- Duplicate local names (from either multiple selective imports or name clashes with local declarations) MUST trigger an ambiguity diagnostic.
- Imports form a contiguous block immediately after the module declaration. Declaring identifiers before imports is forbidden.

#### 3.4.2 Resolution and Cycles

- During import resolution the compiler verifies that the target module exists, is reachable, and exports the requested symbol with sufficient visibility. Missing modules or symbols are reported before semantic analysis continues.
- Modules may reference each other cyclically so long as the structural pass can resolve all declarations without ambiguity. Tooling MUST collect and merge top-level declarations prior to analyzing bodies so that mutually dependent modules see each other’s definitions.
- Ownership rules remain acyclic: even if modules refer to each other, owned object graphs must not form cycles unless the objects live in a shared lifetime domain (Section 11).
- A module import cycle becomes illegal only when it prevents unambiguous resolution (for example, two modules each require the other’s constants during static initialization). When rejecting a cycle, implementations SHOULD emit diagnostics that list the cycle path.

### 3.5 Top-Level Declarations

- Only type declarations (`class`, `struct`, `interface`, `trait`, `enum`, `type` alias) may appear at the top level. Free-standing variables, statements, or expressions outside a type declaration are invalid.
- Top-level types default to `internal` visibility; members declared inside a type default to `private`.
- Attributes, doc comments, and meta invocations that annotate a type MUST immediately precede the type keyword with no intervening declarations or imports.
- Exactly one top-level type declaration MUST appear per source file. Additional types MUST be nested or moved to their own files so that tooling can map file paths to type names deterministically.

### 3.6 File Organization

Even when advanced build systems aggregate files, each physical source file MUST observe the same structure so tools can parse files independently:

1. Optional license or tooling comments.
2. `module` declaration.
3. Contiguous `import` block (preferably sorted lexicographically).
4. Exactly one top-level type declaration whose name matches the project’s documented conventions (for example, file name equals type name).

Declaring multiple modules per file, placing imports after declarations, or mixing statements with the module declaration is forbidden and MUST trigger diagnostics. Generated files are subject to the same ordering so that they can be compiled alongside handwritten sources without special flags.

## 4. Type System

Cloth’s type system is nominal, statically checked, and ownership-aware. Every expression, declaration, and intermediate value has an explicit type, and those types govern both compile-time reasoning and runtime layout.

### 4.1 Overview

- Types fall into four broad categories: primitives, composites, nullable forms, and user-defined declarations (classes, structs, interfaces, traits, enums).
- All user-defined types are nominal: equality depends on the fully qualified module path plus the type name.
- `any` is the universal reference type. Any reference type may implicitly upcast to `any`; downcasts require explicit casts or safe casts.
- `void` represents “no value.” It may only appear as the return type of functions or as the type of a constructor. Variables, fields, and parameters cannot have type `void`.
- Nullability is explicit. Non-nullable types **MUST NOT** receive `null`, and compilers enforce this restriction at compile time.

### 4.2 Primitive Types

Primitive types have fixed binary representations defined by the language rather than by user code.

#### 4.2.1 Integers

- Signed integers: `i8`, `i16`, `i32`, `i64`.
- Unsigned integers: `u8`, `u16`, `u32`, `u64`.
- Synonyms: `byte`=`u8`, `short`=`i16`, `int`=`i32`, `long`=`i64`, `uint`=`u32`, `bit` (single-bit type).
- Representation: all integers use two’s-complement encoding. Arithmetic that overflows the target type is **undefined behavior**; future revisions may introduce checked arithmetic intrinsics, but until then overloads and user code must guard explicitly.
- Implicit conversions are limited to widening conversions within the same signedness (e.g., `i16 → i32`). Signed-to-unsigned or narrowing conversions require explicit casts.

#### 4.2.2 Floating-Point Numbers

- `f32` (alias `float`) implements IEEE-754 single precision.
- `f64` (aliases `double`, `real`) implements IEEE-754 double precision.
- Only the widening conversion `f32 → f64` is implicit. All other conversions require explicit casts because they may change precision or range.

#### 4.2.3 Boolean and Bit Types

- `bool` stores the logical values `true` and `false`. Conditionals (`if`, `while`, `switch`) require `bool`; no other type auto-converts to boolean.
- `bit` is a single-bit numeric type used for bit-level APIs. Unlike `bool`, it participates in numeric operations but cannot replace `bool` in control-flow constructs.

#### 4.2.4 string

- `string` is an immutable UTF-8 sequence. Length is measured in bytes; the standard library exposes code-point iterators for locale-aware operations.
- String literals allocate `string` instances owned by the declaring module unless explicitly copied or transferred.

### 4.3 Composite Types

Composite types derive from other types but remain first-class citizens.

#### 4.3.1 Arrays

- Syntax: `T[]`.
- Arrays are reference types that own their elements. Destroying the array destroys the contained elements following the ownership rules in Section 11.
- Length is fixed at construction. Indexing is bounds-checked unless a documented `unsafe` escape hatch is used.

#### 4.3.2 Tuples

- Syntax: `(T0, T1, …, Tn)` for `n ≥ 1`.
- Tuples are value types. Equality and hashing are structural and consider each component in order.
- Elements are accessed via positional selectors (`value.0`) or pattern destructuring.

### 4.4 Nullable Types

- `T?` denotes an optional value of type `T`. The value set is `{null} ∪ {v | v ∈ T}`.
- Nullable references default to `null`; nullable value types default to the zero-initialized value of `T`.
- Converting `T?` to `T` requires an explicit null check (`??`, `if`, pattern matching). Assigning `null` to a non-nullable `T` is a compile-time error.

### 4.5 Type Modifiers

Modifiers refine concurrency, storage, or ownership semantics. When a modifier affects lifetime, it must remain consistent with Section 11.

#### 4.5.1 `atomic`

- `atomic T` guarantees atomic reads and writes with sequentially consistent ordering.
- Only types whose sizes fit the platform’s native atomic width may be marked `atomic`. Larger types trigger an error.

#### 4.5.2 Ownership Modifiers

- `shared` places an instance in the shared lifetime domain. Shared instances cannot own non-shared children.
- `owned` documents that a member participates in its owner’s destruction order (the default for most fields).
- `const` prohibits mutation after initialization for both values and references.
- `static` indicates that the declaration lives in the static lifetime domain and never participates in ownership transfers.

### 4.6 Type Identity

- Primitive identities are determined by canonical names; aliases map to their canonical forms.
- User-defined types are identified by fully qualified module path plus type name.
- Array types are identical when their element types match exactly. Tuples require identical arity and component types in order.
- Nullable types form distinct identities (`T? ≠ T` even if `T` admits `null`).
- Type aliases introduce alternate spellings but do not produce new identities.

### 4.7 Type Inference

- `var` enables local inference: `var x = expr;` infers `x`’s type from `expr`. The initializer is mandatory.
- Generic inference chooses type arguments that satisfy all constraints at the call site. If inference fails, the program is ill-typed and the compiler MUST request explicit type arguments.
- Inference is never bidirectional; later usage does not retroactively change earlier declarations.
- Public APIs SHOULD spell out explicit types to maintain stability across compilation units.

### 4.8 Conversion Semantics

Conversions move values between types. Unless stated otherwise, conversions occur at compile time; runtime checks are inserted only when required for safety.

#### 4.8.1 Explicit Casting (`as`)

- Syntax: `expr as TargetType`.
- Used for numeric narrowing, reference downcasts, and interface/class rebindings.
- If the conversion cannot be proven safe, a runtime check occurs. Failing the check throws a `CastError`.

#### 4.8.2 Safe Casting (`as?`)

- Syntax: `expr as? TargetType`.
- Returns `TargetType?`. When conversion succeeds, the result is non-null; otherwise `null` is returned without throwing.
- Safe casts are typically paired with `??` to provide fallback behavior.

#### 4.8.3 Implicit Conversions

Implicit conversions are limited to:

1. Numeric widening (`i8 → i16`, `f32 → f64`).
2. Reference upcasting along inheritance or interface edges.
3. Adding nullability (`T → T?`).

All other conversions—including nullable-to-non-nullable and signed-to-unsigned—require explicit casts.

## 5. Declarations

Declarations introduce names, tie them to types, and establish how values participate in Cloth’s ownership and lifetime model. Every rule in this section builds on the structural requirements from Section 3, the type semantics from Section 4, and the ownership rules summarized in Section 11.

### 5.1 General Rules

1. **Explicit typing** — Every declaration MUST state its type (or use `var` for local inference). The compiler never infers visibility, ownership domain, or modifiers from usage.
2. **Storage domains** — Declarations belong to exactly one storage domain:
   - **Static** — Prefixed with `static`; lifetime spans the duration of the program.
   - **Instance** — Fields and members owned by an object; they participate in the ownership hierarchy rooted at `Main`.
   - **Local** — Variables declared inside a block; lifetime ends when the block exits unless ownership is transferred outward.
3. **Relationship markers** — `Type` denotes owned values, `&Type` denotes borrows, and `$Type` denotes shared handles. Unmarked declarations default to owned.
4. **Visibility defaults** — Top-level declarations default to `internal`; members default to `private`. Public APIs SHOULD spell out visibility explicitly.
5. **Definite assignment** — A declaration cannot be read until it has been initialized along every control path. Constructors MUST initialize all owned fields before the instance escapes.
6. **Transfer rules** — Assigning an owned value to a new owner transfers ownership and invalidates the source slot unless the type is copyable. Compilers MUST reject transfers that would create ownership cycles or multiple owners for the same instance.
7. **Field initializer order** — Within a type, field initializers execute in textual order and may reference only fields declared earlier in the same type. Referencing a later field is a compile-time error.

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

```
function-modifiers? func Name(parameter-list) :> return-type maybe clause? body
```

- **Parameters**
  - Owned parameters (`Type`) transfer ownership into the function scope. The function MUST either consume or return ownership before exit.
  - Borrowed parameters (`&Type`) leave ownership with the caller; the callee MUST NOT store the reference beyond the call unless the type system proves the lifetime is valid.
  - Shared parameters (`$Type`) copy a shared handle; lifetime is governed by the shared domain.
- **Return values**
  - Returning `Type` transfers ownership to the caller.
  - Returning `&Type` borrows from the callee; the compiler MUST ensure the referenced object outlives the call.
  - Returning `$Type` passes a shared handle back to the caller.
- **Maybe clauses** — `maybe ErrorType1, ErrorType2` indicates that the function may return either the declared value or one of the listed errors. Ownership guarantees remain in force on both success and failure paths.
- **Receivers**
  - `static` functions reside in module/type scope and have no implicit receiver.
  - Instance methods receive `this` as owned (`this`) or borrowed (`&this`) depending on modifiers defined in Section 9.

### 5.5 Type Declarations

Type declarations define new nominal types and specify how their members participate in ownership.

- **Fields** — Unmarked fields are owned by the containing instance. Use `&Type` for borrows and `$Type` for shared handles.
- **Constructors** — Must initialize all owned fields before returning and may only read fields that have already been initialized (see Section 5.1).
- **Destructors** — Execute after owned children are destroyed, ensuring deterministic cleanup.
- **Static members** — Reside in the static domain and never participate in ownership transfers.
- **Nested types** — Inherit the enclosing type’s default visibility but form independent ownership domains when instantiated.

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

- Syntax mirrors classes, but structs are value types allocated inline.
- Copy semantics:
  - Assigning a struct copies each field. For owned fields, the copy invalidates the source field (a move). Only bitwise-copyable primitives and types explicitly marked as duplicable may be copied without transfer.
  - Structs cannot contain `$Type` fields unless the shared handle’s reference semantics are copyable.
- Structs do not participate in inheritance but may implement interfaces or traits.
- Because structs live inline, any destructor runs when the containing scope releases the struct (end of block, owning field destruction, etc.).

#### 5.5.3 Enum Declarations

- Enums are nominal tagged unions with a fixed set of cases. Syntax:<br>
  `enum Name { CaseA, CaseB(ValueType), ... }`
- Cases may carry payloads. Payload ownership follows the same rules as fields: unmarked payload types are owned by the enum instance.
- Enums are value types; copying behaves like structs (payloads are duplicated or transferred depending on their types).
- Pattern matching exhaustiveness will be enforced in Section 7. For now, the declaration must list every case explicitly; forward declarations are not allowed.

#### 5.5.4 Interface Declarations

- Syntax:
  ```
  interface Name { signature* }
  ```
- Interfaces declare method signatures and property contracts without providing storage. Implementations adopt the ownership semantics described in Section 5.4.
- A class or struct may implement multiple interfaces. The compiler MUST verify that each signature is implemented exactly once.
- Interfaces cannot declare fields or associated types in this revision.

These subsections ensure each type form has clear lifetime responsibilities, enabling the compiler to enforce deterministic destruction and ownership transfer consistently across the language.

## 6. Scope and Accessibility

Scope determines where a declaration is visible. Accessibility controls which modules may use that declaration. Cloth enforces lexical scoping: the textual structure of the program alone determines scope boundaries.

### 6.1 Scope Rules

#### 6.1.1 Block Scope

- Every block `{ ... }` creates a fresh symbol table for locals, labels, and nested declarations.
- Declarations are visible from their declaration point to the end of the block; forward references to later declarations in the same block are disallowed unless the language explicitly supports hoisting.
- Control-flow statements (`if`, `for`, `while`, `switch`, `match`, `catch`, `finally`) implicitly form blocks. Conditions MUST be parenthesized. Tooling SHOULD enforce braces even for single-statement bodies to avoid ambiguity.
- Lifetime:
  - Owned locals are destroyed when the block exits unless ownership is moved out of the block.
  - Borrowed locals become invalid the moment the referenced object leaves scope; compilers must diagnose potential dangling references.
  - Shared locals release their handle when the block terminates following shared-domain rules.
- Variables declared in loop initialization clauses belong to the loop’s block scope.

#### 6.1.2 Function Scope

- Function scope encompasses parameters, the function body, and any nested local declarations.
- Parameters remain in scope throughout the body. Default arguments evaluate in the caller’s context but may reference only earlier parameters.
- Instance methods implicitly introduce `this` (owned or borrowed depending on modifiers); static methods do not.
- Captures follow the rules from Section 5: capturing an owned value moves ownership into the lambda/local function unless the capture explicitly borrows (`&capture`); reference captures borrow; shared captures duplicate the handle. Compilers MUST reject captures that would outlive the captured value.
- Return statements may reference any identifier in function scope subject to lifetime constraints.
- Exception handlers nest inside function scope but may create their own block scopes.

#### 6.1.3 Type Scope

- Each type defines a member scope covering fields, properties, constants, methods, constructors, destructors, and nested types.
- Members are visible throughout the type body. Field initializers may reference only fields declared earlier in the same type.
- Nested types inherit access to the enclosing type’s `private` members but remain separate nominal types.
- Type scope is sealed: members never leak automatically into the enclosing module or instances. Access requires qualification (`instance.member` or `Type.member`).

### 6.2 Name Resolution

Name resolution searches scopes from innermost to outermost:

1. Current block.
2. Enclosing blocks up to the function scope.
3. Function parameters and implicit `this`.
4. Type members.
5. Module-level declarations in the same compilation unit.
6. Imported symbols (selective imports first, then fully qualified modules).
7. Global built-ins (primitive types, meta keywords).

- Qualified names bypass lexical lookup for their leading component (e.g., `module.symbol`).
- Ambiguities (e.g., two imports providing the same name) MUST produce a diagnostic that requires explicit qualification.

### 6.3 Shadowing Rules

- Local variables may shadow names from outer blocks, but they MUST NOT shadow members in the same storage domain when it would create ownership ambiguity (e.g., a local variable shadowing a field inside the same method).
- Parameters may not shadow fields of the containing type. Use `this.field` instead of redeclaring the name.
- Type names cannot be redeclared within the same module.
- Imports cannot shadow local declarations; conflicting imports must be aliased via `as`.

### 6.4 Visibility Modifiers

- **public** — accessible from any module.
- **internal** — accessible only within the declaring module (all compilation units sharing the same `module` declaration). This is the default for top-level declarations.
- **private** — accessible only within the declaring type or block. This is the default for members declared inside a type.

Rules:

1. A declaration cannot increase visibility relative to its container.
2. Visibility is orthogonal to scope; a `public` member still requires qualification and obeys the scope rules above.
3. Attributes defined by this specification may refine visibility; implementations MUST NOT invent new modifiers without standardization.
4. When partial declarations (future feature) exist, overlapping members MUST agree on visibility.

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

Visibility specifies whether a declaration can be accessed from other scopes or modules. Modules are the namespace units defined in Section 1.3, regardless of how the manifest partitions files into compilation units (Section 13.5). Cloth defines three primary modifiers plus block-scoped defaults:

- **public** — Accessible from any module. Public declarations form the module’s exported surface. Changing a public member’s signature is a breaking change.
- **internal** — Accessible only within the declaring module (all compilation units sharing the same `module` statement). This is the default for top-level declarations.
- **private** — Accessible only within the declaring type or block. This is the default for members declared inside a type.

Rules:

- A declaration may not increase visibility relative to its container. For example, a `private` nested class cannot contain a `public` field that references the enclosing private type if that field would leak the private type outside its allowed visibility.
- Visibility is orthogonal to scope: a `public` field still requires qualification (`instance.field`) and obeys scope rules when referenced.
- Attributes defined by this specification may refine visibility (e.g., `shared`, `owned`, `static` when used as annotations). Implementations **MUST NOT** introduce additional access modifiers beyond those enumerated here without a future revision of the language spec.
- When multiple partial declarations of a type exist (future feature), they must agree on visibility for overlapping members.


## 7. Expressions

Expressions produce values, references, or effects. Cloth evaluates expressions deterministically from left to right unless an operator states otherwise. Every expression has a static type (see Section 4) and follows the ownership semantics in Section 5 and in the Ownership & Lifetime Model (Section 11).

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

This is already solid — it just needs tightening, consistency, and a bit more “spec voice.” I cleaned it up to be more formal, removed redundancy, and aligned wording with the rest of your language style.

### 7.10 Lambda Expressions

Cloth supports lambda expressions using arrow syntax with a parenthesized parameter list.

#### Syntax

```
(params) -> expression
(params) -> { statements }
```

#### Examples

- Single expression: `(i32 x) -> x * 2`
- Multiple parameters: `(i32 a, i32 b) -> a + b`
- Block body:
```
(i32 x) -> {
  println(x);
  return x * 2;
}
```

#### Parameter Requirements

- All parameters **MUST** declare an explicit type.
- Valid: `(i32 x) -> x + 1`
- Invalid: `(x) -> x + 1`

#### Return Semantics

- Expression lambdas implicitly return the result of the expression:
- `(i32 x) -> x * 2`
- Block-bodied lambdas **MUST** use explicit `return` statements:
- `(i32 x) -> { return x * 2; }`

#### Type Inference

- The return type of a lambda is inferred from its body.
- The target callable type (e.g., delegate, interface, or trait) is inferred from context.

#### Interaction with Language Features

- Safe casts:
- `(i32 value) -> (value as? u32) ?? throw new NegativeNumberError("negative");`
- Null coalescing:
- `(i32? x) -> x ?? 0`
- Error-aware flow:
- `(i32 x) -> (x as? u32) ?? throw new NegativeNumberError("negative");`

Lambdas inherit `maybe` behavior from their body; explicit annotation is not required.

#### Passing Lambdas

```
numbers.map((i32 x) -> x * 2);
```

#### Capture Semantics

Lambda captures follow the ownership rules defined in Section 5.

- Capturing owned values transfers ownership into the lambda unless explicitly borrowed.
- Capturing references creates non-owning borrows.
- The compiler **MUST** ensure that captured references do not outlive their source.

#### Modifiers

Lambdas may carry modifiers such as `async` or `maybe`, consistent with function declarations.

#### Open Issues

- Callable type system (delegates, interfaces, traits)
- Explicit lambda return type syntax (if required)

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

## 8. Statements

Statements drive control flow, mutation, and structural composition. They execute in sequence unless redirected by control-flow constructs. Every statement obeys ownership, scope, and visibility rules defined in Sections 5 through 6 and inherits lifetime constraints from Section 11.

### 8.1 Statement Categories

Cloth groups statements into the following categories:

1. **Declaration statements** — Introduce new bindings (variables, constants, types) inside a scope.
2. **Assignment statements** — Rebind existing storage locations.
3. **Expression statements** — Evaluate expressions for their side effects.
4. **Control flow statements** — Direct execution (`if`, loops, jumps).
5. **Block statements** — `{ ... }` groupings with their own scope.
6. **Exception handling statements** — `try`, `catch`, `finally`, `throw`.
7. **Call statements** — Function or method calls used purely as statements (subset of expression statements).

Unless otherwise stated, statements evaluate to `void`.

### 8.2 Declaration Statements

- **Local variable declaration**: `Type name = expression;` or `var name = expression;`
  - `var` requires an initializer so the type can be inferred. Owned locals are destroyed at the end of the block unless ownership is transferred outward.
- **Constant declaration**: `const Type name = constant-expression;`
  - The initializer **MUST** be a compile-time constant. Constants inherit the storage domain (static vs. instance) where they are declared.
- **Multiple declarators**: `Type a = 0, b = 1;` declares each identifier with identical modifiers. Every declarator must honor initialization rules for its type.
- **Local type declarations** (nested classes, structs, enums) are permitted but scoped to the containing block. They follow the same ownership rules as top-level types described in Section 5.5.

### 8.3 Assignment Statements

- Syntax: `target assignment-operator expression;`
- Ownership semantics mirror Section 7.3: owned targets receive ownership, references rebind, shared targets update handles.
- Compound assignments (`+=`, `-=` …) evaluate the target once and require type support for the underlying operator.
- Assigning to `const`, `readonly`, or otherwise immutable bindings is a compile-time error.
- Future destructuring assignments are not yet defined; tuple-style left-hand sides are invalid in this revision.

### 8.4 Expression Statements

Any expression may appear as a statement provided the resulting value is either `void` or intentionally discarded:

```
callable(arguments);
(i32 x) -> x * 2; // valid if the lambda is immediately invoked or stored
```

- Pure literals or no-op expressions (e.g., `42;`) are invalid because they produce no observable effect.
- Discarding owned values without transfer triggers a compile-time error unless explicitly suppressed via `_ = expression;`.

### 8.5 Control Flow Statements

#### 8.5.1 Conditional Statements

- Syntax:
  ```
  if (condition) {
      statements
  } else if (condition) {
      statements
  } else {
      statements
  }
  ```
- `condition` must be `bool` and enclosed in parentheses. Each branch introduces its own block scope.
- Future versions will extend this section with `switch`/pattern matching semantics (**OPEN ISSUE: Switch design**).

#### 8.5.2 Iteration Statements

- **while**:
  ```
  while (condition) {
      statements
  }
  ```
- **do-while**:
  ```
  do {
      statements
  } while (condition);
  ```
- **for**:
  ```
  for (initializer; condition; iterator) {
      statements
  }
  ```
  - `initializer` may be a declaration or expression statement.
  - `condition` evaluates before each iteration; omitting it defaults to `true`.
  - `iterator` executes after each loop body completes.
- Loop variables declared in the initializer belong to the loop scope and are destroyed when the loop exits.

#### 8.5.3 Jump Statements

- `break;` — Exits the nearest enclosing loop or future `switch`.
- `continue;` — Skips to the next iteration of the nearest enclosing loop.
- `return expression?;` — Exits the current function or lambda, transferring ownership per Section 5.4.
- `fallthrough;` — Reserved keyword with no semantics yet (illegal to use).

### 8.6 Block Statements

- Syntax: `{ statement* }`
- Blocks introduce new scopes (see Section 6.1.1). Owned locals declared inside are destroyed in reverse order when the block exits unless moved elsewhere.
- Empty blocks are valid but discouraged unless explicitly required (e.g., placeholder handlers).

### 8.7 Exception Handling

#### 8.7.1 Throwing

- Syntax: `throw expression;`
- `expression` must evaluate to an error type declared in the surrounding function’s `maybe` clause or a standard error type.
- Throwing immediately transfers control to the nearest enclosing `catch` or propagates outward if unhandled.

#### 8.7.2 Handling

- Syntax:
  ```
  try {
      statements
  } catch (ErrorType name) {
      handler statements
  } catch (AnotherError name) {
      ...
  } finally {
      cleanup statements
  }
  ```
- `catch` clauses pattern match specific error types; they execute in order. Only one catch runs per throw.
- `finally` executes regardless of whether an error occurred. Owned resources released in `finally` follow the normal destruction order.
- `defer { ... }` remains an **OPEN ISSUE: Defer semantics** and is not yet part of the language.

### 8.8 Function and Method Calls as Statements

- Calls used solely for effects (`engine.start();`, `logger.log(message);`) may appear as standalone statements.
- Evaluation order follows Section 7.12. Arguments transfer ownership according to parameter markers.
- When a call statement returns a value, that value is discarded. Compilers **SHOULD** warn when discarding owned results unintentionally.

## 9. Type Definitions and Behavior

Types define the structure, behavior, and lifetime semantics of Cloth programs. This section expands upon Section 5.5 by describing how classes, structs, enums, and interfaces behave at runtime, how members are resolved, and how construction follows the ownership model codified in Section 11.

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
  - `public`, `internal`, `private` — visibility.
  - `final` — prohibits inheritance.
  - `abstract` — class cannot be instantiated directly; must provide abstract members for subclasses to override.
- Primary parameters initialize fields before the constructor body runs. Each primary parameter can be promoted to a field via `this.name = name;` or shorthand syntax (future extension).

#### 9.1.2 Inheritance Model

- Cloth supports single inheritance using `:>`:
  ```
  class Child :> Parent { ... }
  ```
- A class may inherit from at most one concrete base class but can implement multiple interfaces or traits (see Section 9.4).
- Constructors **MUST** invoke exactly one base constructor via `: base(arguments)`; omission defaults to the base parameterless constructor.
- Destructors run from most-derived to base after owned children are destroyed.

#### 9.1.3 Final, Prototype, Implementation, and Override Rules

- `final` members cannot be overridden.
- `prototype` (trait directive) declares a member signature that must be implemented in downstream classes.
- `implementation` indicates that a member fulfills a previously declared prototype.
- `override` marks members that replace base implementations; the compiler enforces signature compatibility.
- Attempting to override without `override` is a compile-time error. Marking a member as `override` without a matching base definition is also an error.

### 9.2 Structs

- Structs are value types stored inline. Syntax mirrors classes but omits inheritance (`struct Name { ... }`).
- Copy semantics:
  - Assigning a struct copies each field. For owned fields, the copy semantics follow the field type—if the type is not copyable, assignment is prohibited unless the struct implements a future copy trait (**OPEN ISSUE: Copy traits**).
- Structs cannot declare destructors; cleanup occurs when the struct’s owning scope ends.
- Struct methods may be marked `mutating` (future feature) to indicate they modify `this`.

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

### 9.4 Interfaces

- Interfaces declare method signatures, properties, and associated metadata without storage.
- Syntax: `interface Name { signature* }`
- Implementations:
  - Classes and structs declare `: interface1, interface2` to promise implementations.
  - Missing implementations are compile-time errors.
- Interfaces cannot contain fields. Default method bodies are not currently supported (**OPEN ISSUE: Interface default methods**).

### 9.5 Members

#### 9.5.1 Fields

- Unannotated fields are owned by their containing type.
- `static` fields live in the static lifetime domain and obey static initialization rules (Section 9.8).
- Field initializers execute before the constructor body in declaration order.

#### 9.5.2 Methods

- Instance methods implicitly receive `this`. The ownership of `this` depends on the declaration:
  - Regular methods receive an owned `this`.
  - Borrowed methods (future modifier) receive `&this`.
- Methods may declare `async`, `maybe`, `atomic`, and other modifiers consistent with Section 5.4.

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

### 9.6 Member Lookup and Resolution

- Lookup order:
  1. Members declared in the current type.
  2. Members inherited from base classes (unless hidden).
  3. Interface-provided members (requires explicit implementation mapping).
- Ambiguities (e.g., two interfaces define the same signature) must be resolved using explicit implementation syntax (`impl Interface.Method { ... }` — **OPEN ISSUE: Explicit interface impls**).
- Static members are resolved via the type name (`Type.member`). Instance members require an instance expression.

### 9.7 Shadowing and Overriding

- Declaring a member with the same name as an inherited member without `override` hides the base member and triggers a warning.
- `override` requires the base member be `virtual`, `abstract`, or `prototype`.
- Shadowing within the same type (e.g., nested type defines the same member name) is disallowed.

### 9.8 Initialization Order

1. Static initialization:
   - Static fields initialize in textual order the first time the module is loaded.
   - Circular static initialization is undefined behavior (**OPEN ISSUE: Detecting static cycles**).
2. Instance initialization:
   - Base constructor runs before derived field initializers and constructor body.
   - Field initializers execute in declaration order.
   - Constructor body executes last.

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

#### 9.9.2 Default Values

- Constructors may supply default parameter values:
  `public class Button(string label = "OK") { ... }`
- Defaults are evaluated at call site and must be constant expressions or references to static immutable data.

#### 9.9.3 Factory Patterns

- Factory methods (`public static func create(...)`) encapsulate construction. They must return owned instances and may reuse cached shared objects when appropriate.
- Factories may enforce invariants before exposing instances, aligning with the deterministic destruction model.

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

## 10. Functions and Methods

Functions and methods encapsulate reusable behavior. This section defines their syntax, signature rules, parameter passing, and dispatch semantics while reiterating how each construct must respect the ownership and lifetime guarantees from Section 11.

### 10.1 Function Signature

- General form:
  ```
  function-modifiers? func Name(parameter-list) :> return-type maybe clause? body
  ```
- Modifiers include `public`, `internal`, `private`, `static`, `async`, `atomic`, `override`, and `final` (for methods).
- The signature consists of the function name, ordered parameters, return type, and optional `maybe` clause (see Section 10.3).
- Overloads may exist when parameter type lists differ; name + parameter types + `maybe` clause constitute the signature.

### 10.2 Return Types

- All functions declare exactly one return type or `void`.
- Returning owned values transfers ownership to the caller.
- Returning references (`&Type`) requires proof that the referent outlives the call.
- Returning shared handles (`$Type`) follows the shared-domain rules.
- Multiple return values are not supported in this revision; use tuples (`(T1, T2)`) instead.

### 10.3 Maybe Clauses

- Syntax: `maybe ErrorType1, ErrorType2`
- Meaning: the function can either return the declared type or signal one of the listed errors.
- Callers must handle `maybe` results via `try/catch`, propagation, or expression-level operators (`??`, `as?`).
- Errors not listed in the `maybe` clause must not be thrown; doing so is undefined behavior.

### 10.4 Parameter Passing

- Parameters follow the declaration form `Type name` with explicit ownership markers:
  - `Type` (owned) — ownership transfers to the callee.
  - `&Type` (borrowed) — caller retains ownership; callee must not store beyond the call without explicit lifetime guarantees.
  - `$Type` (shared) — shared handle semantics.
- Default parameter values are allowed and are evaluated at the call site.
- `var` parameters (pass-by-reference) are not yet supported (**OPEN ISSUE: Pass-by-reference**).

### 10.5 Function Overloading

- Functions may overload based on parameter types and `maybe` clauses.
- Overloads must not differ solely by return type.
- Ambiguous overloads (where a call could match multiple signatures equally) are compile-time errors.
- Overloading respects visibility; private overloads are ignored outside their scope.

### 10.6 Method Binding and Dispatch

- Instance methods receive an implicit `this` parameter representing the owning object.
- Dispatch rules:
  - Non-virtual (default) methods bind statically; the compiler selects the implementation based on the static type.
- Methods marked `override` participate in dynamic dispatch (virtual dispatch). The runtime chooses the most-derived override that matches the call.
- `final` methods cannot be overridden and always dispatch statically.
- Interface methods require explicit implementations; dispatch occurs via the interface vtable.
- Method references (`Type::method`) capture either static or bound instance methods depending on context.

## 11. Ownership & Lifetime Reference

Cloth’s ownership semantics are defined in the companion **Cloth Ownership & Lifetime Model** document. This section summarizes the most important rules and explains how they interact with the syntax defined in Sections 5–10.

### 11.1 Normative Relationship

- The Ownership & Lifetime Model is authoritative for:
  - Relationship markers (`Type`, `&Type`, `$Type`).
  - Lifetime domains (ownership, shared, static).
  - Deterministic destruction, transfer rules, and acyclicity.
- When conflicts arise, the lifetime model governs runtime behavior; this specification governs syntax, typing, and compilation. Implementers **MUST** follow both documents simultaneously.

### 11.2 Principle Summary

1. **Exclusive ownership** — Each owned instance has exactly one owner. Transfers are explicit and must not introduce cycles.
2. **Borrowing** — `&Type` borrows do not extend lifetime; they are valid only within the lexical scope that guarantees the referent remains alive.
3. **Shared domain** — `$Type` handles live outside the ownership tree and use managed lifetimes (e.g., reference counting). They enable graphs that would otherwise violate acyclicity.
4. **Static domain** — `static` members and constants exist for the lifetime of the process; they never participate in ownership transfers.
5. **Deterministic destruction** — Owned children destroy before their parent; destructors run afterward and must not resurrect objects.

### 11.3 Integration Points

- Section 5 maps declarations to ownership markers and storage domains.
- Section 6 ensures scopes prevent references from escaping their lifetimes.
- Sections 7–8 enforce ownership during expression evaluation and control flow (e.g., moves, `??`, safe casts).
- Section 9 applies the ownership model to type construction, destruction, and member lookup.
- Section 10 propagates ownership through parameter passing, return types, and `maybe` clauses.

### 11.4 Using the Ownership Model

- Treat the Ownership & Lifetime Model as a normative companion. Whenever code manipulates ownership (creating objects, transferring references, sharing handles), consult that document for the precise runtime constraints.
- Future language extensions must update both this specification and the lifetime model to remain consistent.

## 12. Program Execution Model

The execution model translates the static semantics from Sections 3-11 into observable runtime behavior. It specifies how a compiled artifact identifies its entrypoint, constructs the root ownership object, runs user code, and tears everything down deterministically. Unless stated otherwise, requirements in this section apply to every compiler, linker, and runtime environment capable of producing or executing runnable Cloth programs.

### 12.1 Entrypoint Resolution

Implementations MUST determine the entrypoint class before code generation completes.

1. The build manifest (Section 13) or command-line options may declare a fully qualified entrypoint type via `project.entry`. When a specific build target is selected, that target’s `entry` field (see Section 13.6) overrides `project.entry`. If either source specifies an entrypoint, that value takes precedence over heuristic discovery.
2. If no explicit entrypoint is supplied, implementations MUST look for a type named `Main` in the root module of the build target. Exactly one matching declaration MUST exist; zero or multiple matches are compile-time errors.
3. The resolved entrypoint MUST be a top-level `public class`, non-generic, non-abstract, and visible under the rules in Section 6.4.
4. The entrypoint type MUST satisfy the constructor rules in Section 12.3. If no valid constructor exists, entrypoint resolution fails with a diagnostic.

Entrypoint resolution occurs after import resolution (Section 3.4) so that every module path is finalized before the main class name is interpreted.

### 12.2 Main Class

The selected entrypoint class is referred to as `Main` for the remainder of this section, regardless of its actual identifier. `Main` anchors the dynamic ownership tree described in Section 11.

- `Main` MUST be instantiated exactly once for each process invocation. The resulting instance becomes the root owner for every other owned object created during execution unless those objects explicitly enter the shared or static lifetime domains.
- `Main` MUST be declared as a concrete `class`. Structs, enums, interfaces, and prototypes cannot serve as the entrypoint.
- `Main` MAY implement interfaces or inherit from other classes, but it MUST remain visible and instantiable without additional framework code. Base constructors run according to Section 9.8 before the entry constructor body executes.
- `Main` may declare static members; they initialize according to the static rules in Section 9.8 before the runtime attempts to instantiate the class.
- Because `Main` defines the root ownership scope, destroying the `Main` instance triggers deterministic teardown of the entire owned object tree.

### 12.3 Main Constructor

The runtime instantiates `Main` by invoking its designated entry constructor.

- There MUST be exactly one accessible constructor whose parameter list matches what the runtime can supply. Today the runtime only guarantees a zero-argument constructor; additional parameters require explicit future standardization.
- Primary parameters on the class declaration MAY be used to capture environment values. The only standardized primary parameter is `string[] args`, which receives the process command-line exactly once before any constructor body executes.
- Additional constructors may exist, but the runtime never invokes them automatically. Programs requiring alternative initialization paths MUST delegate from the entry constructor.
- The entry constructor MAY declare a `maybe` clause (Section 10.3). If it throws or propagates an error, the process MUST terminate with a non-zero exit status after owned resources are destroyed.
- The entry constructor MUST be `public` or otherwise accessible to the build target; private or internal constructors cannot be selected as the entrypoint.

### 12.4 Initialization Flow

Cloth runtimes MUST follow the initialization order below. Each phase completes before the next begins.

1. **Module validation** - Resolve modules, imports, and cyclic dependencies as described in Section 3. All syntax and semantic checks complete in this phase.
2. **Static initialization** - Evaluate `static` fields, constants, and module-level initializers respecting the ordering guarantees from Section 9.8. Side effects that escape this phase are observable only through the static domain.
3. **Entrypoint binding** - Apply Section 12.1 to select the `Main` type and verify constructor availability.
4. **Root construction** - Allocate the `Main` instance, supply standardized primary parameters (e.g., `string[] args`), run base constructors, field initializers, and finally the entry constructor body. Execution of user code begins at the first statement of this body.
5. **Steady state** - Program behavior is entirely user-defined. Long-running services typically block inside the `Main` constructor or delegate to dedicated event loops or threads.
6. **Shutdown** - When the entry constructor returns or an uncaught `maybe` error escapes, the runtime triggers deterministic destruction: owned children tear down depth-first, then the `Main` destructor (if declared) runs. The process exits with status `0` on success or an implementation-defined non-zero value on failure.

Runtimes MUST NOT skip, reorder, or interleave these steps, ensuring every conforming executable presents a predictable startup and shutdown sequence.

## 13. Build System

This section defines the manifest contracts required to produce conforming Cloth binaries. While tooling MAY offer higher level workflows (IDEs, project generators, CI integrations), every implementation MUST understand the `build.toml` manifest and honor the rules below before it emits executable code.

### 13.1 `build.toml` Overview

- `build.toml` MUST live at the root of the workspace passed to the compiler or build driver. Relative paths inside the manifest are resolved against this directory.
- The manifest is encoded in UTF-8 without a byte-order mark and uses standard TOML 1.0 syntax. Parsers MUST reject malformed manifests before attempting to compile source files.
- Unknown tables or keys MAY be ignored, but implementations MUST preserve the semantics of all standardized keys described in Sections 13.2-13.6.
- When multiple manifests are present (for example, workspaces with nested packages), the explicit manifest path chosen via CLI overrides automatic discovery. If no file is found, the build MUST fail.

### 13.2 Required Sections

Every conforming manifest MUST provide `[project]` and `[build]`. All other sections are optional.

#### 13.2.1 `[project]`

The `[project]` table defines the package identity and default entry target.

- `name` (required) is a non-empty string used in diagnostics, dependency graphs, and cache directories. It MUST obey the identifier grammar from Section 2.5 (dots are permitted to express namespaces).
- `version` (required) is a non-empty semantic-version string. Changing `version` MUST NOT silently alter compilation semantics beyond what is implied by a new release.
- `entry` (required) is a fully qualified `module.path.Type` identifying the entrypoint consumed by Section 12. No other field may contradict this value.

Optional metadata fields include `edition`, `authors`, `description`, `license`, `repository`, and `homepage`. These keys are informative only and MUST NOT influence semantics. Projects MAY also set `module_root`; when omitted, it inherits from `build.source_dir`.

Implementations MUST reject manifests that attempt to describe the entrypoint through any mechanism other than `[project].entry` (for example, a file-based `main_file` requirement).

#### 13.2.2 `[build]`

The `[build]` table specifies source layout and compiler behavior. Paths are relative to the manifest unless absolute.

- `source_dir` (required) points to the directory scanned for modules. Implementations **MUST** auto-discover modules within this tree; manual file enumeration is never required.
- `output_dir` (required) is the directory where build artifacts and intermediate results are written.

Optional fields include `profile`, `target`, `emit`, `artifact_dir`, `cache_dir`, and `warnings_as_errors`. When omitted, implementations MAY supply sensible defaults (e.g., `profile = "debug"`, `target = "native"`, `emit = ["binary"]`). The `main_file` key MAY appear for tooling assistance but MUST remain optional and MUST NOT participate in entrypoint selection.

Manifest-defined search paths MUST NOT escape the workspace root unless the user opts in via tooling flags. When two files resolve to the same module name inside `source_dir`, the build MUST fail rather than pick one arbitrarily.

### 13.3 Optional Sections

Sections beyond `[project]` and `[build]` MAY be omitted. When absent, implementations continue with conservative defaults.

#### 13.3.1 `[dependencies]`

Dependencies are optional. Manifests with no external dependencies SHOULD omit this section entirely.

- Each entry MUST be written as an inline table (`name = { ... }`). Shorthand string forms (`name = "1.2.3"`) are invalid because they provide no room for future metadata.
- Exactly one source attribute is permitted per dependency:
  - `version` selects a registry release and follows semantic version ranges.
  - `path` points to a workspace-relative directory containing another `build.toml`. Paths outside the workspace REQUIRE an additional opt-in flag (implementation-defined).
  - `git` specifies a remote repository; implementations MAY accept optional `rev`, `tag`, or `branch` keys alongside `git`.
- Optional attributes:
  - `features` (array of strings) enables dependency features when supported.
  - `optional` (boolean) marks the dependency as feature-gated; tooling MUST NOT treat optional dependencies as linked unless a feature activates them.
  - `side = "tool"` marks tooling-only dependencies that do not participate in the runtime module graph.
- Version requirements follow semantic version ranges. Implementations MUST resolve every dependency to exactly one version per build, unless `side = "tool"` explicitly permits separate tool graphs.
- Path dependencies MUST resolve to existing manifests and inherit the same validation rules as the root project.
- Dependency resolution MUST be deterministic. When multiple versions satisfy the constraints, the compiler chooses the highest compatible version unless a lock file (`build.lock`) pins a specific revision. Lock files are advisory but SHOULD be honored when present.
- Circular dependencies between packages are disallowed unless every edge in the cycle is marked `side = "tool"`. Implementations detect and report other cycles before compiling code.

#### 13.3.2 `[profiles.<name>]`

Profiles customize optimization pipelines and debug features without forcing users to duplicate manifests. Each `[profiles.<name>]` table MAY override any subset of `[build]` keys. Conforming implementations MUST support at least `debug` and `release`.

- Common fields include `optimization` (`"none"`, `"standard"`, `"aggressive"`), `debug_symbols` (boolean), `strip` (boolean), `incremental` (boolean), and `overflow_checks` (boolean).
- Unspecified keys inherit the value from `[build]`. For example, if `[build]` sets `warnings_as_errors = false` and `[profiles.release]` omits it, release builds remain warning-tolerant.
- When a profile introduces an unrecognized key, the compiler MUST emit a diagnostic rather than silently ignoring it.
- Toolchains MAY expose CLI switches (e.g., `--profile release`) to select the active profile. The value recorded in `build.profile` remains the default when no CLI override is provided.

#### 13.3.3 `[targets.<name>]`

Targets describe the concrete artifacts a project can emit. Each `[targets.<name>]` table refines or augments the base configuration.

- `kind` classifies the artifact (`"executable"`, `"library"`, `"test"`, `"docs"`, etc.). Unsupported kinds MUST result in diagnostics.
- `entry` overrides `project.entry` for the selected target. Executable targets MUST provide either this field or rely on the project-level entry.
- `source_dir`, `output_dir`, and `emit` entries MAY override the corresponding `[build]` values for that target only. This enables doc/test targets to compile from alternate trees without rewriting the base configuration.
- `dependencies` (optional nested table) can declare target-specific dependencies (e.g., test-only libraries). When present, the compiler MUST merge these dependencies with the root `[dependencies]` before resolution.
- Implementations SHOULD provide a default executable target derived from `[project].entry` when no `[targets.*]` tables exist. When multiple targets are declared, build tooling MUST require the caller to specify which target to build.

Advanced build partitioning mechanisms such as `[[units]]` remain an **OPEN ISSUE: Explicit compilation units**. Until standardized, toolchains MUST rely on automatic module discovery informed by `[build]` and `[targets.*]`.

### 13.4 Minimal Valid Manifest

A manifest containing only the two required sections remains conforming:

```
[project]
name = "notebook"
version = "0.1.0"
entry = "app.main.Main"

[build]
source_dir = "src"
output_dir = "build"
```

Declaring multiple entry sources (e.g., providing both `[project].entry` and a contradictory `main_file`) is invalid and MUST trigger a diagnostic referencing the conflicting fields.
