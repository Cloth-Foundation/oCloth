let cloth_version = "0.0.1"

let executable_name = "cloth"

let supported_extensions = [ ".co"; ".cloth"; ".clib" ]
let supported_extensions_text = String.concat ", " supported_extensions

let has_supported_extension path =
  List.exists (Filename.check_suffix path) supported_extensions

let print_lines channel lines =
  List.iter (fun line -> output_string channel (line ^ "\n")) lines

type command_mode = Build | Compile | Check | Run

type resolved_target =
  | Direct_source of string
  | Project_entry of {
      project_dir : string;
      build_file : string;
      main_class : string;
      entry_file : string;
    }

let command_name = function
  | Build -> "build"
  | Compile -> "compile"
  | Check -> "check"
  | Run -> "run"

let mode_of_string = function
  | "build" -> Some Build
  | "compile" -> Some Compile
  | "check" -> Some Check
  | "run" -> Some Run
  | _ -> None

let trim_trailing_separators path =
  let rec loop index =
    if index <= 0 then index
    else
      match path.[index] with
      | '/' | '\\' -> loop (index - 1)
      | _ -> index
  in
  if path = "" then path
  else
    let last = loop (String.length path - 1) in
    if last = String.length path - 1 then path else String.sub path 0 (last + 1)

let normalize_path path =
  let path = trim_trailing_separators path in
  if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path

let is_directory path =
  try Sys.is_directory path with Sys_error _ -> false

let is_build_toml path =
  String.lowercase_ascii (Filename.basename path) = "build.toml"

let looks_like_path path =
  path = "." || path = ".." || String.contains path '/' || String.contains path '\\'

let strip_comment line =
  match String.index_opt line '#' with
  | Some index -> String.sub line 0 index
  | None -> line

let unquote value =
  let value = String.trim value in
  let len = String.length value in
  if len >= 2 && value.[0] = '"' && value.[len - 1] = '"' then
    String.sub value 1 (len - 2)
  else value

let rec find_build_toml_from_dir dir =
  let candidate = Filename.concat dir "build.toml" in
  if Sys.file_exists candidate then Some candidate
  else
    let parent = Filename.dirname dir in
    if parent = dir then None else find_build_toml_from_dir parent

let find_build_toml target =
  let normalized = normalize_path target in
  if is_build_toml normalized && Sys.file_exists normalized then Some normalized
  else
    let start_dir =
      if is_directory normalized then normalized else Filename.dirname normalized
    in
    find_build_toml_from_dir start_dir

let parse_main_class build_file =
  let read_binding line =
    let cleaned = String.trim (strip_comment line) in
    if cleaned = "" then None
    else
      match String.index_opt cleaned '=' with
      | None -> None
      | Some index ->
          let key = String.sub cleaned 0 index |> String.trim in
          let value_length = String.length cleaned - index - 1 in
          let value = String.sub cleaned (index + 1) value_length |> unquote in
          if List.mem key [ "main"; "main_class"; "mainClass"; "entry" ] then
            Some value
          else None
  in
  try
    let channel = open_in build_file in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () ->
        let rec loop () =
          match input_line channel with
          | line -> (
              match read_binding line with
              | Some value when value <> "" -> Ok value
              | _ -> loop () )
          | exception End_of_file -> Ok "Main"
        in
        loop ())
  with Sys_error msg -> Error msg

let resolve_main_file project_dir main_class =
  let src_dir = Filename.concat project_dir "src" in
  let candidate_names =
    if has_supported_extension main_class then [ main_class ]
    else List.map (fun extension -> main_class ^ extension) supported_extensions
  in
  let candidates =
    if Filename.is_implicit main_class then
      let in_src = List.map (Filename.concat src_dir) candidate_names in
      let in_root = List.map (Filename.concat project_dir) candidate_names in
      in_src @ in_root
    else List.map (Filename.concat project_dir) candidate_names
  in
  match List.find_opt Sys.file_exists candidates with
  | Some entry_file -> Ok entry_file
  | None ->
      Error
        (Printf.sprintf
           "could not find a source file for main class %S in %s. Expected one of: %s"
           main_class project_dir
           (String.concat ", " candidates))

