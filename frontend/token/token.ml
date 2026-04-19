type keyword =
  | Kw_true
  | Kw_false
  | Kw_null
  | Kw_NaN
  | Kw_if
  | Kw_else
  | Kw_switch
  | Kw_case
  | Kw_default
  | Kw_for
  | Kw_while
  | Kw_do
  | Kw_break
  | Kw_continue
  | Kw_yield
  | Kw_return
  | Kw_throw
  | Kw_try
  | Kw_catch
  | Kw_finally
  | Kw_defer
  | Kw_await
  | Kw_and
  | Kw_or
  | Kw_is
  | Kw_in
  | Kw_as
  | Kw_maybe
  | Kw_public
  | Kw_private
  | Kw_internal
  | Kw_static
  | Kw_shared
  | Kw_owned
  | Kw_const
  | Kw_var
  | Kw_get
  | Kw_set
  | Kw_async
  | Kw_atomic
  | Kw_module
  | Kw_import
  | Kw_class
  | Kw_struct
  | Kw_enum
  | Kw_interface
  | Kw_trait
  | Kw_type
  | Kw_func
  | Kw_new
  | Kw_delete
  | Kw_this
  | Kw_super
  | Kw_bit
  | Kw_bool
  | Kw_char
  | Kw_byte
  | Kw_i8
  | Kw_i16
  | Kw_i32
  | Kw_i64
  | Kw_u8
  | Kw_u16
  | Kw_u32
  | Kw_u64
  | Kw_f32
  | Kw_f64
  | Kw_float
  | Kw_double
  | Kw_real
  | Kw_long
  | Kw_short
  | Kw_int
  | Kw_uint
  | Kw_unsigned
  | Kw_void
  | Kw_any
  | Kw_string
  | Kw_Override
  | Kw_Implementation
  | Kw_Prototype
  | Kw_Deprecated
  | Kw_ALIGNOF
  | Kw_DEFAULT
  | Kw_LENGTH
  | Kw_MAX
  | Kw_MEMSPACE
  | Kw_MIN
  | Kw_SIZEOF
  | Kw_TO_BITS
  | Kw_TO_BYTES
  | Kw_TO_STRING
  | Kw_TYPEOF

type literal =
  | IntegerLiteral of string
  | FloatLiteral of string
  | StringLiteral of string
  | CharLiteral of string
  | BitLiteral of string
  | BooleanLiteral of bool
  | NullLiteral
  | NaNLiteral

type operator_punctuation =
  | Op_DotDotDot
  | Op_DotDot
  | Op_ColonColon
  | Op_ReturnArrow
  | Op_Arrow
  | Op_Fallback
  | Op_PlusPlus
  | Op_MinusMinus
  | Op_Equal
  | Op_PlusEqual
  | Op_MinusEqual
  | Op_StarEqual
  | Op_SlashEqual
  | Op_PercentEqual
  | Op_AmpEqual
  | Op_PipeEqual
  | Op_CaretEqual
  | Op_EqualEqual
  | Op_BangEqual
  | Op_Less
  | Op_Greater
  | Op_LessEqual
  | Op_GreaterEqual
  | Op_Plus
  | Op_Minus
  | Op_Star
  | Op_Slash
  | Op_Percent
  | Op_Amp
  | Op_Pipe
  | Op_Caret
  | Op_Tilde
  | Op_Bang
  | Op_Dot
  | Op_Comma
  | Op_Semicolon
  | Op_Colon
  | Op_LParen
  | Op_RParen
  | Op_LBrace
  | Op_RBrace
  | Op_LBracket
  | Op_RBracket
  | Op_At
  | Op_Hash
  | Op_Dollar
  | Op_Question
  | Op_Backtick

type meta_kind =
  | ALIGNOF
  | DEFAULT
  | LENGTH
  | MAX
  | MEMSPACE
  | MIN
  | SIZEOF
  | TO_BITS
  | TO_BYTES
  | TO_STRING
  | TYPEOF

type token_kind =
  | Identifier of string
  | Keyword of keyword
  | Literal of literal
  | OperatorPunctuation of operator_punctuation
  | Meta of meta_kind
  | EOF
  | UNKNOWN

type t = {
  kind : token_kind;
  lexeme : string;
  span : Source_span.t;
}

let make ~kind ~lexeme ~span = { kind; lexeme; span }
let kind token = token.kind
let lexeme token = token.lexeme
let span token = token.span
let is_eof token = match token.kind with EOF -> true | _ -> false

