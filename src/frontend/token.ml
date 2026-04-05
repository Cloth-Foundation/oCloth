module Token = struct

  type position = {
    offset: int;
    line: int;
    column: int;
  }

  type span = {
    start_pos: position;
    end_pos: position;
  }

  type kind =
    | Identifier of string
    | Keyword of string
    | Symbol of string
    | Integer of int
    | Float of float
    | String of string
    | Keyword_And
    | Keyword_Any
    | Keyword_As
    | Keyword_Async
    | Keyword_Atomic
    | Keyword_Await
    | Keyword_Bit
    | Keyword_Bool
    | Keyword_Break
    | Keyword_Byte
    | Keyword_Case
    | Keyword_Catch
    | Keyword_Char
    | Keyword_Class
    | Keyword_Const
    | Keyword_Continue
    | Keyword_Defer
    | Keyword_Default
    | Keyword_Delete
    | Keyword_Do
    | Keyword_Double
    | Keyword_Else
    | Keyword_Enum
    | Keyword_F32
    | Keyword_F64
    | Keyword_False
    | Keyword_Finally
    | Keyword_Float
    | Keyword_For
    | Keyword_Func
    | Keyword_Get
    | Keyword_I16
    | Keyword_I32
    | Keyword_I64
    | Keyword_I8
    | Keyword_If
    | Keyword_Import
    | Keyword_In
    | Keyword_Interface
    | Keyword_Internal
    | Keyword_Is
    | Keyword_Long
    | Keyword_Maybe
    | Keyword_Module
    | Keyword_New
    | Keyword_Null
    | Keyword_Or
    | Keyword_Owned
    | Keyword_Private
    | Keyword_Public
    | Keyword_Real
    | Keyword_Return
    | Keyword_Set
    | Keyword_Shared
    | Keyword_Short
    | Keyword_Static
    | Keyword_Struct
    | Keyword_Super
    | Keyword_Switch
    | Keyword_This
    | Keyword_Throw
    | Keyword_True
    | Keyword_Try
    | Keyword_Type
    | Keyword_U16
    | Keyword_U32
    | Keyword_U64
    | Keyword_U8
    | Keyword_Var
    | Keyword_Void
    | Keyword_While
    | Keyword_Yield
    | Keyword_NaN
    | Keyword_Trait
    | Keyword_Trait_Override
    | Keyword_Trait_Implementation
    | Keyword_Trait_Prototype
    | Keyword_Trait_Deprecated
    | OP_Plus
    | OP_Minus
    | OP_Star
    | OP_Slash
    | OP_Percent
    | OP_PlusPlus
    | OP_MinusMinus
    | OP_Assign
    | OP_PlusAssign
    | OP_MinusAssign
    | OP_StarAssign
    | OP_SlashAssign
    | OP_PercentAssign
    | OP_Equal
    | OP_NotEqual
    | OP_Less
    | OP_LessEqual
    | OP_Greater
    | OP_GreaterEqual
    | OP_Ampersand
    | OP_Pipe
    | OP_Caret
    | OP_Bang
    | OP_Tilde
    | OP_Dot
    | OP_Comma
    | OP_Semicolon
    | OP_Colon
    | OP_ReturnArrow
    | OP_Arrow
    | OP_LeftParen
    | OP_RightParen
    | OP_LeftBrace
    | OP_RightBrace
    | OP_LeftBracket
    | OP_RightBracket
    | OP_At
    | OP_Hash
    | OP_Dollar
    | OP_Question
    | OP_Backtick
    | OP_Fallback
    | OP_ColonColon
    | OP_DotDot
    | OP_DotDotDot
    | EndOfFile

  type t = {
    kind: kind;
    lexeme: string;
    span: span;
  }

  let make ~kind ~lexeme ~span = { kind; lexeme; span }

  let kind_to_string = function
    | Identifier s -> "Identifier(" ^ s ^ ")"
    | Keyword s -> "Keyword(" ^ s ^ ")"
    | Symbol s -> "Symbol(" ^ s ^ ")"
    | Integer i -> "Integer(" ^ string_of_int i ^ ")"
    | Float f -> "Float(" ^ string_of_float f ^ ")"
    | String s -> "String(" ^ s ^ ")"
    | Keyword_And -> "Keyword_And"
    | Keyword_Any -> "Keyword_Any"
    | Keyword_As -> "Keyword_As"
    | Keyword_Async -> "Keyword_Async"
    | Keyword_Atomic -> "Keyword_Atomic"
    | Keyword_Await -> "Keyword_Await"
    | Keyword_Bit -> "Keyword_Bit"
    | Keyword_Bool -> "Keyword_Bool"
    | Keyword_Break -> "Keyword_Break"
    | Keyword_Byte -> "Keyword_Byte"
    | Keyword_Case -> "Keyword_Case"
    | Keyword_Catch -> "Keyword_Catch"
    | Keyword_Char -> "Keyword_Char"
    | Keyword_Class -> "Keyword_Class"
    | Keyword_Const -> "Keyword_Const"
    | Keyword_Continue -> "Keyword_Continue"
    | Keyword_Defer -> "Keyword_Defer"
    | Keyword_Default -> "Keyword_Default"
    | Keyword_Delete -> "Keyword_Delete"
    | Keyword_Do -> "Keyword_Do"
    | Keyword_Double -> "Keyword_Double"
    | Keyword_Else -> "Keyword_Else"
    | Keyword_Enum -> "Keyword_Enum"
    | Keyword_F32 -> "Keyword_F32"
    | Keyword_F64 -> "Keyword_F64"
    | Keyword_False -> "Keyword_False"
    | Keyword_Finally -> "Keyword_Finally"
    | Keyword_Float -> "Keyword_Float"
    | Keyword_For -> "Keyword_For"
    | Keyword_Func -> "Keyword_Func"
    | Keyword_Get -> "Keyword_Get"
    | Keyword_I16 -> "Keyword_I16"
    | Keyword_I32 -> "Keyword_I32"
    | Keyword_I64 -> "Keyword_I64"
    | Keyword_I8 -> "Keyword_I8"
    | Keyword_If -> "Keyword_If"
    | Keyword_Import -> "Keyword_Import"
    | Keyword_In -> "Keyword_In"
    | Keyword_Interface -> "Keyword_Interface"
    | Keyword_Internal -> "Keyword_Internal"
    | Keyword_Is -> "Keyword_Is"
    | Keyword_Long -> "Keyword_Long"
    | Keyword_Maybe -> "Keyword_Maybe"
    | Keyword_Module -> "Keyword_Module"
    | Keyword_New -> "Keyword_New"
    | Keyword_Null -> "Keyword_Null"
    | Keyword_Or -> "Keyword_Or"
    | Keyword_Owned -> "Keyword_Owned"
    | Keyword_Private -> "Keyword_Private"
    | Keyword_Public -> "Keyword_Public"
    | Keyword_Real -> "Keyword_Real"
    | Keyword_Return -> "Keyword_Return"
    | Keyword_Set -> "Keyword_Set"
    | Keyword_Shared -> "Keyword_Shared"
    | Keyword_Short -> "Keyword_Short"
    | Keyword_Static -> "Keyword_Static"
    | Keyword_Struct -> "Keyword_Struct"
    | Keyword_Super -> "Keyword_Super"
    | Keyword_Switch -> "Keyword_Switch"
    | Keyword_This -> "Keyword_This"
    | Keyword_Throw -> "Keyword_Throw"
    | Keyword_True -> "Keyword_True"
    | Keyword_Try -> "Keyword_Try"
    | Keyword_Type -> "Keyword_Type"
    | Keyword_U16 -> "Keyword_U16"
    | Keyword_U32 -> "Keyword_U32"
    | Keyword_U64 -> "Keyword_U64"
    | Keyword_U8 -> "Keyword_U8"
    | Keyword_Var -> "Keyword_Var"
    | Keyword_Void -> "Keyword_Void"
    | Keyword_While -> "Keyword_While"
    | Keyword_Yield -> "Keyword_Yield"
    | Keyword_NaN -> "Keyword_NaN"
    | Keyword_Trait -> "Keyword_Trait"
    | Keyword_Trait_Override -> "Keyword_Trait_Override"
    | Keyword_Trait_Implementation -> "Keyword_Trait_Implementation"
    | Keyword_Trait_Prototype -> "Keyword_Trait_Prototype"
    | Keyword_Trait_Deprecated -> "Keyword_Trait_Deprecated"
    | OP_Plus -> "OP_Plus"
    | OP_Minus -> "OP_Minus"
    | OP_Star -> "OP_Star"
    | OP_Slash -> "OP_Slash"
    | OP_Percent -> "OP_Percent"
    | OP_PlusPlus -> "OP_PlusPlus"
    | OP_MinusMinus -> "OP_MinusMinus"
    | OP_Assign -> "OP_Assign"
    | OP_PlusAssign -> "OP_PlusAssign"
    | OP_MinusAssign -> "OP_MinusAssign"
    | OP_StarAssign -> "OP_StarAssign"
    | OP_SlashAssign -> "OP_SlashAssign"
    | OP_PercentAssign -> "OP_PercentAssign"
    | OP_Equal -> "OP_Equal"
    | OP_NotEqual -> "OP_NotEqual"
    | OP_Less -> "OP_Less"
    | OP_LessEqual -> "OP_LessEqual"
    | OP_Greater -> "OP_Greater"
    | OP_GreaterEqual -> "OP_GreaterEqual"
    | OP_Ampersand -> "OP_Ampersand"
    | OP_Pipe -> "OP_Pipe"
    | OP_Caret -> "OP_Caret"
    | OP_Bang -> "OP_Bang"
    | OP_Tilde -> "OP_Tilde"
    | OP_Dot -> "OP_Dot"
    | OP_Comma -> "OP_Comma"
    | OP_Semicolon -> "OP_Semicolon"
    | OP_Colon -> "OP_Colon"
    | OP_ReturnArrow -> "OP_ReturnArrow"
    | OP_Arrow -> "OP_Arrow"
    | OP_LeftParen -> "OP_LeftParen"
    | OP_RightParen -> "OP_RightParen"
    | OP_LeftBrace -> "OP_LeftBrace"
    | OP_RightBrace -> "OP_RightBrace"
    | OP_LeftBracket -> "OP_LeftBracket"
    | OP_RightBracket -> "OP_RightBracket"
    | OP_At -> "OP_At"
    | OP_Hash -> "OP_Hash"
    | OP_Dollar -> "OP_Dollar"
    | OP_Question -> "OP_Question"
    | OP_Backtick -> "OP_Backtick"
    | OP_Fallback -> "OP_Fallback"
    | OP_ColonColon -> "OP_ColonColon"
    | OP_DotDot -> "OP_DotDot"
    | OP_DotDotDot -> "OP_DotDotDot"
    | EndOfFile -> "EndOfFile"
end