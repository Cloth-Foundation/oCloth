type t = {
  source : Source_file.t;
  mutable offset : int;
  mutable location : Source_location.t;
  mutable current_char : char option;
  mutable meta_candidate_after_colon_colon : bool;
  mutable diagnostics : Diagnostic.t list;
}

let create source =
  {
    source;
    offset = 0;
    location = Source_location.start_of_file source;
    current_char = Source_file.char_at source 0;
    meta_candidate_after_colon_colon = false;
    diagnostics = [];
  }

let diagnostics lexer = List.rev lexer.diagnostics

let emit_diagnostic lexer ~severity ~span ~code ~message ~primary_label ?(notes = [])
    ?(helps = []) ~clause_refs () =
  let diagnostic =
    Diagnostic.make ~severity ~code ~message ~span ~primary_label ~notes ~helps
      ~clause_refs ()
  in
  lexer.diagnostics <- diagnostic :: lexer.diagnostics

let emit_error lexer ~span ~code ~message ~primary_label ?(notes = [])
    ?(helps = []) ~clause_refs () =
  emit_diagnostic lexer ~severity:Diagnostic.Error ~span ~code ~message
    ~primary_label ~notes ~helps ~clause_refs ()

let emit_warning lexer ~span ~code ~message ~primary_label ?(notes = [])
    ?(helps = []) ~clause_refs () =
  emit_diagnostic lexer ~severity:Diagnostic.Warning ~span ~code ~message
    ~primary_label ~notes ~helps ~clause_refs ()

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
  | Some ch when Char_class.is_whitespace ch ->
      advance lexer;
      skip_whitespace lexer
  | _ -> ()

let skip_line_comment lexer =
  if
    match (lexer.current_char, peek_char lexer) with
    | Some '/', Some '/' -> true
    | _ -> false
  then (
    advance lexer;
    advance lexer);
  (* TODO(spec 2.1.2): align line-comment termination with line-terminator normalization strategy if CRLF is normalized upstream. *)
  let rec loop () =
    match lexer.current_char with
    | None -> ()
    | Some ch when Char_class.is_line_terminator ch -> ()
    | Some _ ->
        advance lexer;
        loop ()
  in
  loop ()

let skip_block_comment lexer =
  let comment_start = lexer.location in
  if
    match (lexer.current_char, peek_char lexer) with
    | Some '/', Some '*' -> true
    | _ -> false
  then (
    advance lexer;
    advance lexer);
  let rec loop prev =
    match lexer.current_char with
    | None ->
        let span = Source_span.create ~start:comment_start ~end_:lexer.location in
        emit_error lexer ~span ~code:"LEX003"
          ~message:"unterminated block comment"
          ~primary_label:"block comment starts here"
          ~notes:[ "block comments must end with */" ]
          ~helps:[ "add a closing */" ]
          ~clause_refs:[ "2.4.2"; "2.2.6"; "1.2.5" ] ();
        ()
    | Some ch ->
        advance lexer;
        if prev = '*' && ch = '/' then () else loop ch
  in
  loop '\000'

let skip_comment lexer =
  match (lexer.current_char, peek_char lexer) with
  | Some '/', Some '/' -> skip_line_comment lexer
  | Some '/', Some '*' -> skip_block_comment lexer
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
      if Char_class.is_control_char ch then
        emit_error lexer ~span
          ~code:"LEX002"
          ~message:"illegal control character outside literal"
          ~primary_label:"control character appears here"
          ~notes:[ "control characters are only valid as escapes in literals" ]
          ~clause_refs:[ "2.1.2"; "2.1.3"; "2.2.6"; "1.2.5" ] ()
      else
        emit_error lexer ~span ~code:"LEX001" ~message:"illegal character"
          ~primary_label:"illegal character appears here"
          ~clause_refs:[ "2.2.6"; "1.2.5" ] ();
      Token.make ~kind:Token.UNKNOWN ~lexeme:(String.make 1 ch) ~span

