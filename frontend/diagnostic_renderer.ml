let string_of_severity = function
  | Diagnostic.Error -> "error"
  | Diagnostic.Warning -> "warning"
  | Diagnostic.Note -> "note"

let repeat_char count ch =
  if count <= 0 then "" else String.make count ch

let underline_for_span span source_line =
  let start_col = Source_location.column span.Source_span.start in
  let end_col = Source_location.column span.Source_span.end_ in
  let source_len = String.length source_line in
  let start_spaces = max 0 (start_col - 1) in
  let raw_width = end_col - start_col in
  let width = if raw_width <= 0 then 1 else raw_width in
  let max_width = max 1 (source_len - start_spaces) in
  let clamped_width = min width max_width in
  (repeat_char start_spaces ' ') ^ repeat_char clamped_width '^'

let render_source_line span =
  let file = Source_location.file span.Source_span.start in
  let line_no = Source_location.line span.Source_span.start in
  match Source_file.get_line file line_no with
  | Some line_text -> (line_no, line_text)
  | None -> (line_no, "<source unavailable>")

let render diagnostic =
  let span = Diagnostic.span diagnostic in
  let start = span.Source_span.start in
  let file = Source_location.file start in
  let line_no, source_line = render_source_line span in
  let underline = underline_for_span span source_line in
  let buffer = Buffer.create 256 in
  Buffer.add_string buffer
    (Printf.sprintf "%s[%s]: %s\n" (string_of_severity (Diagnostic.severity diagnostic))
       (Diagnostic.code diagnostic) (Diagnostic.message diagnostic));
  Buffer.add_string buffer
    (Printf.sprintf " --> %s:%d:%d\n" file.absolute_path (Source_location.line start)
       (Source_location.column start));
  Buffer.add_string buffer "  |\n";
  Buffer.add_string buffer (Printf.sprintf "%d | %s\n" line_no source_line);
  Buffer.add_string buffer
    (Printf.sprintf "  | %s %s\n" underline (Diagnostic.primary_label diagnostic));
  Buffer.add_string buffer "  |\n";
  List.iter
    (fun note ->
      Buffer.add_string buffer (Printf.sprintf "  = note: %s\n" note))
    (Diagnostic.notes diagnostic);
  List.iter
    (fun help ->
      Buffer.add_string buffer (Printf.sprintf "  = help: %s\n" help))
    (Diagnostic.helps diagnostic);
  Buffer.contents buffer
