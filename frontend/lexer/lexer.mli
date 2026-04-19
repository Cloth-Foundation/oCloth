type t = {
  source : Source_file.t;
  mutable offset : int;
  mutable location : Source_location.t;
  mutable current_char : char option;
  mutable meta_candidate_after_colon_colon : bool;
  mutable diagnostics : Diagnostic.t list;
}

val create : Source_file.t -> t
val current_char : t -> char option
val peek_char : t -> char option
val advance : t -> unit
val is_eof : t -> bool
val diagnostics : t -> Diagnostic.t list
val emit_error :
  t ->
  span:Source_span.t ->
  code:string ->
  message:string ->
  primary_label:string ->
  ?notes:string list ->
  ?helps:string list ->
  clause_refs:string list ->
  unit ->
  unit

val emit_warning :
  t ->
  span:Source_span.t ->
  code:string ->
  message:string ->
  primary_label:string ->
  ?notes:string list ->
  ?helps:string list ->
  clause_refs:string list ->
  unit ->
  unit

val skip_whitespace : t -> unit
val skip_line_comment : t -> unit
val skip_block_comment : t -> unit
val skip_comment : t -> unit
val skip_trivia : t -> unit

val read_identifier_or_keyword : t -> Token.t
val read_integer_or_float : t -> Token.t
val read_number_literal : t -> Token.t
val read_string_literal : t -> Token.t
val read_char_literal : t -> Token.t
val read_operator_or_punctuation : t -> Token.t
val next_token : t -> Token.t
val peek_token : t -> Token.t
val lex_all : t -> Token.t list