let is_valid_literal_escape = function
  | 'n' | 'r' | 't' | '"' | '\\' | '\'' -> true
  | _ -> false

let read_string_literal lexer =
  match lexer.current_char with
  | Some '"' ->
      let start_location = lexer.location in
      let start_offset = lexer.offset in
      advance lexer;
      let malformed = ref false in
      let rec loop terminated =
        match lexer.current_char with
        | None ->
            malformed := true;
            terminated
        | Some ch when Char_class.is_line_terminator ch ->
            malformed := true;
            terminated
        | Some '"' ->
            advance lexer;
            true
        | Some '\\' ->
            advance lexer;
            (match lexer.current_char with
            | None ->
                malformed := true;
                false
            | Some esc when Char_class.is_line_terminator esc ->
                malformed := true;
                false
            | Some esc ->
                if not (is_valid_literal_escape esc) then (
                  let warning_span = make_span lexer.location lexer.location in
                  emit_warning lexer ~span:warning_span ~code:"LEX007"
                    ~message:"unknown escape sequence; escaped character preserved literally"
                    ~primary_label:"unknown escape sequence"
                    ~notes:[ "unrecognized escapes are treated as the escaped character" ]
                    ~helps:[ "use one of: \\\\n \\\\r \\\\t \\\\\\\" \\\\\\\\ \\\\'" ]
                    ~clause_refs:[ "2.8"; "1.2.5" ] ());
                advance lexer;
                loop terminated)
        | Some ch ->
            if Char_class.is_control_char ch && not (Char_class.is_whitespace ch) then (
              malformed := true;
              let error_span = make_span lexer.location lexer.location in
              emit_error lexer ~span:error_span ~code:"LEX010"
                ~message:"illegal control character in string literal"
                ~primary_label:"control character appears here"
                ~clause_refs:[ "2.1.3"; "2.8"; "2.2.6"; "1.2.5" ] ());
            advance lexer;
            loop terminated
      in
      let terminated = loop false in
      let end_location = lexer.location in
      let span = make_span start_location end_location in
      let lexeme =
        String.sub lexer.source.contents start_offset (lexer.offset - start_offset)
      in
      if not terminated then
        emit_error lexer ~span ~code:"LEX004"
          ~message:"unterminated string literal"
          ~primary_label:"string literal starts here"
          ~notes:[ "string literals must end before the line ends" ]
          ~helps:[ "add a closing double quote" ]
          ~clause_refs:[ "2.8"; "2.2.6"; "1.2.5" ] ();
      let kind =
        if terminated && not !malformed then
          Token.Literal (Token.StringLiteral lexeme)
        else Token.UNKNOWN
      in
      Token.make ~kind ~lexeme ~span
  | _ -> unknown_token lexer