let resolve_project_target target =
  match find_build_toml target with
  | None ->
      Error
        (Printf.sprintf "could not locate build.toml from %S or its parent directories." target)
  | Some build_file -> (
      let project_dir = Filename.dirname build_file in
      match parse_main_class build_file with
      | Error msg -> Error msg
      | Ok main_class -> (
          match resolve_main_file project_dir main_class with
          | Ok entry_file ->
              Ok (Project_entry { project_dir; build_file; main_class; entry_file })
          | Error msg -> Error msg ) )

let resolve_target_for_mode mode target =
  let target = if String.trim target = "" then "." else target in
  match mode with
  | Build -> resolve_project_target target
  | Compile | Check | Run ->
      if has_supported_extension target && Sys.file_exists target then
        Ok (Direct_source target)
      else if is_directory target || is_build_toml target then
        resolve_project_target target
      else if has_supported_extension target then
        Ok (Direct_source target)
      else resolve_project_target target

let resolved_entry_file = function
  | Direct_source file -> file
  | Project_entry { entry_file; _ } -> entry_file

let resolved_summary = function
  | Direct_source file -> file
  | Project_entry { project_dir; main_class; entry_file; _ } ->
      Printf.sprintf "%s (main=%s -> %s)" project_dir main_class entry_file

let print_help channel =
  print_lines channel
    [ Printf.sprintf "Usage: %s [options] <source-file>" executable_name
    ; Printf.sprintf "       %s build [project-dir]" executable_name
    ; Printf.sprintf "       %s <command> [target]" executable_name
    ; ""
    ; "Compile, check, build, or preview-run a Cloth target."
    ; ""
    ; "Commands:"
    ; "  build      Build from the nearest build.toml (defaults to current directory)"
    ; "  compile    Compile a single Cloth source file or resolved project entry"
    ; "  check      Validate a source file or build.toml project"
    ; "  run        Run preview mode for a source file or build.toml project"
    ; "  help       Show general or command-specific help"
    ; ""
    ; "Supported source kinds:"
    ; "  *.co        low-level Cloth source"
    ; "  *.cloth     standard Cloth source"
    ; "  *.clib      Cloth library input"
    ; ""
    ; "Project config:"
    ; "  build.toml  declares `main = \"Main\"` (or `main_class = \"Main\"`)"
    ; "              and resolves it as `src/Main.co` by default"
    ; ""
    ; "Options:"
    ; "  -h, -help, --help        Print this help message"
    ; "  --help-extra, -X         Print additional launcher guidance"
    ; "  -v, --version            Print version information"
    ; ""
    ; "Examples:"
    ; Printf.sprintf "  %s hello.cloth" executable_name
    ; Printf.sprintf "  %s ./co_project/" executable_name
    ; Printf.sprintf "  %s build" executable_name
    ; Printf.sprintf "  %s build ." executable_name
    ; Printf.sprintf "  %s check app/" executable_name
    ; Printf.sprintf "  %s run app/" executable_name
    ; Printf.sprintf "  %s help build" executable_name
    ]

let print_command_help channel mode =
  let usage, summary, example, note =
    match mode with
    | Build ->
        ( Printf.sprintf "Usage: %s build [project-dir|build.toml]" executable_name
        , "Build the Cloth project rooted at the nearest build.toml file."
        , Printf.sprintf "%s build ./app" executable_name
        , "If `main` is omitted in build.toml, Cloth defaults to `src/Main.co`." )
    | Compile ->
        ( Printf.sprintf "Usage: %s compile <source-file|project-dir>" executable_name
        , "Compile a direct source file, or resolve the project entry from build.toml."
        , Printf.sprintf "%s compile hello.cloth" executable_name
        , "If a directory is passed, the nearest build.toml decides the entry file." )
    | Check ->
        ( Printf.sprintf "Usage: %s check [source-file|project-dir]" executable_name
        , "Validate a source file or a project rooted by build.toml."
        , Printf.sprintf "%s check ./app" executable_name
        , "With no explicit file, check can work from the current project directory." )
    | Run ->
        ( Printf.sprintf "Usage: %s run [source-file|project-dir]" executable_name
        , "Preview execution flow for a source file or build.toml project."
        , Printf.sprintf "%s run ./app" executable_name
        , "Run mode currently performs a compile-backed preview." )
  in
  print_lines channel
    [ usage
    ; ""
    ; summary
    ; ""
    ; "Accepted inputs:"
    ; Printf.sprintf "  %s" supported_extensions_text
    ; "  project directories containing build.toml"
    ; ""
    ; "Example:"
    ; Printf.sprintf "  %s" example
    ; ""
    ; note
    ]

