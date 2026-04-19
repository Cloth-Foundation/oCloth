module Frontend = Cloth

let unwrap_ok = function
  | Ok value -> value
  | Error _ -> failwith "expected Ok"

let sample_file () =
  Frontend.Source_file.from_string ~path:"span.co"
    ~contents:"line1\nline2\nline3"
  |> unwrap_ok

let mk_loc file offset line column =
  Frontend.Source_location.create ~file ~offset ~line ~column

let test_advance_across_lines () =
  let file = sample_file () in
  let l0 = Frontend.Source_location.start_of_file file in
  let l1 = Frontend.Source_location.advance l0 'a' in
  let l2 = Frontend.Source_location.advance l1 '\n' in
  let l3 = Frontend.Source_location.advance l2 'b' in
  Alcotest.(check int) "offset after a" 1 l1.offset;
  Alcotest.(check int) "line after a" 1 l1.line;
  Alcotest.(check int) "column after a" 2 l1.column;
  Alcotest.(check int) "offset after newline" 2 l2.offset;
  Alcotest.(check int) "line after newline" 2 l2.line;
  Alcotest.(check int) "column reset after newline" 1 l2.column;
  Alcotest.(check int) "column after b" 2 l3.column

let test_span_creation_and_length () =
  let file = sample_file () in
  let span =
    Frontend.Source_span.create ~start:(mk_loc file 2 1 3)
      ~end_:(mk_loc file 9 2 4)
  in
  Alcotest.(check int) "span length" 7 (Frontend.Source_span.length span)

let test_contains () =
  let file = sample_file () in
  let span =
    Frontend.Source_span.create ~start:(mk_loc file 2 1 3)
      ~end_:(mk_loc file 6 1 7)
  in
  Alcotest.(check bool) "contains start" true
    (Frontend.Source_span.contains span (mk_loc file 2 1 3));
  Alcotest.(check bool) "contains middle" true
    (Frontend.Source_span.contains span (mk_loc file 4 1 5));
  Alcotest.(check bool) "contains end" true
    (Frontend.Source_span.contains span (mk_loc file 6 1 7));
  Alcotest.(check bool) "outside" false
    (Frontend.Source_span.contains span (mk_loc file 7 1 8))

let test_merge () =
  let file = sample_file () in
  let a =
    Frontend.Source_span.create ~start:(mk_loc file 1 1 2)
      ~end_:(mk_loc file 4 1 5)
  in
  let b =
    Frontend.Source_span.create ~start:(mk_loc file 3 1 4)
      ~end_:(mk_loc file 8 2 2)
  in
  let merged = Frontend.Source_span.merge a b in
  Alcotest.(check int) "merged start" 1 merged.start.offset;
  Alcotest.(check int) "merged end" 8 merged.end_.offset

let () =
  Alcotest.run "source_span"
    [ ( "source_span"
      , [ Alcotest.test_case "advance" `Quick test_advance_across_lines
        ; Alcotest.test_case "length" `Quick test_span_creation_and_length
        ; Alcotest.test_case "contains" `Quick test_contains
        ; Alcotest.test_case "merge" `Quick test_merge
        ] )
    ]
