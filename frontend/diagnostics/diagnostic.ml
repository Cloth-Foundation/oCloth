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

let make ~severity ~code ~message ~span ~primary_label ?(notes = []) ?(helps = [])
    ?(clause_refs = []) () =
  { severity; code; message; span; primary_label; notes; helps; clause_refs }

let severity diagnostic = diagnostic.severity
let code diagnostic = diagnostic.code
let message diagnostic = diagnostic.message
let span diagnostic = diagnostic.span
let primary_label diagnostic = diagnostic.primary_label
let notes diagnostic = diagnostic.notes
let helps diagnostic = diagnostic.helps
let clause_refs diagnostic = diagnostic.clause_refs

let string_of_severity = function
  | Error -> "error"
  | Warning -> "warning"
  | Note -> "note"

let to_string diagnostic =
  Format.sprintf
    "{severity=%s; code=%s; message=%S; span=%s; primary_label=%S; notes=[%s]; helps=[%s]}"
    (string_of_severity diagnostic.severity)
    diagnostic.code
    diagnostic.message
    (Source_span.to_string diagnostic.span)
    diagnostic.primary_label
    (String.concat "," diagnostic.notes)
    (String.concat "," diagnostic.helps)
