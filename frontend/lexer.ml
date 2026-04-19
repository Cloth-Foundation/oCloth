type t = {
  source : Source_file.t;
  mutable offset : int;
  mutable location : Source_location.t;
  mutable current_char : char option;
}

let create source =
  {
    source;
    offset = 0;
    location = Source_location.start_of_file source;
    current_char = Source_file.char_at source 0;
  }

let current_char lexer = lexer.current_char
let peek_char lexer = Source_file.char_at lexer.source (lexer.offset + 1)

let advance lexer =
  match lexer.current_char with
  | None -> ()
  | Some ch ->
      lexer.location <- Source_location.advance lexer.location ch;
      lexer.offset <- lexer.offset + 1;
      lexer.current_char <- Source_file.char_at lexer.source lexer.offset

let is_eof lexer = match lexer.current_char with None -> true | Some _ -> false

let rec skip_whitespace lexer =
  match lexer.current_char with
  | Some (' ' | '\t' | '\n' | '\r') ->
      advance lexer;
      skip_whitespace lexer
  | _ ->
      (* TODO(spec 2.1.3): confirm the complete whitespace set after normalization. *)
      ()

let skip_line_comment lexer =
  let rec loop () =
    match lexer.current_char with
    | None | Some '\n' -> ()
    | Some _ ->
        advance lexer;
        loop ()
  in
  loop ()

let skip_block_comment lexer =
  let rec loop prev =
    match lexer.current_char with
    | None ->
        (* TODO(spec 2.4.2): attach unterminated block comment diagnostic span. *)
        ()
    | Some ch ->
        advance lexer;
        if prev = '*' && ch = '/' then () else loop ch
  in
  loop '\000'

let skip_comment lexer =
  match (lexer.current_char, peek_char lexer) with
  | Some '/', Some '/' ->
      advance lexer;
      advance lexer;
      skip_line_comment lexer
  | Some '/', Some '*' ->
      advance lexer;
      advance lexer;
      skip_block_comment lexer
  | _ -> ()

let make_span start_location end_location =
  Source_span.create ~start:start_location ~end_:end_location

let eof_token lexer =
  let span = make_span lexer.location lexer.location in
  Token.make ~kind:Token.EOF ~lexeme:"" ~span

let unknown_token lexer =
  match lexer.current_char with
  | None -> eof_token lexer
  | Some ch ->
      let start_location = lexer.location in
      advance lexer;
      let end_location = lexer.location in
      let span = make_span start_location end_location in
      Token.make ~kind:Token.UNKNOWN ~lexeme:(String.make 1 ch) ~span

let rec skip_trivia lexer =
  let before_offset = lexer.offset in
  skip_whitespace lexer;
  skip_comment lexer;
  if lexer.offset <> before_offset then skip_trivia lexer else ()

let next_token lexer =
  skip_trivia lexer;
  if is_eof lexer then eof_token lexer
  else
    (* TODO(spec 2.2.2, 2.5-2.8): implement maximal-munch token recognition. *)
    unknown_token lexer

let peek_token lexer =
  let saved_offset = lexer.offset in
  let saved_location = lexer.location in
  let saved_current_char = lexer.current_char in
  let token = next_token lexer in
  lexer.offset <- saved_offset;
  lexer.location <- saved_location;
  lexer.current_char <- saved_current_char;
  token
