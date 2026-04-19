type t = {
  file : Source_file.t;
  offset : int;
  line : int;
  column : int;
}

let create ~file ~offset ~line ~column = { file; offset; line; column }

let start_of_file file = { file; offset = 0; line = 1; column = 1 }

let advance location ch =
  if ch = '\n' then
    {
      location with
      offset = location.offset + 1;
      line = location.line + 1;
      column = 1;
    }
  else { location with offset = location.offset + 1; column = location.column + 1 }

let file location = location.file
let offset location = location.offset
let line location = location.line
let column location = location.column

let compare a b =
  match String.compare a.file.absolute_path b.file.absolute_path with
  | 0 -> Int.compare a.offset b.offset
  | c -> c

let to_string location =
  Format.sprintf "%s:%d:%d" location.file.absolute_path location.line
    location.column
