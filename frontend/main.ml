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

let print_usage () =
  prerr_endline "Usage:";
  prerr_endline "  cloth <file>";
  prerr_endline "  cloth lexer <file>"

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
      let tokens = Frontend.Lexer.lex_all lexer in
      let diagnostics = Frontend.Lexer.diagnostics lexer in
      if diagnostics <> [] then print_diagnostics diagnostics;
      List.iter print_token tokens;
      0

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let exit_code =
    match args with
    | [ "lexer"; file ] -> run_lex file
    | [ "lexer" ] ->
        prerr_endline "error: missing file for lexer command";
        1
    | [ file ] -> run_lex file
    | cmd :: _ ->
        prerr_endline ("error: unknown command '" ^ cmd ^ "'");
        print_usage ();
        1
    | [] ->
        print_usage ();
        1
  in
  exit exit_code
