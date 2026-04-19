module Frontend = Cloth

let unwrap_ok = function
  | Ok value -> value
  | Error _ -> failwith "expected Ok"

let make_source contents =
  Frontend.Source_file.from_string ~path:"lexer.co" ~contents |> unwrap_ok

let make_lexer text =
  let source = make_source text in
  Frontend.Lexer.create source

let test_lex_all_mixed_source () =
  let lexer = make_lexer "module m; var x = 1; ::SIZEOF" in
  let tokens = Frontend.Lexer.lex_all lexer in
  Alcotest.(check bool) "ends with eof" true
    (match Frontend.Token.kind (List.hd (List.rev tokens)) with
    | Frontend.Token.EOF -> true
    | _ -> false);
  Alcotest.(check bool) "contains meta token" true
    (List.exists
       (fun t ->
         match Frontend.Token.kind t with Frontend.Token.Meta Frontend.Token.SIZEOF -> true | _ -> false)
       tokens)

let test_eof_behavior_consistent () =
  let lexer = make_lexer "" in
  let t1 = Frontend.Lexer.next_token lexer in
  let t2 = Frontend.Lexer.next_token lexer in
  Alcotest.(check bool) "first eof" true
    (match Frontend.Token.kind t1 with Frontend.Token.EOF -> true | _ -> false);
  Alcotest.(check bool) "second eof" true
    (match Frontend.Token.kind t2 with Frontend.Token.EOF -> true | _ -> false);
  Alcotest.(check string) "eof lexeme empty" "" (Frontend.Token.lexeme t1)

let test_trivia_skipped_correctly () =
  let lexer = make_lexer "  // comment\n /* block */ module" in
  let token = Frontend.Lexer.next_token lexer in
  Alcotest.(check bool) "first non-trivia is module keyword" true
    (match Frontend.Token.kind token with
    | Frontend.Token.Keyword Frontend.Token.Kw_module -> true
    | _ -> false)

let test_meta_token_sequence () =
  let lexer = make_lexer "::SIZEOF" in
  let t1 = Frontend.Lexer.next_token lexer in
  let t2 = Frontend.Lexer.next_token lexer in
  Alcotest.(check bool) "first is ::" true
    (match Frontend.Token.kind t1 with
    | Frontend.Token.OperatorPunctuation Frontend.Token.Op_ColonColon -> true
    | _ -> false);
  Alcotest.(check bool) "second is meta SIZEOF" true
    (match Frontend.Token.kind t2 with
    | Frontend.Token.Meta Frontend.Token.SIZEOF -> true
    | _ -> false)

let test_malformed_input_terminates_with_diagnostics () =
  let lexer = make_lexer "\"unterminated" in
  let tokens = Frontend.Lexer.lex_all lexer in
  let diagnostics = Frontend.Lexer.diagnostics lexer in
  Alcotest.(check bool) "lex_all terminates with eof" true
    (match Frontend.Token.kind (List.hd (List.rev tokens)) with
    | Frontend.Token.EOF -> true
    | _ -> false);
  Alcotest.(check bool) "diagnostics recorded" true (List.length diagnostics > 0)

let test_peek_token_does_not_consume () =
  let lexer = make_lexer "module" in
  let p = Frontend.Lexer.peek_token lexer in
  let n = Frontend.Lexer.next_token lexer in
  Alcotest.(check int) "peek equals next" 0 (Frontend.Token.compare p n)

let test_integration_small_snippet () =
  let lexer = make_lexer "module m;\nvar x = 0b;" in
  let tokens = Frontend.Lexer.lex_all lexer in
  let diagnostics = Frontend.Lexer.diagnostics lexer in
  Alcotest.(check bool) "has module keyword token" true
    (List.exists
       (fun t ->
         match Frontend.Token.kind t with
         | Frontend.Token.Keyword Frontend.Token.Kw_module -> true
         | _ -> false)
       tokens);
  Alcotest.(check bool) "has malformed literal diagnostic" true (List.length diagnostics > 0)

let () =
  Alcotest.run "lexer"
    [ ( "lexer"
      , [ Alcotest.test_case "lex_all_mixed_source" `Quick test_lex_all_mixed_source
        ; Alcotest.test_case "eof_behavior_consistent" `Quick
            test_eof_behavior_consistent
        ; Alcotest.test_case "trivia_skipped_correctly" `Quick
            test_trivia_skipped_correctly
        ; Alcotest.test_case "meta_token_sequence" `Quick test_meta_token_sequence
        ; Alcotest.test_case "malformed_input_terminates_with_diagnostics" `Quick
            test_malformed_input_terminates_with_diagnostics
        ; Alcotest.test_case "peek_token_does_not_consume" `Quick
            test_peek_token_does_not_consume
        ; Alcotest.test_case "integration_small_snippet" `Quick
            test_integration_small_snippet
        ] )
    ]