let compare a b = Source_location.compare a.span.start b.span.start

let keyword_table : (string * keyword) list =
  [ ("true", Kw_true); ("false", Kw_false); ("null", Kw_null); ("NaN", Kw_NaN)
  ; ("if", Kw_if); ("else", Kw_else); ("switch", Kw_switch); ("case", Kw_case)
  ; ("default", Kw_default); ("for", Kw_for); ("while", Kw_while); ("do", Kw_do)
  ; ("break", Kw_break); ("continue", Kw_continue); ("yield", Kw_yield)
  ; ("return", Kw_return); ("throw", Kw_throw); ("try", Kw_try)
  ; ("catch", Kw_catch); ("finally", Kw_finally); ("defer", Kw_defer)
  ; ("await", Kw_await); ("and", Kw_and); ("or", Kw_or); ("is", Kw_is)
  ; ("in", Kw_in); ("as", Kw_as); ("maybe", Kw_maybe); ("public", Kw_public)
  ; ("private", Kw_private); ("internal", Kw_internal); ("static", Kw_static)
  ; ("shared", Kw_shared); ("owned", Kw_owned); ("const", Kw_const)
  ; ("var", Kw_var); ("get", Kw_get); ("set", Kw_set); ("async", Kw_async)
  ; ("atomic", Kw_atomic); ("module", Kw_module); ("import", Kw_import)
  ; ("class", Kw_class); ("struct", Kw_struct); ("enum", Kw_enum)
  ; ("interface", Kw_interface); ("trait", Kw_trait); ("type", Kw_type)
  ; ("func", Kw_func); ("new", Kw_new); ("delete", Kw_delete); ("this", Kw_this)
  ; ("super", Kw_super); ("bit", Kw_bit); ("bool", Kw_bool); ("char", Kw_char)
  ; ("byte", Kw_byte); ("i8", Kw_i8); ("i16", Kw_i16); ("i32", Kw_i32)
  ; ("i64", Kw_i64); ("u8", Kw_u8); ("u16", Kw_u16); ("u32", Kw_u32)
  ; ("u64", Kw_u64); ("f32", Kw_f32); ("f64", Kw_f64); ("float", Kw_float)
  ; ("double", Kw_double); ("real", Kw_real); ("long", Kw_long)
  ; ("short", Kw_short); ("int", Kw_int); ("uint", Kw_uint)
  ; ("unsigned", Kw_unsigned); ("void", Kw_void); ("any", Kw_any)
  ; ("string", Kw_string); ("Override", Kw_Override)
  ; ("Implementation", Kw_Implementation); ("Prototype", Kw_Prototype)
  ; ("Deprecated", Kw_Deprecated); ("ALIGNOF", Kw_ALIGNOF)
  ; ("DEFAULT", Kw_DEFAULT); ("LENGTH", Kw_LENGTH); ("MAX", Kw_MAX)
  ; ("MEMSPACE", Kw_MEMSPACE); ("MIN", Kw_MIN); ("SIZEOF", Kw_SIZEOF)
  ; ("TO_BITS", Kw_TO_BITS); ("TO_BYTES", Kw_TO_BYTES)
  ; ("TO_STRING", Kw_TO_STRING); ("TYPEOF", Kw_TYPEOF)
  ]

let keyword_of_string text =
  match List.find_opt (fun (lexeme, _) -> String.equal lexeme text) keyword_table with
  | Some (_, kw) -> Some (Keyword kw)
  | None -> None

let meta_of_string = function
  | "ALIGNOF" -> Some ALIGNOF
  | "DEFAULT" -> Some DEFAULT
  | "LENGTH" -> Some LENGTH
  | "MAX" -> Some MAX
  | "MEMSPACE" -> Some MEMSPACE
  | "MIN" -> Some MIN
  | "SIZEOF" -> Some SIZEOF
  | "TO_BITS" -> Some TO_BITS
  | "TO_BYTES" -> Some TO_BYTES
  | "TO_STRING" -> Some TO_STRING
  | "TYPEOF" -> Some TYPEOF
  | _ -> None

