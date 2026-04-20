let kind_to_string = function
  | Token.Identifier _ -> "Identifier"
  | Token.Keyword _ -> "Keyword"
  | Token.Literal _ -> "Literal"
  | Token.OperatorPunctuation _ -> "OperatorPunctuation"
  | Token.Meta _ -> "Meta"
  | Token.EOF -> "EOF"
  | Token.UNKNOWN -> "UNKNOWN"

let token_to_json token =
  let kind = kind_to_string (Token.kind token) in
  let lexeme = Token.lexeme token in
  let span = Token.span token in
  let start = span.Source_span.start in 
  let file = Source_location.file start in

  `Assoc [
    ("kind", `String kind);
    ("lexeme", `String lexeme);
    ("location",
      `Assoc [
        ("file", `String file.file_name);
        ("line", `Int (Source_location.line start));
        ("column", `Int (Source_location.column start));
        ("offset", `Int (Source_location.offset start));
        ("span", `String (Source_span.span_to_string span))
      ])
  ]

let token_to_json_at index token =
  match token_to_json token with
  | `Assoc fields -> `Assoc (("#", `Int (index + 1)) :: fields)
  | json -> json

let print_token_json token =
  token_to_json token
  |> Yojson.Safe.pretty_to_string
  |> print_endline

let print_tokens_json tokens =
  let json =
    `Assoc
      [ ("tokens", `List (List.mapi token_to_json_at tokens))
      ; ("token_count", `Int (List.length tokens))
      ; ("file_name", `String (List.hd tokens).Token.span.Source_span.start.Source_location.file.base_name)
      ; ("file_path", `String (List.hd tokens).Token.span.Source_span.start.Source_location.file.absolute_path)
      ; ("success", `Bool true)
      ]
  in
  json |> Yojson.Safe.pretty_to_string |> print_endline

let tokens_json_string tokens =
  let json =
    `Assoc
      [ ("tokens", `List (List.mapi token_to_json_at tokens))
      ; ("token_count", `Int (List.length tokens))
      ; ("file_name", `String (List.hd tokens).Token.span.Source_span.start.Source_location.file.base_name)
      ; ("file_path", `String (List.hd tokens).Token.span.Source_span.start.Source_location.file.absolute_path)
      ; ("success", `Bool true)
      ]
  in
  Yojson.Safe.pretty_to_string json