let print_extra_help channel =
  print_lines channel
    [ Printf.sprintf "%s extra help" executable_name
    ; ""
    ; "Command quick reference:"
    ; "  cloth build [dir]      build from the nearest build.toml"
    ; "  cloth <dir>            shorthand for building a project directory"
    ; "  cloth compile <file>   compile a source file directly"
    ; "  cloth check [target]   validate a file or project"
    ; "  cloth run [target]     preview run behavior"
    ; "  cloth help <command>   show command-specific help"
    ; ""
    ; "Project rules:"
    ; "  - build.toml chooses the entry class via `main = \"Main\"`."
    ; "  - Plain class names resolve from `src/` by default, e.g. `Main` -> `src/Main.co`."
    ; "  - Class files are expected to have the same name as the class."
    ; ""
    ; "Accepted source extensions:"
    ; Printf.sprintf "  %s" supported_extensions_text
    ; ""
    ; "Exit codes:"
    ; "  0  success"
    ; "  1  invalid arguments or compile failure"
    ]

let print_version channel =
  print_lines channel [ Printf.sprintf "cloth version %s" cloth_version ]

let fail_with_help message =
  prerr_endline ("error: " ^ message);
  print_help stderr;
  exit 1

let fail_unknown_command command =
  Printf.eprintf "error: unknown command %S\n" command;
  print_help stderr;
  exit 1

let execute_mode mode target =
  match resolve_target_for_mode mode target with
  | Error msg ->
      prerr_endline ("error: " ^ msg);
      exit 1
  | Ok resolved ->
      let entry_file = resolved_entry_file resolved in
      match Cloth_frontend.compile_file entry_file with
      | Ok () -> (
          match mode with
          | Build ->
              Printf.printf "Build succeeded with exit code 0\n"
          | Compile ->
              Printf.printf "Compile succeeded for %s\n" (resolved_summary resolved)
          | Check ->
              Printf.printf "Check succeeded for %s\n" (resolved_summary resolved)
          | Run ->
              Printf.printf "Run preview succeeded for %s\n" (resolved_summary resolved);)
      | Error msg ->
          prerr_endline msg;
          exit 1

let () =
  let args =
    match Array.to_list Sys.argv with
    | [] -> []
    | _ :: rest -> rest
  in
  match args with
  | [] | [ "-h" ] | [ "-help" ] | [ "--help" ] ->
      print_help stdout;
      exit 0
  | [ "--help-extra" ] | [ "-X" ] ->
      print_extra_help stdout;
      exit 0
  | [ "-v" ] | [ "--version" ] ->
      print_version stdout;
      exit 0
  | "help" :: rest -> (
      match rest with
      | [] ->
          print_help stdout;
          exit 0
      | [ command ] -> (
          match mode_of_string command with
          | Some mode ->
              print_command_help stdout mode;
              exit 0
          | None -> fail_unknown_command command )
      | _ -> fail_with_help "help accepts at most one command name." )
  | command :: rest -> (
      match mode_of_string command with
      | Some mode -> (
          match (mode, rest) with
          | (Build, []) | (Check, []) | (Run, []) -> execute_mode mode "."
          | (Compile, []) ->
              fail_with_help
                (Printf.sprintf "missing source file or project directory for `%s`." command)
          | _, [ target ] -> execute_mode mode target
          | _ ->
              fail_with_help
                (Printf.sprintf "`%s` expects at most one target argument." command) )
      | None -> (
          match rest with
          | [] when has_supported_extension command -> execute_mode Compile command
          | [] when is_directory command || is_build_toml command || looks_like_path command ->
              execute_mode Build command
          | [] -> fail_unknown_command command
          | _ -> fail_with_help "expected exactly one target argument." ) )
