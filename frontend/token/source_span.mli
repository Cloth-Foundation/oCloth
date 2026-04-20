type t = {
  start : Source_location.t;
  end_ : Source_location.t;
}

val create : start:Source_location.t -> end_:Source_location.t -> t

val length : t -> int
val contains : t -> Source_location.t -> bool
val merge : t -> t -> t
val compare : t -> t -> int
val pp : Format.formatter -> t -> unit
val to_string : t -> string
val span_to_string : t -> string