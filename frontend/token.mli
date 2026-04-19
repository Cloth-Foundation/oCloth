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

val make : kind:token_kind -> lexeme:string -> span:Source_span.t -> t
val kind : t -> token_kind
val lexeme : t -> string
val span : t -> Source_span.t
val is_eof : t -> bool
val compare : t -> t -> int
val keyword_of_string : string -> token_kind option
val meta_of_string : string -> meta_kind option
val to_string : t -> string