let read_operator_or_punctuation lexer =
  let start_location = lexer.location in
  let start_offset = lexer.offset in
  let peek2 = Source_file.char_at lexer.source (lexer.offset + 2) in
  let matched =
    match (lexer.current_char, peek_char lexer, peek2) with
    | Some '.', Some '.', Some '.' -> Some (Token.Op_DotDotDot, 3)
    | _ -> (
        match (lexer.current_char, peek_char lexer) with
        | Some '.', Some '.' -> Some (Token.Op_DotDot, 2)
        | Some ':', Some ':' -> Some (Token.Op_ColonColon, 2)
        | Some ':', Some '>' -> Some (Token.Op_ReturnArrow, 2)
        | Some '-', Some '>' -> Some (Token.Op_Arrow, 2)
        | Some '?', Some '?' -> Some (Token.Op_Fallback, 2)
        | Some '+', Some '+' -> Some (Token.Op_PlusPlus, 2)
        | Some '-', Some '-' -> Some (Token.Op_MinusMinus, 2)
        | Some '+', Some '=' -> Some (Token.Op_PlusEqual, 2)
        | Some '-', Some '=' -> Some (Token.Op_MinusEqual, 2)
        | Some '*', Some '=' -> Some (Token.Op_StarEqual, 2)
        | Some '/', Some '=' -> Some (Token.Op_SlashEqual, 2)
        | Some '%', Some '=' -> Some (Token.Op_PercentEqual, 2)
        | Some '&', Some '=' -> Some (Token.Op_AmpEqual, 2)
        | Some '|', Some '=' -> Some (Token.Op_PipeEqual, 2)
        | Some '^', Some '=' -> Some (Token.Op_CaretEqual, 2)
        | Some '=', Some '=' -> Some (Token.Op_EqualEqual, 2)
        | Some '!', Some '=' -> Some (Token.Op_BangEqual, 2)
        | Some '<', Some '=' -> Some (Token.Op_LessEqual, 2)
        | Some '>', Some '=' -> Some (Token.Op_GreaterEqual, 2)
        | _ -> (
            match lexer.current_char with
            | Some '=' -> Some (Token.Op_Equal, 1)
            | Some '+' -> Some (Token.Op_Plus, 1)
            | Some '-' -> Some (Token.Op_Minus, 1)
            | Some '*' -> Some (Token.Op_Star, 1)
            | Some '/' -> Some (Token.Op_Slash, 1)
            | Some '%' -> Some (Token.Op_Percent, 1)
            | Some '&' -> Some (Token.Op_Amp, 1)
            | Some '|' -> Some (Token.Op_Pipe, 1)
            | Some '^' -> Some (Token.Op_Caret, 1)
            | Some '~' -> Some (Token.Op_Tilde, 1)
            | Some '!' -> Some (Token.Op_Bang, 1)
            | Some '<' -> Some (Token.Op_Less, 1)
            | Some '>' -> Some (Token.Op_Greater, 1)
            | Some '.' -> Some (Token.Op_Dot, 1)
            | Some ',' -> Some (Token.Op_Comma, 1)
            | Some ';' -> Some (Token.Op_Semicolon, 1)
            | Some ':' -> Some (Token.Op_Colon, 1)
            | Some '(' -> Some (Token.Op_LParen, 1)
            | Some ')' -> Some (Token.Op_RParen, 1)
            | Some '{' -> Some (Token.Op_LBrace, 1)
            | Some '}' -> Some (Token.Op_RBrace, 1)
            | Some '[' -> Some (Token.Op_LBracket, 1)
            | Some ']' -> Some (Token.Op_RBracket, 1)
            | Some '@' -> Some (Token.Op_At, 1)
            | Some '#' -> Some (Token.Op_Hash, 1)
            | Some '$' -> Some (Token.Op_Dollar, 1)
            | Some '?' -> Some (Token.Op_Question, 1)
            | Some '`' -> Some (Token.Op_Backtick, 1)
            | _ -> None))
  in
  match matched with
  | Some (op, length) ->
      for _ = 1 to length do
        advance lexer
      done;
      let end_location = lexer.location in
      let span = make_span start_location end_location in
      let lexeme = String.sub lexer.source.contents start_offset length in
      lexer.meta_candidate_after_colon_colon <- (op = Token.Op_ColonColon);
      Token.make ~kind:(Token.OperatorPunctuation op) ~lexeme ~span
  | None ->
      (* TODO(spec 2.7): attach diagnostic for unknown operator/punctuation symbol. *)
      let end_offset = min (String.length lexer.source.contents) (start_offset + 1) in
      let length = end_offset - start_offset in
      let lexeme = if length <= 0 then "" else String.sub lexer.source.contents start_offset length in
      let token = unknown_token lexer in
      lexer.meta_candidate_after_colon_colon <- false;
      Token.make ~kind:Token.UNKNOWN ~lexeme ~span:(Token.span token)

