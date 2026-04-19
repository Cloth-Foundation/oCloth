type t = {
  source : Source_file.t;
  mutable offset : int;
  mutable location : Source_location.t;
  mutable current_char : char option;
}

val create : Source_file.t -> t
val current_char : t -> char option
val peek_char : t -> char option
val advance : t -> unit
val is_eof : t -> bool

val skip_whitespace : t -> unit
val skip_comment : t -> unit

val next_token : t -> Token.t
val peek_token : t -> Token.t
