type t = {
  start : Source_location.t;
  end_ : Source_location.t;
}

(* Spec: Section 2.2.3 defines token metadata as start/end offsets and line/column.
   TODO(spec 2.2.3): confirm whether span endpoints are universally half-open in all
   frontend stages or whether stage-specific closed ranges are permitted. *)
let create ~start ~end_ =
  if
    String.compare
      (Source_location.file start).absolute_path
      (Source_location.file end_).absolute_path
    <> 0
  then
    invalid_arg "Source_span.create: locations must belong to the same file"
  else if Source_location.compare start end_ <= 0 then { start; end_ }
  else { start = end_; end_ = start }

let length span =
  Source_location.offset span.end_ - Source_location.offset span.start

let contains span location =
  String.compare
    (Source_location.file span.start).absolute_path
    (Source_location.file location).absolute_path
  = 0
  && Source_location.compare span.start location <= 0
  && Source_location.compare location span.end_ <= 0

let merge a b =
  if
    String.compare
      (Source_location.file a.start).absolute_path
      (Source_location.file b.start).absolute_path
    <> 0
  then
    invalid_arg "Source_span.merge: spans must belong to the same file"
  else
    let start =
      if Source_location.compare a.start b.start <= 0 then a.start else b.start
    in
    let end_ =
      if Source_location.compare a.end_ b.end_ >= 0 then a.end_ else b.end_
    in
    { start; end_ }

let compare a b =
  match
    String.compare
      (Source_location.file a.start).absolute_path
      (Source_location.file b.start).absolute_path
  with
  | 0 -> (
      match Source_location.compare a.start b.start with
      | 0 -> Source_location.compare a.end_ b.end_
      | c -> c )
  | c -> c

let pp ppf span =
  Format.fprintf ppf "%s:%d:%d-%d:%d"
    (Source_location.file span.start).absolute_path
    (Source_location.line span.start)
    (Source_location.column span.start)
    (Source_location.line span.end_)
    (Source_location.column span.end_)

let to_string span =
  Format.asprintf "%a" pp span