let read_char_literal lexer =
  match lexer.current_char with
  | Some '\'' ->
      let start_location = lexer.location in
      let start_offset = lexer.offset in
      advance lexer;
      let scalar_count = ref 0 in
      let malformed = ref false in
      let terminated = ref false in
      let rec loop () =
        match lexer.current_char with
        | None -> ()
        | Some ch when Char_class.is_line_terminator ch ->
            malformed := true
        | Some '\'' ->
            advance lexer;
            terminated := true
        | Some '\\' ->
            advance lexer;
            (match lexer.current_char with
            | None -> malformed := true
            | Some esc when Char_class.is_line_terminator esc ->
                malformed := true
            | Some esc ->
                if not (is_valid_literal_escape esc) then (
                  let warning_span = make_span lexer.location lexer.location in
                  emit_warning lexer ~span:warning_span ~code:"LEX007"
                    ~message:"unknown escape sequence; escaped character preserved literally"
                    ~primary_label:"unknown escape sequence"
                    ~notes:[ "unrecognized escapes are treated as the escaped character" ]
                    ~helps:[ "use one of: \\\\n \\\\r \\\\t \\\\\\\" \\\\\\\\ \\\\'" ]
                    ~clause_refs:[ "2.8"; "1.2.5" ] ());
                scalar_count := !scalar_count + 1;
                advance lexer;
                loop ())
        | Some ch ->
            if Char_class.is_control_char ch && not (Char_class.is_whitespace ch) then
              malformed := true;
            scalar_count := !scalar_count + 1;
            advance lexer;
            loop ()
      in
      loop ();
      if not !terminated then
        malformed := true;
      if !scalar_count = 0 then
        malformed := true;
      if !scalar_count <> 1 then
        malformed := true;
      let end_location = lexer.location in
      let span = make_span start_location end_location in
      let lexeme =
        String.sub lexer.source.contents start_offset (lexer.offset - start_offset)
      in
      if not !terminated then
        emit_error lexer ~span ~code:"LEX005"
          ~message:"unterminated character literal"
          ~primary_label:"character literal starts here"
          ~helps:[ "add a closing single quote" ]
          ~clause_refs:[ "2.8"; "2.2.6"; "1.2.5" ] ();
      if !scalar_count = 0 then
        emit_error lexer ~span ~code:"LEX006" ~message:"empty character literal"
          ~primary_label:"character literal is empty"
          ~helps:[ "insert exactly one character or escape" ]
          ~clause_refs:[ "2.8"; "2.2.6"; "1.2.5" ] ();
      if !scalar_count > 1 then
        emit_error lexer ~span ~code:"LEX006"
          ~message:"malformed character literal: must contain exactly one Unicode scalar value"
          ~primary_label:"character literal has too many characters"
          ~clause_refs:[ "2.8"; "2.2.6"; "1.2.5" ] ();
      let kind =
        if (not !malformed) && !terminated then
          Token.Literal (Token.CharLiteral lexeme)
        else Token.UNKNOWN
      in
      Token.make ~kind ~lexeme ~span
  | _ -> unknown_token lexer

let read_identifier_or_keyword lexer =
  match lexer.current_char with
  | Some ch when Char_class.is_identifier_start ch ->
      let start_location = lexer.location in
      let start_offset = lexer.offset in
      advance lexer;
      while
        match lexer.current_char with
        | Some next_ch -> Char_class.is_identifier_part next_ch
        | None -> false
      do
        advance lexer
      done;
      let end_location = lexer.location in
      let span = make_span start_location end_location in
      let lexeme =
        String.sub lexer.source.contents start_offset (lexer.offset - start_offset)
      in
      let is_ascii_upper_or_underscore = function
        | 'A' .. 'Z' | '_' -> true
        | _ -> false
      in
      let is_meta_candidate_lexeme =
        String.length lexeme > 0
        && String.for_all is_ascii_upper_or_underscore lexeme
      in
      let kind =
        if lexer.meta_candidate_after_colon_colon && is_meta_candidate_lexeme then
          match Token.meta_of_string lexeme with
          | Some meta_kind -> Token.Meta meta_kind
          | None ->
              (* TODO(spec 2.3): clarify whether non-meta uppercase identifiers immediately after :: are diagnostic-only or plain identifiers. *)
              (match Token.keyword_of_string lexeme with
              | Some keyword_kind -> keyword_kind
              | None -> Token.Identifier lexeme)
        else
          match Token.keyword_of_string lexeme with
          | Some keyword_kind -> keyword_kind
          | None -> Token.Identifier lexeme
      in
      lexer.meta_candidate_after_colon_colon <- false;
      Token.make ~kind ~lexeme ~span
  | Some _ ->
      let start_location = lexer.location in
      let span = make_span start_location start_location in
      lexer.meta_candidate_after_colon_colon <- false;
      Token.make ~kind:Token.UNKNOWN ~lexeme:"" ~span
  | None ->
      lexer.meta_candidate_after_colon_colon <- false;
      eof_token lexer

