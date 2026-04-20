let usage () =
  prerr_endline "Usage:";
  prerr_endline "  cloth <flags?> <command>";
  prerr_endline "  USE: cloth -h for help"

let help () =
  prerr_endline ("Cloth Compiler " ^ Definitions.compiler_version);
  prerr_endline "";

  prerr_endline "Usage:";
  prerr_endline "  cloth <command> [options] <file>";
  prerr_endline "  cloth <file>                    (defaults to run)";
  prerr_endline "";

  prerr_endline "Commands:";
  prerr_endline "  help, ?                         Show this help message";
  prerr_endline "  version                         Show compiler version";
  prerr_endline "  lexer <flags> <file>            Run lexer on a source file";
  prerr_endline "  parse <flags> <file>            Parse source and report syntax errors";
  prerr_endline "  check <flags> <file>            Run semantic/type checks";
  prerr_endline "  run <flags> <build_file>        Compile and execute";
  prerr_endline "  build <flags> <build_file>      Compile to output artifact";
  prerr_endline "  doc <flags> <build_file>        Generate documentation";
  prerr_endline "";

  prerr_endline "Options:";
  prerr_endline "  -o <path>                       Set output path";
  prerr_endline "  -target <triple>                Select target/backend";
  prerr_endline "  -O0|-O1|-O2|-O3                 Optimization level";
  prerr_endline "  -g                              Emit debug information";
  prerr_endline "  -Werror                         Treat warnings as errors";
  prerr_endline "  -I <dir>                        Add import/include directory";
  prerr_endline "  -color <mode>                   Diagnostic color: always|auto|never";
  prerr_endline "";

  prerr_endline "Debug:";
  prerr_endline "  --dump-tokens <flags>           Dump lexer tokens";
  prerr_endline "  --dump-ast <flags>              Print parsed AST";
  prerr_endline "  --dump-ir <flags>               Print lowered IR";
  prerr_endline "  --dump-symbols <flags>          Print symbol table/resolution data";
  prerr_endline "";

  prerr_endline "Examples:";
  prerr_endline "  cloth main.co";
  prerr_endline "  cloth lexer main.co";
  prerr_endline "  cloth parse src/main.co";
  prerr_endline "  cloth build \"C:\\path\\to\\build.toml\" -o out.exe";
  prerr_endline "  cloth doc \"C:\\path\\to\\build.toml\"";
  prerr_endline "";

  prerr_endline "For more help:";
  prerr_endline "  cloth <command> -help";
