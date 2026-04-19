module Frontend = Cloth

let test_identifier_rules () =
  Alcotest.(check bool) "letter starts identifier" true
    (Frontend.Char_class.is_identifier_start 'a');
  Alcotest.(check bool) "underscore starts identifier" true
    (Frontend.Char_class.is_identifier_start '_');
  Alcotest.(check bool) "digit does not start identifier" false
    (Frontend.Char_class.is_identifier_start '1');
  Alcotest.(check bool) "dollar only in identifier part" true
    (Frontend.Char_class.is_identifier_part '$')

let test_ascii_only_enforcement () =
  Alcotest.(check bool) "ascii letter allowed" true
    (Frontend.Char_class.is_ascii_letter 'Z');
  Alcotest.(check bool) "non-ascii letter rejected" false
    (Frontend.Char_class.is_identifier_start '\192')

let test_digit_classification () =
  Alcotest.(check bool) "binary 1" true (Frontend.Char_class.is_binary_digit '1');
  Alcotest.(check bool) "binary 2 false" false (Frontend.Char_class.is_binary_digit '2');
  Alcotest.(check bool) "octal 7" true (Frontend.Char_class.is_octal_digit '7');
  Alcotest.(check bool) "octal 8 false" false (Frontend.Char_class.is_octal_digit '8');
  Alcotest.(check bool) "decimal 9" true (Frontend.Char_class.is_decimal_digit '9');
  Alcotest.(check bool) "hex F" true (Frontend.Char_class.is_hex_digit 'F');
  Alcotest.(check bool) "hex g false" false (Frontend.Char_class.is_hex_digit 'g')

let test_whitespace_and_terminators () =
  Alcotest.(check bool) "space whitespace" true (Frontend.Char_class.is_whitespace ' ');
  Alcotest.(check bool) "tab whitespace" true (Frontend.Char_class.is_whitespace '\t');
  Alcotest.(check bool) "lf whitespace" true (Frontend.Char_class.is_whitespace '\n');
  Alcotest.(check bool) "cr whitespace" true (Frontend.Char_class.is_whitespace '\r');
  Alcotest.(check bool) "vertical tab not whitespace" false
    (Frontend.Char_class.is_whitespace '\011');
  Alcotest.(check bool) "lf line terminator" true
    (Frontend.Char_class.is_line_terminator '\n');
  Alcotest.(check bool) "cr line terminator" true
    (Frontend.Char_class.is_line_terminator '\r')

let test_comment_helpers () =
  Alcotest.(check bool) "line comment start" true
    (Frontend.Char_class.is_line_comment_start ~current:'/' ~next:(Some '/'));
  Alcotest.(check bool) "block comment start" true
    (Frontend.Char_class.is_block_comment_start ~current:'/' ~next:(Some '*'));
  Alcotest.(check bool) "non-comment slash" false
    (Frontend.Char_class.is_comment_start ~current:'/' ~next:(Some '+'))

let test_operator_start_helpers () =
  Alcotest.(check bool) "plus starts operator" true
    (Frontend.Char_class.is_operator_or_punctuation_start '+');
  Alcotest.(check bool) "lparen starts punctuation" true
    (Frontend.Char_class.is_operator_or_punctuation_start '(');
  Alcotest.(check bool) "letter does not start operator" false
    (Frontend.Char_class.is_operator_or_punctuation_start 'a')

let () =
  Alcotest.run "char_class"
    [ ( "char_class"
      , [ Alcotest.test_case "identifier_rules" `Quick test_identifier_rules
        ; Alcotest.test_case "ascii_only" `Quick test_ascii_only_enforcement
        ; Alcotest.test_case "digit_classification" `Quick test_digit_classification
        ; Alcotest.test_case "whitespace" `Quick test_whitespace_and_terminators
        ; Alcotest.test_case "comment_helpers" `Quick test_comment_helpers
        ; Alcotest.test_case "operator_helpers" `Quick test_operator_start_helpers
        ] )
    ]
