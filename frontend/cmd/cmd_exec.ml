let print_version () =
  Printf.printf "Cloth Compiler %s\n" Definitions.compiler_version

let dump_tokens = ref false

let write_tokens = ref (None : string option)

let write_only = ref false