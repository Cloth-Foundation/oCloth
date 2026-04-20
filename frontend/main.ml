module Frontend = Cloth

let print_diagnostics diagnostics =
  List.iter
    (fun diagnostic ->
      let rendered = Frontend.Diagnostic_renderer.render diagnostic in
      output_string stderr rendered)
    diagnostics

let write_string_to_file path contents =
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel contents)

let run_lex path =
  match Frontend.Source_file.from_path path with
  | Error Frontend.Source_file.Invalid_extension ->
      prerr_endline "error: invalid source file extension";
      (1, 0)
  | Error Frontend.Source_file.File_not_found ->
      prerr_endline "error: source file not found";
      (1, 0)
  | Error (Frontend.Source_file.IOError msg) ->
      prerr_endline ("error: unable to read source file: " ^ msg);
      (1, 0)
  | Ok source ->
      let lexer = Frontend.Lexer.create source in
      let _tokens = Frontend.Lexer.lex_all lexer in
      let diagnostics = Frontend.Lexer.diagnostics lexer in
      if diagnostics <> [] then print_diagnostics diagnostics;
      if !(Frontend.Cmd_exec.dump_tokens) then (
        if not !(Frontend.Cmd_exec.write_only) then
          Frontend.Print_lexer_stream.print_tokens_json _tokens;
        match !(Frontend.Cmd_exec.write_tokens) with
        | None -> ()
        | Some dest ->
            let base_output_name = source.base_name ^ ".json" in
            let output_path =
              if dest = "" then Filename.concat source.directory_path base_output_name
              else
                let is_existing_dir =
                  try Sys.file_exists dest && Sys.is_directory dest with
                  | _ -> false
                in
                let looks_like_dir =
                  String.length dest > 0
                  && (dest.[String.length dest - 1] = '/' || dest.[String.length dest - 1] = '\\'
                     || Filename.extension dest = "")
                in
                if is_existing_dir || looks_like_dir then
                  Filename.concat dest base_output_name
                else dest
            in
            let json = Frontend.Print_lexer_stream.tokens_json_string _tokens in
            write_string_to_file output_path json);
      (0, List.length _tokens)

let command_of_string = function
    | "lexer" -> Some `Lexer
    | "-help" | "?" -> Some `Help
    | "version" -> Some `Version
    | _ -> None

let process_flags args =
  let rec loop acc = function
    | [] -> List.rev acc
    | "--dump-tokens" :: rest ->
        Frontend.Cmd_exec.dump_tokens := true;
        loop acc rest
    | ("--write") :: rest -> (
        match rest with
        | path :: tail when not (String.length path > 0 && path.[0] = '-') ->
            Frontend.Cmd_exec.write_tokens := Some path;
            loop acc tail
        | _ ->
            Frontend.Cmd_exec.write_tokens := Some "";
            loop acc rest )
    | ("--write-only") :: rest ->
        Frontend.Cmd_exec.dump_tokens := true;
        Frontend.Cmd_exec.write_only := true;
        if !(Frontend.Cmd_exec.write_tokens) = None then
          Frontend.Cmd_exec.write_tokens := Some "";
        loop acc rest
    | arg :: rest -> loop (arg :: acc) rest
  in
  loop [] args

let () =
  let args = Array.to_list Sys.argv |> List.tl |> process_flags in
  let exit_code = 
    match args with
    | cmd :: file :: [] -> (
      match command_of_string cmd with 
        | Some `Lexer -> 
          let exit_code, token_count = run_lex file in
          if exit_code = 0 then
            Printf.printf "Successfully lexed %d tokens.\n" token_count;
          exit_code
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