let is_integer_suffix = function
  | 'b' | 'B' | 'i' | 'I' | 'l' | 'L' | 'u' | 'U' -> true
  | _ -> false

let is_float_suffix = function
  | 'f' | 'F' | 'd' | 'D' -> true
  | _ -> false

let digit_for_radix radix =
  match radix with
  | 2 -> Char_class.is_binary_digit
  | 8 -> Char_class.is_octal_digit
  | 10 -> Char_class.is_decimal_digit
  | 16 -> Char_class.is_hex_digit
  | _ -> fun _ -> false

let consume_while lexer predicate =
  while
    match lexer.current_char with
    | Some ch -> predicate ch
    | None -> false
  do
    advance lexer
  done

let read_integer_with_radix lexer ~start_location ~start_offset radix =
  let is_digit_for_radix = digit_for_radix radix in
  consume_while lexer is_digit_for_radix;
  (match lexer.current_char with
  | Some ch when Char_class.is_identifier_part ch && not (is_integer_suffix ch) ->
      let span = make_span start_location lexer.location in
      emit_error lexer ~span ~code:"LEX008"
        ~message:"invalid radix digit in numeric literal"
        ~primary_label:"invalid digit for literal radix"
        ~clause_refs:[ "2.8"; "2.2.6"; "1.2.5" ] ()
  | _ -> ());
  (match lexer.current_char with
  | Some ch when is_integer_suffix ch -> advance lexer
  | _ -> ());
  let end_location = lexer.location in
  let span = make_span start_location end_location in
  let lexeme = String.sub lexer.source.contents start_offset (lexer.offset - start_offset) in
  Token.make ~kind:(Token.Literal (Token.IntegerLiteral lexeme)) ~lexeme ~span

let read_integer_or_float lexer =
  let start_location = lexer.location in
  let start_offset = lexer.offset in
  let saw_leading_digits =
    match lexer.current_char with
    | Some ch when Char_class.is_decimal_digit ch ->
        consume_while lexer Char_class.is_decimal_digit;
        true
    | _ -> false
  in
  let saw_dot =
    match lexer.current_char with
    | Some '.' ->
        advance lexer;
        true
    | _ -> false
  in
  let saw_fraction_digits =
    if saw_dot then
      let before = lexer.offset in
      consume_while lexer Char_class.is_decimal_digit;
      lexer.offset > before
    else false
  in
  let has_decimal_point_number = saw_dot && (saw_leading_digits || saw_fraction_digits) in
  if has_decimal_point_number then (
    match lexer.current_char with
    | Some ('e' | 'E') ->
        let exp_mark_offset = lexer.offset in
        let exp_mark_location = lexer.location in
        let exp_mark_current_char = lexer.current_char in
        advance lexer;
        (match lexer.current_char with
        | Some ('+' | '-') -> advance lexer
        | _ -> ());
        let exp_digits_start = lexer.offset in
        consume_while lexer Char_class.is_decimal_digit;
        if lexer.offset = exp_digits_start then (
          lexer.offset <- exp_mark_offset;
          lexer.location <- exp_mark_location;
          lexer.current_char <- exp_mark_current_char)
    | _ -> ());
  if has_decimal_point_number then (
    match lexer.current_char with
    | Some ch when is_float_suffix ch -> advance lexer
    | _ -> ());
  if not has_decimal_point_number then
    (match lexer.current_char with
    | Some ch when is_integer_suffix ch -> advance lexer
    | _ -> ());
  let end_location = lexer.location in
  let span = make_span start_location end_location in
  let lexeme = String.sub lexer.source.contents start_offset (lexer.offset - start_offset) in
  let kind =
    if has_decimal_point_number then Token.Literal (Token.FloatLiteral lexeme)
    else Token.Literal (Token.IntegerLiteral lexeme)
  in
  Token.make ~kind ~lexeme ~span

