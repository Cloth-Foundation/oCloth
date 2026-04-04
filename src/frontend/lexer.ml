module T = Token.Token

exception Lexing_error of string

type state = {
  source : string;
  length : int;
  mutable index : int;
  mutable line : int;
  mutable column : int;
}

let create_state source =
  { source; length = String.length source; index = 0; line = 1; column = 1 }

let is_at_end state = state.index >= state.length

let peek state offset =
  let index = state.index + offset in
  if index < 0 || index >= state.length then None else Some state.source.[index]

let current_position state =
  { T.offset = state.index; line = state.line; column = state.column }

let error state message =
  let pos = current_position state in
  raise
    (Lexing_error
       (Printf.sprintf "line %d, column %d: %s" pos.line pos.column message))

let advance state =
  match peek state 0 with
  | None -> None
  | Some ch ->
      state.index <- state.index + 1;
      if ch = '\n' then (
        state.line <- state.line + 1;
        state.column <- 1 )
      else state.column <- state.column + 1;
      Some ch

let make_span start_pos end_pos = { T.start_pos; end_pos }

let make_token state start_pos kind lexeme =
  T.make ~kind ~lexeme ~span:(make_span start_pos (current_position state))

let is_space = function ' ' | '\t' | '\r' | '\n' -> true | _ -> false
let is_digit ch = ch >= '0' && ch <= '9'

let is_identifier_start = function
  | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true
  | _ -> false

let is_identifier_part ch = is_identifier_start ch || is_digit ch

let take_while state predicate =
  let start = state.index in
  let rec loop () =
    match peek state 0 with
    | Some ch when predicate ch ->
        ignore (advance state);
        loop ()
    | _ -> String.sub state.source start (state.index - start)
  in
  loop ()

let keyword_table =
  [ ("and", T.Keyword_And)
  ; ("any", T.Keyword_Any)
  ; ("as", T.Keyword_As)
  ; ("async", T.Keyword_Async)
  ; ("atomic", T.Keyword_Atomic)
  ; ("await", T.Keyword_Await)
  ; ("bit", T.Keyword_Bit)
  ; ("bool", T.Keyword_Bool)
  ; ("break", T.Keyword_Break)
  ; ("byte", T.Keyword_Byte)
  ; ("case", T.Keyword_Case)
  ; ("catch", T.Keyword_Catch)
  ; ("char", T.Keyword_Char)
  ; ("class", T.Keyword_Class)
  ; ("const", T.Keyword_Const)
  ; ("continue", T.Keyword_Continue)
  ; ("defer", T.Keyword_Defer)
  ; ("default", T.Keyword_Default)
  ; ("delete", T.Keyword_Delete)
  ; ("do", T.Keyword_Do)
  ; ("double", T.Keyword_Double)
  ; ("else", T.Keyword_Else)
  ; ("enum", T.Keyword_Enum)
  ; ("f32", T.Keyword_F32)
  ; ("f64", T.Keyword_F64)
  ; ("false", T.Keyword_False)
  ; ("finally", T.Keyword_Finally)
  ; ("float", T.Keyword_Float)
  ; ("for", T.Keyword_For)
  ; ("func", T.Keyword_Func)
  ; ("get", T.Keyword_Get)
  ; ("i16", T.Keyword_I16)
  ; ("i32", T.Keyword_I32)
  ; ("i64", T.Keyword_I64)
  ; ("i8", T.Keyword_I8)
  ; ("if", T.Keyword_If)
  ; ("import", T.Keyword_Import)
  ; ("in", T.Keyword_In)
  ; ("int", T.Keyword_Int)
  ; ("interface", T.Keyword_Interface)
  ; ("internal", T.Keyword_Internal)
  ; ("is", T.Keyword_Is)
  ; ("long", T.Keyword_Long)
  ; ("maybe", T.Keyword_Maybe)
  ; ("module", T.Keyword_Module)
  ; ("new", T.Keyword_New)
  ; ("null", T.Keyword_Null)
  ; ("or", T.Keyword_Or)
  ; ("owned", T.Keyword_Owned)
  ; ("private", T.Keyword_Private)
  ; ("public", T.Keyword_Public)
  ; ("real", T.Keyword_Real)
  ; ("return", T.Keyword_Return)
  ; ("set", T.Keyword_Set)
  ; ("shared", T.Keyword_Shared)
  ; ("short", T.Keyword_Short)
  ; ("static", T.Keyword_Static)
  ; ("struct", T.Keyword_Struct)
  ; ("super", T.Keyword_Super)
  ; ("switch", T.Keyword_Switch)
  ; ("this", T.Keyword_This)
  ; ("throw", T.Keyword_Throw)
  ; ("true", T.Keyword_True)
  ; ("try", T.Keyword_Try)
  ; ("type", T.Keyword_Type)
  ; ("u16", T.Keyword_U16)
  ; ("u32", T.Keyword_U32)
  ; ("u64", T.Keyword_U64)
  ; ("u8", T.Keyword_U8)
  ; ("uint", T.Keyword_Uint)
  ; ("unsigned", T.Keyword_Unsigned)
  ; ("var", T.Keyword_Var)
  ; ("void", T.Keyword_Void)
  ; ("while", T.Keyword_While)
  ; ("yield", T.Keyword_Yield)
  ; ("NaN", T.Keyword_NaN)
  ; ("trait", T.Keyword_Trait)
  ; ("Override", T.Keyword_Trait_Override)
  ; ("Implementation", T.Keyword_Trait_Implementation)
  ; ("Prototype", T.Keyword_Trait_Prototype)
  ; ("Deprecated", T.Keyword_Trait_Deprecated)
  ]

