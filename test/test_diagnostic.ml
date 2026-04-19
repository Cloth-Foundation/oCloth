module Frontend = Cloth

let unwrap_ok = function
  | Ok value -> value
  | Error _ -> failwith "expected Ok"

let contains_substring haystack needle =
  let hay_len = String.length haystack in
  let needle_len = String.length needle in
  let rec loop i =
    if i + needle_len > hay_len then false
    else if String.sub haystack i needle_len = needle then true
    else loop (i + 1)
  in
  if needle_len = 0 then true else loop 0

let make_diagnostic ~contents ~line ~start_col ~end_col ~severity ~code ~message
    ~primary_label ?(notes = []) ?(helps = []) ?(clause_refs = []) () =
  let source =
    Frontend.Source_file.from_string ~path:"diag.co" ~contents |> unwrap_ok
  in
  let start =
    Frontend.Source_location.create ~file:source ~offset:0 ~line ~column:start_col
  in
  let end_ =
    Frontend.Source_location.create ~file:source ~offset:0 ~line ~column:end_col
  in
  let span = Frontend.Source_span.create ~start ~end_ in
  Frontend.Diagnostic.make ~severity ~code ~message ~span ~primary_label ~notes
    ~helps ~clause_refs ()

let test_error_single_char_underline () =
  let d =
    make_diagnostic ~contents:"let x = §" ~line:1 ~start_col:9 ~end_col:10
      ~severity:Frontend.Diagnostic.Error ~code:"LEX001"
      ~message:"illegal character" ~primary_label:"illegal character appears here"
      ()
  in
  let rendered = Frontend.Diagnostic_renderer.render d in
  let span = Frontend.Diagnostic.span d in
  let file = Frontend.Source_location.file span.start in
  let expected =
    Printf.sprintf
      "error[LEX001]: illegal character\n --> %s:1:9\n  |\n1 | let x = §\n  |         ^ illegal character appears here\n  |\n"
      file.absolute_path
  in
  Alcotest.(check string) "single-char render" expected rendered

let test_error_multi_char_underline () =
  let d =
    make_diagnostic ~contents:"let s = \"hello" ~line:1 ~start_col:9 ~end_col:15
      ~severity:Frontend.Diagnostic.Error ~code:"LEX004"
      ~message:"unterminated string literal"
      ~primary_label:"string literal starts here" ()
  in
  let rendered = Frontend.Diagnostic_renderer.render d in
  Alcotest.(check bool) "multi-char underline" true
    (contains_substring rendered "|         ^^^^^^ string literal starts here")

let test_warning_with_note () =
  let d =
    make_diagnostic ~contents:"let s = \"\\q\"" ~line:1 ~start_col:10 ~end_col:12
      ~severity:Frontend.Diagnostic.Warning ~code:"LEX007"
      ~message:"unknown escape sequence; escaped character preserved literally"
      ~primary_label:"unknown escape sequence"
      ~notes:[ "unrecognized escapes are treated as the escaped character" ] ()
  in
  let rendered = Frontend.Diagnostic_renderer.render d in
  Alcotest.(check bool) "warning severity line" true
    (contains_substring rendered "warning[LEX007]: unknown escape sequence; escaped character preserved literally");
  Alcotest.(check bool) "note line present" true
    (contains_substring rendered
       "= note: unrecognized escapes are treated as the escaped character")

let test_error_with_note_and_help () =
  let d =
    make_diagnostic ~contents:"let s = \"hello" ~line:1 ~start_col:9 ~end_col:15
      ~severity:Frontend.Diagnostic.Error ~code:"LEX004"
      ~message:"unterminated string literal"
      ~primary_label:"string literal starts here"
      ~notes:[ "string literals must end before the line ends" ]
      ~helps:[ "add a closing double quote" ] ()
  in
  let rendered = Frontend.Diagnostic_renderer.render d in
  Alcotest.(check bool) "note included" true
    (contains_substring rendered
       "= note: string literals must end before the line ends");
  Alcotest.(check bool) "help included" true
    (contains_substring rendered "= help: add a closing double quote")

let test_rendering_hides_spec_references () =
  let d =
    make_diagnostic ~contents:"let x = §" ~line:1 ~start_col:9 ~end_col:10
      ~severity:Frontend.Diagnostic.Error ~code:"LEX001"
      ~message:"illegal character" ~primary_label:"illegal character appears here"
      ~clause_refs:[ "2.2.6"; "1.2.5" ] ()
  in
  let rendered = Frontend.Diagnostic_renderer.render d in
  Alcotest.(check bool) "clause ref hidden" false
    (contains_substring rendered "2.2.6")

let () =
  Alcotest.run "diagnostic"
    [ ( "diagnostic"
      , [ Alcotest.test_case "error_single_char_underline" `Quick
            test_error_single_char_underline
        ; Alcotest.test_case "error_multi_char_underline" `Quick
            test_error_multi_char_underline
        ; Alcotest.test_case "warning_with_note" `Quick
            test_warning_with_note
        ; Alcotest.test_case "error_with_note_and_help" `Quick
            test_error_with_note_and_help
        ; Alcotest.test_case "rendering_hides_spec_references" `Quick
            test_rendering_hides_spec_references
        ] )
    ]
