module Frontend = Cloth_frontend

let unwrap_ok = function
  | Ok value -> value
  | Error _ -> failwith "expected Ok"

let make_source contents =
  Frontend.Source_file.from_string ~path:"lexer.co" ~contents |> unwrap_ok

let test_lexer_initialization () =
  let source = make_source "ab" in
  let lexer = Frontend.Lexer.create source in
  Alcotest.(check bool) "current char exists" true
    (match Frontend.Lexer.current_char lexer with Some 'a' -> true | _ -> false);
  Alcotest.(check int) "offset starts at 0" 0 lexer.offset

let test_advance_through_characters () =
  let source = make_source "ab" in
  let lexer = Frontend.Lexer.create source in
  Frontend.Lexer.advance lexer;
  Alcotest.(check bool) "after first advance" true
    (match Frontend.Lexer.current_char lexer with Some 'b' -> true | _ -> false);
  Frontend.Lexer.advance lexer;
  Alcotest.(check bool) "at eof" true (Frontend.Lexer.current_char lexer = None)

let test_eof_detection () =
  let source = make_source "" in
  let lexer = Frontend.Lexer.create source in
  Alcotest.(check bool) "empty is eof" true (Frontend.Lexer.is_eof lexer)

let test_next_token_returns_eof_at_end () =
  let source = make_source "" in
  let lexer = Frontend.Lexer.create source in
  let token = Frontend.Lexer.next_token lexer in
  Alcotest.(check bool) "eof token" true (Frontend.Token.is_eof token)

let test_unknown_token_span_is_valid () =
  let source = make_source "x" in
  let lexer = Frontend.Lexer.create source in
  let token = Frontend.Lexer.next_token lexer in
  Alcotest.(check bool) "unknown token kind" true
    (match Frontend.Token.kind token with Frontend.Token.UNKNOWN -> true | _ -> false);
  let span = Frontend.Token.span token in
  Alcotest.(check bool) "non-negative span" true (Frontend.Source_span.length span >= 0)

let () =
  Alcotest.run "lexer"
    [ ( "lexer"
      , [ Alcotest.test_case "initialization" `Quick test_lexer_initialization
        ; Alcotest.test_case "advance" `Quick test_advance_through_characters
        ; Alcotest.test_case "eof_detection" `Quick test_eof_detection
        ; Alcotest.test_case "next_token_eof" `Quick test_next_token_returns_eof_at_end
        ; Alcotest.test_case "span_validity" `Quick test_unknown_token_span_is_valid
        ] )
    ]