let string_of_keyword = function
  | Kw_true -> "Kw_true"
  | Kw_false -> "Kw_false"
  | Kw_null -> "Kw_null"
  | Kw_NaN -> "Kw_NaN"
  | Kw_if -> "Kw_if"
  | Kw_else -> "Kw_else"
  | Kw_switch -> "Kw_switch"
  | Kw_case -> "Kw_case"
  | Kw_default -> "Kw_default"
  | Kw_for -> "Kw_for"
  | Kw_while -> "Kw_while"
  | Kw_do -> "Kw_do"
  | Kw_break -> "Kw_break"
  | Kw_continue -> "Kw_continue"
  | Kw_yield -> "Kw_yield"
  | Kw_return -> "Kw_return"
  | Kw_throw -> "Kw_throw"
  | Kw_try -> "Kw_try"
  | Kw_catch -> "Kw_catch"
  | Kw_finally -> "Kw_finally"
  | Kw_defer -> "Kw_defer"
  | Kw_await -> "Kw_await"
  | Kw_and -> "Kw_and"
  | Kw_or -> "Kw_or"
  | Kw_is -> "Kw_is"
  | Kw_in -> "Kw_in"
  | Kw_as -> "Kw_as"
  | Kw_maybe -> "Kw_maybe"
  | Kw_public -> "Kw_public"
  | Kw_private -> "Kw_private"
  | Kw_internal -> "Kw_internal"
  | Kw_static -> "Kw_static"
  | Kw_shared -> "Kw_shared"
  | Kw_owned -> "Kw_owned"
  | Kw_const -> "Kw_const"
  | Kw_var -> "Kw_var"
  | Kw_get -> "Kw_get"
  | Kw_set -> "Kw_set"
  | Kw_async -> "Kw_async"
  | Kw_atomic -> "Kw_atomic"
  | Kw_module -> "Kw_module"
  | Kw_import -> "Kw_import"
  | Kw_class -> "Kw_class"
  | Kw_struct -> "Kw_struct"
  | Kw_enum -> "Kw_enum"
  | Kw_interface -> "Kw_interface"
  | Kw_trait -> "Kw_trait"
  | Kw_type -> "Kw_type"
  | Kw_func -> "Kw_func"
  | Kw_new -> "Kw_new"
  | Kw_delete -> "Kw_delete"
  | Kw_this -> "Kw_this"
  | Kw_super -> "Kw_super"
  | Kw_bit -> "Kw_bit"
  | Kw_bool -> "Kw_bool"
  | Kw_char -> "Kw_char"
  | Kw_byte -> "Kw_byte"
  | Kw_i8 -> "Kw_i8"
  | Kw_i16 -> "Kw_i16"
  | Kw_i32 -> "Kw_i32"
  | Kw_i64 -> "Kw_i64"
  | Kw_u8 -> "Kw_u8"
  | Kw_u16 -> "Kw_u16"
  | Kw_u32 -> "Kw_u32"
  | Kw_u64 -> "Kw_u64"
  | Kw_f32 -> "Kw_f32"
  | Kw_f64 -> "Kw_f64"
  | Kw_float -> "Kw_float"
  | Kw_double -> "Kw_double"
  | Kw_real -> "Kw_real"
  | Kw_long -> "Kw_long"
  | Kw_short -> "Kw_short"
  | Kw_int -> "Kw_int"
  | Kw_uint -> "Kw_uint"
  | Kw_unsigned -> "Kw_unsigned"
  | Kw_void -> "Kw_void"
  | Kw_any -> "Kw_any"
  | Kw_string -> "Kw_string"
  | Kw_Override -> "Kw_Override"
  | Kw_Implementation -> "Kw_Implementation"
  | Kw_Prototype -> "Kw_Prototype"
  | Kw_Deprecated -> "Kw_Deprecated"
  | Kw_ALIGNOF -> "Kw_ALIGNOF"
  | Kw_DEFAULT -> "Kw_DEFAULT"
  | Kw_LENGTH -> "Kw_LENGTH"
  | Kw_MAX -> "Kw_MAX"
  | Kw_MEMSPACE -> "Kw_MEMSPACE"
  | Kw_MIN -> "Kw_MIN"
  | Kw_SIZEOF -> "Kw_SIZEOF"
  | Kw_TO_BITS -> "Kw_TO_BITS"
  | Kw_TO_BYTES -> "Kw_TO_BYTES"
  | Kw_TO_STRING -> "Kw_TO_STRING"
  | Kw_TYPEOF -> "Kw_TYPEOF"