let kind_of_identifier lexeme =
  match List.assoc_opt lexeme keyword_table with
  | Some kind -> kind
  | None -> T.Identifier lexeme

let rec skip_whitespace_and_comments state =
  match (peek state 0, peek state 1) with
  | Some ch, _ when is_space ch ->
      ignore (advance state);
      skip_whitespace_and_comments state
  | Some '/', Some '/' ->
      ignore (advance state);
      ignore (advance state);
      skip_line_comment state;
      skip_whitespace_and_comments state
  | Some '/', Some '*' ->
      ignore (advance state);
      ignore (advance state);
      skip_block_comment state;
      skip_whitespace_and_comments state
  | _ -> ()

and skip_line_comment state =
  match peek state 0 with
  | Some '\n' | None -> ()
  | _ ->
      ignore (advance state);
      skip_line_comment state

and skip_block_comment state =
  match (peek state 0, peek state 1) with
  | None, _ -> error state "unterminated block comment"
  | Some '*', Some '/' ->
      ignore (advance state);
      ignore (advance state)
  | _ ->
      ignore (advance state);
      skip_block_comment state

let lex_identifier state start_pos =
  let lexeme = take_while state is_identifier_part in
  make_token state start_pos (kind_of_identifier lexeme) lexeme

let lex_number state start_pos =
  let start_index = state.index in
  ignore (take_while state is_digit);
  let is_float_literal =
    match (peek state 0, peek state 1) with
    | Some '.', Some ch when is_digit ch ->
        ignore (advance state);
        ignore (take_while state is_digit);
        true
    | _ -> false
  in
  let lexeme = String.sub state.source start_index (state.index - start_index) in
  let kind =
    if is_float_literal then
      match float_of_string_opt lexeme with
      | Some value -> T.Float value
      | None -> error state (Printf.sprintf "invalid float literal %S" lexeme)
    else
      match int_of_string_opt lexeme with
      | Some value -> T.Integer value
      | None -> error state (Printf.sprintf "invalid integer literal %S" lexeme)
  in
  make_token state start_pos kind lexeme

