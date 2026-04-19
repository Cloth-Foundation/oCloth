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

(* Spec: Section 3.1.1 and Section 13 define source-file selection/discovery.
   TODO(spec 13): Confirm whether additional source extensions are mandated by the
   active edition/build profile beyond .co and .clib. *)
let file_kind_of_extension = function
  | ".co" -> Ok Cloth_object
  | ".clib" -> Ok Cloth_library
  | _ -> Error Invalid_extension

let normalize_absolute_path path =
  if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path

let build ~path ~contents =
  let absolute_path = normalize_absolute_path path in
  let file_name = Filename.basename absolute_path in
  let extension = Filename.extension file_name in
  match file_kind_of_extension extension with
  | Error _ as error -> error
  | Ok file_kind ->
      let base_name = Filename.remove_extension file_name in
      let directory_path = Filename.dirname absolute_path in
      Ok
        {
          absolute_path;
          file_name;
          directory_path;
          base_name;
          extension;
          file_kind;
          contents;
        }

let from_string ~path ~contents = build ~path ~contents

let read_file path =
  try
    let channel = open_in_bin path in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () ->
        let size = in_channel_length channel in
        really_input_string channel size)
    |> fun contents -> Ok contents
  with
  | Sys_error msg -> Error (IOError msg)

let from_path path =
  let absolute_path = normalize_absolute_path path in
  if not (Sys.file_exists absolute_path) then Error File_not_found
  else
    match read_file absolute_path with
    | Error _ as error -> error
    | Ok contents -> build ~path:absolute_path ~contents

let length source_file = String.length source_file.contents

let char_at source_file index =
  if index < 0 || index >= String.length source_file.contents then None
  else Some source_file.contents.[index]

let get_line source_file line_number =
  if line_number <= 0 then None
  else
    let text = source_file.contents in
    let text_length = String.length text in
    let rec seek_line current_line index line_start =
      if index >= text_length then
        if current_line = line_number then Some (String.sub text line_start (text_length - line_start))
        else None
      else if text.[index] = '\n' then
        if current_line = line_number then Some (String.sub text line_start (index - line_start))
        else seek_line (current_line + 1) (index + 1) (index + 1)
      else seek_line current_line (index + 1) line_start
    in
    seek_line 1 0 0
