type t = {
  file : Source_file.t;
  offset : int;
  line : int;
  column : int;
}

val create : file:Source_file.t -> offset:int -> line:int -> column:int -> t
val start_of_file : Source_file.t -> t
val advance : t -> char -> t
val file : t -> Source_file.t
val offset : t -> int
val line : t -> int
val column : t -> int
val compare : t -> t -> int
val to_string : t -> string