let string_of_literal = function
  | IntegerLiteral text -> "IntegerLiteral(" ^ text ^ ")"
  | FloatLiteral text -> "FloatLiteral(" ^ text ^ ")"
  | StringLiteral text -> "StringLiteral(" ^ text ^ ")"
  | CharLiteral text -> "CharLiteral(" ^ text ^ ")"
  | BitLiteral text -> "BitLiteral(" ^ text ^ ")"
  | BooleanLiteral value -> "BooleanLiteral(" ^ string_of_bool value ^ ")"
  | NullLiteral -> "NullLiteral"
  | NaNLiteral -> "NaNLiteral"

let string_of_operator_punctuation = function
  | Op_DotDotDot -> "Op_DotDotDot"
  | Op_DotDot -> "Op_DotDot"
  | Op_ColonColon -> "Op_ColonColon"
  | Op_ReturnArrow -> "Op_ReturnArrow"
  | Op_Arrow -> "Op_Arrow"
  | Op_Fallback -> "Op_Fallback"
  | Op_PlusPlus -> "Op_PlusPlus"
  | Op_MinusMinus -> "Op_MinusMinus"
  | Op_Equal -> "Op_Equal"
  | Op_PlusEqual -> "Op_PlusEqual"
  | Op_MinusEqual -> "Op_MinusEqual"
  | Op_StarEqual -> "Op_StarEqual"
  | Op_SlashEqual -> "Op_SlashEqual"
  | Op_PercentEqual -> "Op_PercentEqual"
  | Op_AmpEqual -> "Op_AmpEqual"
  | Op_PipeEqual -> "Op_PipeEqual"
  | Op_CaretEqual -> "Op_CaretEqual"
  | Op_EqualEqual -> "Op_EqualEqual"
  | Op_BangEqual -> "Op_BangEqual"
  | Op_Less -> "Op_Less"
  | Op_Greater -> "Op_Greater"
  | Op_LessEqual -> "Op_LessEqual"
  | Op_GreaterEqual -> "Op_GreaterEqual"
  | Op_Plus -> "Op_Plus"
  | Op_Minus -> "Op_Minus"
  | Op_Star -> "Op_Star"
  | Op_Slash -> "Op_Slash"
  | Op_Percent -> "Op_Percent"
  | Op_Amp -> "Op_Amp"
  | Op_Pipe -> "Op_Pipe"
  | Op_Caret -> "Op_Caret"
  | Op_Tilde -> "Op_Tilde"
  | Op_Bang -> "Op_Bang"
  | Op_Dot -> "Op_Dot"
  | Op_Comma -> "Op_Comma"
  | Op_Semicolon -> "Op_Semicolon"
  | Op_Colon -> "Op_Colon"
  | Op_LParen -> "Op_LParen"
  | Op_RParen -> "Op_RParen"
  | Op_LBrace -> "Op_LBrace"
  | Op_RBrace -> "Op_RBrace"
  | Op_LBracket -> "Op_LBracket"
  | Op_RBracket -> "Op_RBracket"
  | Op_At -> "Op_At"
  | Op_Hash -> "Op_Hash"
  | Op_Dollar -> "Op_Dollar"
  | Op_Question -> "Op_Question"
  | Op_Backtick -> "Op_Backtick"

let string_of_meta_kind = function
  | ALIGNOF -> "ALIGNOF"
  | DEFAULT -> "DEFAULT"
  | LENGTH -> "LENGTH"
  | MAX -> "MAX"
  | MEMSPACE -> "MEMSPACE"
  | MIN -> "MIN"
  | SIZEOF -> "SIZEOF"
  | TO_BITS -> "TO_BITS"
  | TO_BYTES -> "TO_BYTES"
  | TO_STRING -> "TO_STRING"
  | TYPEOF -> "TYPEOF"

let string_of_token_kind = function
  | Identifier name -> "Identifier(" ^ name ^ ")"
  | Keyword keyword -> "Keyword(" ^ string_of_keyword keyword ^ ")"
  | Literal literal -> "Literal(" ^ string_of_literal literal ^ ")"
  | OperatorPunctuation op ->
      "OperatorPunctuation(" ^ string_of_operator_punctuation op ^ ")"
  | Meta meta -> "Meta(" ^ string_of_meta_kind meta ^ ")"
  | EOF -> "EOF"
  | UNKNOWN -> "UNKNOWN"

let to_string token =
  Format.sprintf "{kind=%s; lexeme=%S; span=%s}"
    (string_of_token_kind token.kind)
    token.lexeme
    (Source_span.to_string token.span)
