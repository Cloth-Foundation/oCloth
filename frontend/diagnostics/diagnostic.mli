type severity =
  | Error
  | Warning
  | Note

type t = {
  severity : severity;
  code : string;
  message : string;
  span : Source_span.t;
  primary_label : string;
  notes : string list;
  helps : string list;
  clause_refs : string list;
}

val make :
  severity:severity ->
  code:string ->
  message:string ->
  span:Source_span.t ->
  primary_label:string ->
  ?notes:string list ->
  ?helps:string list ->
  ?clause_refs:string list ->
  unit ->
  t

val severity : t -> severity
val code : t -> string
val message : t -> string
val span : t -> Source_span.t
val primary_label : t -> string
val notes : t -> string list
val helps : t -> string list
val clause_refs : t -> string list
val to_string : t -> string
