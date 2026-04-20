module Frontend = Cloth

module CArg = Cmdliner.Arg
module Term = Cmdliner.Term
module Cmd = Cmdliner.Cmd

let lexer_cmd =
  let file =
    let doc = "Source file to lex." in
    CArg.(required & pos 0 (some string) None & info [] ~docv:"FILE" ~doc)
  in
  let dump_tokens =
    let doc = "Dump lexer tokens as JSON to stdout." in
    CArg.(value & flag & info [ "dump-tokens" ] ~doc)
  in
  let write_default =
    let doc =
      "Write dumped lexer token JSON next to the input file as <base>.json."
    in
    CArg.(value & flag & info [ "write" ] ~doc)
  in
  let write_to =
    let doc =
      "Write dumped lexer token JSON to PATH. If PATH is a directory, writes <base>.json inside it."
    in
    CArg.(value & opt (some string) None & info [ "write-to" ] ~docv:"PATH" ~doc)
  in
  let write_only =
    let doc = "Write token JSON to disk but do not print it to stdout." in
    CArg.(value & flag & info [ "write-only" ] ~doc)
  in
  let term =
    Term.(
      const (fun file dump_tokens write_default write_to write_only ->
          let options : Frontend.Runner.lexer_options =
            { dump_tokens; write_default; write_to; write_only }
          in
          let exit_code, token_count = Frontend.Runner.lexer ~file ~options in
          if exit_code = 0 then
            Printf.printf "Successfully lexed %d tokens.\n" token_count;
          exit_code)
      $ file $ dump_tokens $ write_default $ write_to $ write_only)
  in
  Cmd.v (Cmd.info "lexer" ~doc:"Lex a Cloth source file." ~man:[]) term

let version_cmd =
  let term =
    Term.(const (fun () ->
        Frontend.Cmd_exec.print_version ();
        0)
    $ const ())
  in
  Cmd.v (Cmd.info "version" ~doc:"Print compiler version." ~man:[]) term

let help_cmd =
  let term =
    Term.(const (fun () ->
        Frontend.Cmd_strings.help ();
        0)
    $ const ())
  in
  Cmd.v (Cmd.info "help" ~doc:"Show help." ~man:[]) term

let default_term =
  Term.(const (fun () ->
      Frontend.Cmd_strings.help ();
      1)
  $ const ())

let main () =
  let argv = Sys.argv in
  let has_custom_help_request =
    Array.exists
      (fun a -> a = "-h" || a = "--help" || a = "help" || a = "?")
      argv
  in
  if has_custom_help_request then (
    Frontend.Cmd_strings.help ();
    0)
  else
    Cmd.eval'
      (Cmd.group
         (Cmd.info "cloth" ~doc:"Cloth compiler." ~man:[])
         ~default:default_term
         [ lexer_cmd; version_cmd; help_cmd ])
