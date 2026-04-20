let print_diagnostics diagnostics =
  List.iter
    (fun diagnostic ->
      let rendered = Diagnostic_renderer.render diagnostic in
      output_string stderr rendered)
    diagnostics

let write_string_to_file path contents =
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel contents)

let output_path_for_source ~source ~dest =
  let base_output_name = source.Source_file.base_name ^ ".json" in
  if dest = "" then Filename.concat source.directory_path base_output_name
  else
    let is_existing_dir =
      try Sys.file_exists dest && Sys.is_directory dest with
      | _ -> false
    in
    let looks_like_dir =
      String.length dest > 0
      && (dest.[String.length dest - 1] = '/'
         || dest.[String.length dest - 1] = '\\'
         || Filename.extension dest = "")
    in
    if is_existing_dir || looks_like_dir then Filename.concat dest base_output_name
    else dest

type lex_dump = {
  dump_tokens : bool;
  write_only : bool;
  write_dest : string option;
}

type lexer_options = {
  dump_tokens : bool;
  write_default : bool;
  write_to : string option;
  write_only : bool;
}

let run_lex ~path (dump : lex_dump) =
  match Source_file.from_path path with
  | Error Source_file.Invalid_extension ->
      prerr_endline "error: invalid source file extension";
      (1, 0)
  | Error Source_file.File_not_found ->
      prerr_endline "error: source file not found";
      (1, 0)
  | Error (Source_file.IOError msg) ->
      prerr_endline ("error: unable to read source file: " ^ msg);
      (1, 0)
  | Ok source ->
      let lexer = Lexer.create source in
      let tokens = Lexer.lex_all lexer in
      let diagnostics = Lexer.diagnostics lexer in
      if diagnostics <> [] then print_diagnostics diagnostics;
      if dump.dump_tokens then (
        if not dump.write_only then Print_lexer_stream.print_tokens_json tokens;
        match dump.write_dest with
        | None -> ()
        | Some dest ->
            let output_path = output_path_for_source ~source ~dest in
            let json = Print_lexer_stream.tokens_json_string tokens in
            write_string_to_file output_path json);
      (0, List.length tokens)

let lexer ~file ~(options : lexer_options) =
  let should_dump =
    options.dump_tokens || options.write_default || options.write_to <> None
    || options.write_only
  in
  let write_dest =
    match (options.write_default, options.write_to, options.write_only) with
    | _, Some path, _ -> Some path
    | true, None, _ -> Some ""
    | false, None, true -> Some ""
    | false, None, false -> None
  in
  let dump : lex_dump =
    { dump_tokens = should_dump; write_only = options.write_only; write_dest }
  in
  run_lex ~path:file dump
