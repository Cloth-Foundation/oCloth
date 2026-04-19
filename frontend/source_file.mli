type file_kind =
  | Cloth_object
  | Cloth_library

type error =
  | Invalid_extension
  | File_not_found
  | IOError of string

type t = {
  absolute_path : string;
  file_name : string;
  directory_path : string;
  base_name : string;
  extension : string;
  file_kind : file_kind;
  contents : string;
}

val from_path : string -> (t, error) result
val from_string : path:string -> contents:string -> (t, error) result

val get_line : t -> int -> string option
val length : t -> int
val char_at : t -> int -> char option
