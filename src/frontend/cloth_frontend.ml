(* src/frontend/cloth_frontend.ml *)

let () = Backend_bindings.initialize ()

let compile_file path =
  try
    let source =
      let channel = open_in_bin path in
      Fun.protect
        ~finally:(fun () -> close_in_noerr channel)
        (fun () ->
          let len = in_channel_length channel in
          really_input_string channel len)
    in
    Format.printf "Loaded %d bytes from %s@." (String.length source) path;
    Ok ()
  with Sys_error msg -> Error msg

let demo_token () =
  let tok =
    Token.Token.make
      ~kind:(Token.Token.Identifier "abc")
      ~lexeme:"abc"
      ~span:
        {
          Token.Token.start_pos = { offset = 0; line = 1; column = 1 };
          end_pos = { offset = 3; line = 1; column = 4 };
        }
  in
  Format.printf "Token: kind=%s, lexeme=%s, span=[%d:%d-%d:%d]@."
    (match tok.Token.Token.kind with
    | Token.Token.Identifier id -> Printf.sprintf "Identifier(%s)" id
    | Token.Token.Keyword kw -> Printf.sprintf "Keyword(%s)" kw
    | Token.Token.Symbol sym -> Printf.sprintf "Symbol(%s)" sym
    | Token.Token.Integer i -> Printf.sprintf "Integer(%d)" i
    | Token.Token.Float f -> Printf.sprintf "Float(%f)" f
    | Token.Token.String s -> Printf.sprintf "String(%S)" s
    | _ -> "Other")
    tok.Token.Token.lexeme
    tok.Token.Token.span.Token.Token.start_pos.line
    tok.Token.Token.span.Token.Token.start_pos.column
    tok.Token.Token.span.Token.Token.end_pos.line
    tok.Token.Token.span.Token.Token.end_pos.column