let read_number_literal lexer =
  match lexer.current_char with
  | Some '0' ->
      let start_location = lexer.location in
      let start_offset = lexer.offset in
      (match peek_char lexer with
      | Some ('t' | 'T') ->
          advance lexer;
          advance lexer;
          let end_location = lexer.location in
          let span = make_span start_location end_location in
          let lexeme =
            String.sub lexer.source.contents start_offset (lexer.offset - start_offset)
          in
          Token.make ~kind:(Token.Literal (Token.BitLiteral lexeme)) ~lexeme ~span
      | Some ('b' | 'B') ->
          advance lexer;
          advance lexer;
          (match lexer.current_char with
          | Some ch when Char_class.is_binary_digit ch ->
              read_integer_with_radix lexer ~start_location ~start_offset 2
          | _ ->
              let end_location = lexer.location in
              let span = make_span start_location end_location in
              emit_error lexer ~span
                ~code:"LEX009"
                ~message:"malformed binary literal: missing binary digits"
                ~primary_label:"binary prefix without digits"
                ~helps:[ "add at least one binary digit (0 or 1) after 0b" ]
                ~clause_refs:[ "2.8.1"; "2.2.6"; "1.2.5" ] ();
              let lexeme =
                String.sub lexer.source.contents start_offset
                  (lexer.offset - start_offset)
              in
              Token.make ~kind:Token.UNKNOWN ~lexeme ~span)
      | Some ('o' | 'O') ->
          advance lexer;
          advance lexer;
          (match lexer.current_char with
          | Some ch when Char_class.is_octal_digit ch ->
              read_integer_with_radix lexer ~start_location ~start_offset 8
          | _ ->
              let end_location = lexer.location in
              let span = make_span start_location end_location in
              emit_error lexer ~span
                ~code:"LEX009"
                ~message:"malformed octal literal: missing octal digits"
                ~primary_label:"octal prefix without digits"
                ~helps:[ "add at least one octal digit after 0o" ]
                ~clause_refs:[ "2.8.1"; "2.2.6"; "1.2.5" ] ();
              let lexeme =
                String.sub lexer.source.contents start_offset
                  (lexer.offset - start_offset)
              in
              Token.make ~kind:Token.UNKNOWN ~lexeme ~span)
      | Some ('d' | 'D') ->
          advance lexer;
          advance lexer;
          (match lexer.current_char with
          | Some ch when Char_class.is_decimal_digit ch ->
              read_integer_with_radix lexer ~start_location ~start_offset 10
          | _ ->
              let end_location = lexer.location in
              let span = make_span start_location end_location in
              emit_error lexer ~span
                ~code:"LEX009"
                ~message:"malformed decimal literal: missing decimal digits"
                ~primary_label:"decimal prefix without digits"
                ~helps:[ "add at least one decimal digit after 0d" ]
                ~clause_refs:[ "2.8.1"; "2.2.6"; "1.2.5" ] ();
              let lexeme =
                String.sub lexer.source.contents start_offset
                  (lexer.offset - start_offset)
              in
              Token.make ~kind:Token.UNKNOWN ~lexeme ~span)
      | Some ('x' | 'X') ->
          advance lexer;
          advance lexer;
          (match lexer.current_char with
          | Some ch when Char_class.is_hex_digit ch ->
              read_integer_with_radix lexer ~start_location ~start_offset 16
          | _ ->
              let end_location = lexer.location in
              let span = make_span start_location end_location in
              emit_error lexer ~span
                ~code:"LEX009"
                ~message:"malformed hexadecimal literal: missing hexadecimal digits"
                ~primary_label:"hexadecimal prefix without digits"
                ~helps:[ "add at least one hexadecimal digit after 0x" ]
                ~clause_refs:[ "2.8.1"; "2.2.6"; "1.2.5" ] ();
              let lexeme =
                String.sub lexer.source.contents start_offset
                  (lexer.offset - start_offset)
              in
              Token.make ~kind:Token.UNKNOWN ~lexeme ~span)
      | _ -> read_integer_or_float lexer)
  | Some '1' ->
      let start_location = lexer.location in
      let start_offset = lexer.offset in
      (match peek_char lexer with
      | Some ('t' | 'T') ->
          advance lexer;
          advance lexer;
          let end_location = lexer.location in
          let span = make_span start_location end_location in
          let lexeme =
            String.sub lexer.source.contents start_offset (lexer.offset - start_offset)
          in
          Token.make ~kind:(Token.Literal (Token.BitLiteral lexeme)) ~lexeme ~span
      | _ -> read_integer_or_float lexer)
  | Some '.' ->
      (match peek_char lexer with
      | Some ch when Char_class.is_decimal_digit ch -> read_integer_or_float lexer
      | _ -> unknown_token lexer)
  | Some ch when Char_class.is_decimal_digit ch -> read_integer_or_float lexer
  | _ -> unknown_token lexer

