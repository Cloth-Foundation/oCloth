module Frontend = Cloth_frontend

let sample_file () =
  match
    Frontend.Source_file.from_string ~path:"sample.co" ~contents:"if x -> y"
  with
  | Ok file -> file
  | Error _ -> failwith "expected sample source file"

let sample_location ~offset ~line ~column =
  Frontend.Source_location.create ~file:(sample_file ()) ~offset ~line ~column

let sample_span () =
  Frontend.Source_span.create
    ~start:(sample_location ~offset:0 ~line:1 ~column:1)
    ~end_:(sample_location ~offset:2 ~line:1 ~column:3)

let test_keyword_detection () =
  Alcotest.(check bool) "if is keyword" true
    (match Frontend.Token.keyword_of_string "if" with
    | Some (Frontend.Token.Keyword Frontend.Token.Kw_if) -> true
    | _ -> false);
  Alcotest.(check bool) "NaN is keyword" true
    (match Frontend.Token.keyword_of_string "NaN" with
    | Some (Frontend.Token.Keyword Frontend.Token.Kw_NaN) -> true
    | _ -> false);
  Alcotest.(check bool) "name is not keyword" true
    (match Frontend.Token.keyword_of_string "name" with None -> true | _ -> false)

let test_meta_keyword_detection () =
  Alcotest.(check bool) "ALIGNOF is meta keyword" true
    (match Frontend.Token.meta_of_string "ALIGNOF" with
    | Some Frontend.Token.ALIGNOF -> true
    | _ -> false);
  Alcotest.(check bool) "alignof is not meta keyword" true
    (match Frontend.Token.meta_of_string "alignof" with None -> true | _ -> false)

let test_token_creation () =
  let span = sample_span () in
  let token =
    Frontend.Token.make
      ~kind:(Frontend.Token.Identifier "name")
      ~lexeme:"name" ~span
  in
  Alcotest.(check bool) "identifier" true
    (match Frontend.Token.kind token with
    | Frontend.Token.Identifier "name" -> true
    | _ -> false);
  Alcotest.(check string) "lexeme" "name" (Frontend.Token.lexeme token)

let test_eof_detection () =
  let span = sample_span () in
  let token = Frontend.Token.make ~kind:Frontend.Token.EOF ~lexeme:"" ~span in
  Alcotest.(check bool) "is eof" true (Frontend.Token.is_eof token)

let test_string_formatting () =
  let span = sample_span () in
  let token = Frontend.Token.make ~kind:Frontend.Token.UNKNOWN ~lexeme:"@" ~span in
  let rendered = Frontend.Token.to_string token in
  Alcotest.(check bool) "contains unknown" true (String.contains rendered 'U');
  Alcotest.(check bool) "contains lexeme" true
    (String.contains rendered '@')

let () =
  Alcotest.run "token"
    [ ( "token"
      , [ Alcotest.test_case "keyword_detection" `Quick test_keyword_detection
        ; Alcotest.test_case "meta_keyword_detection" `Quick
            test_meta_keyword_detection
        ; Alcotest.test_case "creation" `Quick test_token_creation
        ; Alcotest.test_case "eof_detection" `Quick test_eof_detection
        ; Alcotest.test_case "string_formatting" `Quick test_string_formatting
        ] )
    ]
