(* src/frontend/cloth_frontend.ml *)

let () = Backend_bindings.initialize ()

let read_source_file path =
  try
    let source =
      let channel = open_in_bin path in
      Fun.protect
        ~finally:(fun () -> close_in_noerr channel)
        (fun () ->
          let len = in_channel_length channel in
          really_input_string channel len)
    in
    Ok source
  with Sys_error msg -> Error msg

let lex_source = Lexer.tokenize

let compile_file path =
  match read_source_file path with
  | Error msg -> Error msg
  | Ok source -> (
      match lex_source source with
      | Ok _ ->
          Ok ()
      | Error msg -> Error (Printf.sprintf "lex error in %s: %s" path msg) )