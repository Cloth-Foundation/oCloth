module Frontend = Cloth

let kind_to_string = function
  | Frontend.Token.Identifier _ -> "Identifier"
  | Frontend.Token.Keyword _ -> "Keyword"
  | Frontend.Token.Literal _ -> "Literal"
  | Frontend.Token.OperatorPunctuation _ -> "OperatorPunctuation"
  | Frontend.Token.Meta _ -> "Meta"
  | Frontend.Token.EOF -> "EOF"
  | Frontend.Token.UNKNOWN -> "UNKNOWN"

let print_token token =
  let kind = kind_to_string (Frontend.Token.kind token) in
  let lexeme = String.escaped (Frontend.Token.lexeme token) in
  let span = Frontend.Token.span token in
  let start = span.Frontend.Source_span.start in
  let file = Frontend.Source_location.file start in
  Printf.printf "%s \"%s\" @ %s:%d:%d\n" kind lexeme file.absolute_path
    (Frontend.Source_location.line start) (Frontend.Source_location.column start)

let print_diagnostics diagnostics =
  List.iter
    (fun diagnostic ->
      let rendered = Frontend.Diagnostic_renderer.render diagnostic in
      output_string stderr rendered)
    diagnostics

let run_lex path =
  match Frontend.Source_file.from_path path with
  | Error Frontend.Source_file.Invalid_extension ->
      prerr_endline "error: invalid source file extension";
      1
  | Error Frontend.Source_file.File_not_found ->
      prerr_endline "error: source file not found";
      1
  | Error (Frontend.Source_file.IOError msg) ->
      prerr_endline ("error: unable to read source file: " ^ msg);
      1
  | Ok source ->
      let lexer = Frontend.Lexer.create source in
      let _tokens = Frontend.Lexer.lex_all lexer in
      let diagnostics = Frontend.Lexer.diagnostics lexer in
      if diagnostics <> [] then print_diagnostics diagnostics;
      if !(Frontend.Cmd_exec.dump_tokens) then List.iter print_token _tokens;
      0

let command_of_string = function
    | "lexer" -> Some `Lexer
    | "-help" | "?" -> Some `Help
    | "version" -> Some `Version
    | _ -> None

let process_flags args =
  List.filter
    (fun arg ->
      match arg with
      | "-dump-tokens" ->
          Frontend.Cmd_exec.dump_tokens := true;
          false
      | _ -> true)
    args

let () =
  let args = Array.to_list Sys.argv |> List.tl |> process_flags in
  let exit_code = 
    match args with
    | cmd :: file :: [] -> (
      match command_of_string cmd with 
        | Some `Lexer -> run_lex file
        | Some `Help -> 
          Frontend.Cmd_strings.help ();
          0
        | Some `Version -> 
          Frontend.Cmd_exec.print_version ();
          0
        | None -> 
          prerr_endline ("error: unknown command '" ^ cmd ^ "'");
          1
    )
    | [ cmd ] -> (
      match command_of_string cmd with
        | Some `Lexer -> 
          prerr_endline "error: no file specified";
          1
        | Some `Help -> 
          Frontend.Cmd_strings.help ();
          0
        | Some `Version -> 
          Frontend.Cmd_exec.print_version ();
          0
        | None -> 
          prerr_endline ("error: unknown command '" ^ cmd ^ "'");
          1
    )
    | [] -> 
      Frontend.Cmd_strings.help ();
      1
    | cmd :: _ -> 
      prerr_endline ("error: invalid arguments for command '" ^ cmd ^ "'");
      Frontend.Cmd_strings.help ();
      1
  in
  exit exit_code
