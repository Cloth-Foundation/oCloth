module Frontend = Cloth

let unwrap_ok = function
  | Ok value -> value
  | Error _ -> failwith "expected Ok"

let test_from_string_loads () =
  let source_file =
    Frontend.Source_file.from_string ~path:"demo.co"
      ~contents:"module app;\nclass Main {}"
    |> unwrap_ok
  in
  Alcotest.(check string) "contents" "module app;\nclass Main {}"
    source_file.contents

let test_extension_detection () =
  let object_file =
    Frontend.Source_file.from_string ~path:"x.co" ~contents:""
  in
  let library_file =
    Frontend.Source_file.from_string ~path:"x.clib" ~contents:""
  in
  let invalid_file =
    Frontend.Source_file.from_string ~path:"x.txt" ~contents:""
  in
  Alcotest.(check bool) "object extension" true
    (match object_file with
    | Ok value -> value.file_kind = Frontend.Source_file.Cloth_object
    | Error _ -> false);
  Alcotest.(check bool) "library extension" true
    (match library_file with
    | Ok value -> value.file_kind = Frontend.Source_file.Cloth_library
    | Error _ -> false);
  Alcotest.(check bool) "invalid extension" true
    (match invalid_file with
    | Error Frontend.Source_file.Invalid_extension -> true
    | _ -> false)

let test_metadata_correctness () =
  let source_file =
    Frontend.Source_file.from_string ~path:"src/main.clib" ~contents:"x"
    |> unwrap_ok
  in
  Alcotest.(check string) "file name" "main.clib" source_file.file_name;
  Alcotest.(check string) "base name" "main" source_file.base_name;
  Alcotest.(check string) "extension" ".clib" source_file.extension;
  Alcotest.(check bool) "absolute path" true
    (not (Filename.is_relative source_file.absolute_path))

let test_line_retrieval () =
  let source_file =
    Frontend.Source_file.from_string ~path:"lines.co"
      ~contents:"first\nsecond\nthird"
    |> unwrap_ok
  in
  Alcotest.(check (option string)) "line 1" (Some "first")
    (Frontend.Source_file.get_line source_file 1);
  Alcotest.(check (option string)) "line 2" (Some "second")
    (Frontend.Source_file.get_line source_file 2);
  Alcotest.(check (option string)) "line 3" (Some "third")
    (Frontend.Source_file.get_line source_file 3);
  Alcotest.(check (option string)) "missing line" None
    (Frontend.Source_file.get_line source_file 4)

let () =
  Alcotest.run "source_file"
    [ ( "source_file"
      , [ Alcotest.test_case "from_string" `Quick test_from_string_loads
        ; Alcotest.test_case "extension_detection" `Quick test_extension_detection
        ; Alcotest.test_case "metadata" `Quick test_metadata_correctness
        ; Alcotest.test_case "get_line" `Quick test_line_retrieval
        ] )
    ]