let lex_string state start_pos =
  let start_index = state.index in
  let buffer = Buffer.create 16 in
  ignore (advance state);
  let rec loop () =
    match peek state 0 with
    | None -> error state "unterminated string literal"
    | Some '"' ->
        ignore (advance state);
        let lexeme = String.sub state.source start_index (state.index - start_index) in
        make_token state start_pos (T.String (Buffer.contents buffer)) lexeme
    | Some '\\' ->
        ignore (advance state);
        let escaped =
          match advance state with
          | Some 'n' -> '\n'
          | Some 'r' -> '\r'
          | Some 't' -> '\t'
          | Some '"' -> '"'
          | Some '\\' -> '\\'
          | Some ch -> ch
          | None -> error state "unterminated escape sequence"
        in
        Buffer.add_char buffer escaped;
        loop ()
    | Some ch ->
        ignore (advance state);
        Buffer.add_char buffer ch;
        loop ()
  in
  loop ()

let symbol_table =
  [ ("...", T.OP_DotDotDot)
  ; ("++", T.OP_PlusPlus)
  ; ("--", T.OP_MinusMinus)
  ; ("+=", T.OP_PlusAssign)
  ; ("-=", T.OP_MinusAssign)
  ; ("*=", T.OP_StarAssign)
  ; ("/=", T.OP_SlashAssign)
  ; ("%=", T.OP_PercentAssign)
  ; ("==", T.OP_Equal)
  ; ("!=", T.OP_NotEqual)
  ; ("<=", T.OP_LessEqual)
  ; (">=", T.OP_GreaterEqual)
  ; (":>", T.OP_ReturnArrow)
  ; ("->", T.OP_Arrow)
  ; ("::", T.OP_ColonColon)
  ; ("..", T.OP_DotDot)
  ; ("??", T.OP_Fallback)
  ; ("+", T.OP_Plus)
  ; ("-", T.OP_Minus)
  ; ("*", T.OP_Star)
  ; ("/", T.OP_Slash)
  ; ("%", T.OP_Percent)
  ; ("=", T.OP_Assign)
  ; ("<", T.OP_Less)
  ; (">", T.OP_Greater)
  ; ("&", T.OP_Ampersand)
  ; ("|", T.OP_Pipe)
  ; ("^", T.OP_Caret)
  ; ("!", T.OP_Bang)
  ; ("~", T.OP_Tilde)
  ; (".", T.OP_Dot)
  ; (",", T.OP_Comma)
  ; (";", T.OP_Semicolon)
  ; (":", T.OP_Colon)
  ; ("(", T.OP_LeftParen)
  ; (")", T.OP_RightParen)
  ; ("{", T.OP_LeftBrace)
  ; ("}", T.OP_RightBrace)
  ; ("[", T.OP_LeftBracket)
  ; ("]", T.OP_RightBracket)
  ; ("@", T.OP_At)
  ; ("#", T.OP_Hash)
  ; ("$", T.OP_Dollar)
  ; ("?", T.OP_Question)
  ; ("`", T.OP_Backtick)
  ]

let matches_lexeme state lexeme =
  let rec loop index =
    if index = String.length lexeme then true
    else
      match peek state index with
      | Some ch when ch = lexeme.[index] -> loop (index + 1)
      | _ -> false
  in
  loop 0

let consume_lexeme state lexeme =
  for _ = 1 to String.length lexeme do
    ignore (advance state)
  done

let lex_symbol state start_pos =
  match List.find_opt (fun (lexeme, _) -> matches_lexeme state lexeme) symbol_table with
  | Some (lexeme, kind) ->
      consume_lexeme state lexeme;
      make_token state start_pos kind lexeme
  | None ->
      match peek state 0 with
      | Some ch -> error state (Printf.sprintf "unexpected character %C" ch)
      | None -> make_token state start_pos T.EndOfFile ""

let next_token state =
  skip_whitespace_and_comments state;
  let start_pos = current_position state in
  match peek state 0 with
  | None -> make_token state start_pos T.EndOfFile ""
  | Some ch when is_identifier_start ch -> lex_identifier state start_pos
  | Some ch when is_digit ch -> lex_number state start_pos
  | Some '"' -> lex_string state start_pos
  | Some _ -> lex_symbol state start_pos

let tokenize source =
  try
    let state = create_state source in
    let rec loop tokens =
      let token = next_token state in
      match token.T.kind with
      | T.EndOfFile -> Ok (List.rev (token :: tokens))
      | _ -> loop (token :: tokens)
    in
    loop []
  with Lexing_error message -> Error message