let rec skip_trivia lexer =
  let before_offset = lexer.offset in
  skip_whitespace lexer;
  skip_comment lexer;
  if lexer.offset <> before_offset then skip_trivia lexer else ()

let next_token lexer =
  (* TODO(spec 2.1.1.1): integrate ill-formed UTF-8 decoding diagnostics if decoding is performed in Source_file. *)
  skip_trivia lexer;
  if is_eof lexer then (
    lexer.meta_candidate_after_colon_colon <- false;
    eof_token lexer)
  else if
    match lexer.current_char with
    | Some ch -> Char_class.is_identifier_start ch
    | None -> false
  then read_identifier_or_keyword lexer
  else if
    match lexer.current_char with
    | Some ch ->
        Char_class.is_decimal_digit ch
        || (ch = '.'
           &&
           match peek_char lexer with
           | Some next_ch -> Char_class.is_decimal_digit next_ch
           | None -> false)
    | None -> false
  then (
    lexer.meta_candidate_after_colon_colon <- false;
    read_number_literal lexer)
  else if
    match lexer.current_char with
    | Some '"' -> true
    | _ -> false
  then (
    lexer.meta_candidate_after_colon_colon <- false;
    read_string_literal lexer)
  else if
    match lexer.current_char with
    | Some '\'' -> true
    | _ -> false
  then (
    lexer.meta_candidate_after_colon_colon <- false;
    read_char_literal lexer)
  else if
    match lexer.current_char with
    | Some ch -> Char_class.is_operator_or_punctuation_start ch
    | None -> false
  then read_operator_or_punctuation lexer
  else
    (* TODO(spec 2.2.2, 2.5-2.8): extend dispatch for non-identifier token classes. *)
    let token = unknown_token lexer in
    lexer.meta_candidate_after_colon_colon <- false;
    token

let peek_token lexer =
  let saved_offset = lexer.offset in
  let saved_location = lexer.location in
  let saved_current_char = lexer.current_char in
  let saved_meta_candidate_after_colon_colon = lexer.meta_candidate_after_colon_colon in
  let saved_diagnostics = lexer.diagnostics in
  let token = next_token lexer in
  lexer.offset <- saved_offset;
  lexer.location <- saved_location;
  lexer.current_char <- saved_current_char;
  lexer.meta_candidate_after_colon_colon <- saved_meta_candidate_after_colon_colon;
  lexer.diagnostics <- saved_diagnostics;
  token

let lex_all lexer =
  let rec loop acc =
    let token = next_token lexer in
    if Token.is_eof token then List.rev (token :: acc) else loop (token :: acc)
  in
  loop []
