let is_ascii_upper ch = ch >= 'A' && ch <= 'Z'
let is_ascii_lower ch = ch >= 'a' && ch <= 'z'
let is_ascii_letter ch = is_ascii_upper ch || is_ascii_lower ch

let is_decimal_digit ch = ch >= '0' && ch <= '9'
let is_digit = is_decimal_digit

let is_binary_digit = function
  | '0' | '1' -> true
  | _ -> false

let is_octal_digit ch = ch >= '0' && ch <= '7'

let is_hex_digit ch =
  is_decimal_digit ch || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F')

let is_identifier_start ch = is_ascii_letter ch || ch = '_'
let is_identifier_part ch = is_identifier_start ch || is_decimal_digit ch || ch = '$'

let is_line_terminator = function
  | '\n' | '\r' -> true
  | _ -> false

let is_horizontal_space = function
  | ' ' | '\t' -> true
  | _ -> false

let is_whitespace ch = is_horizontal_space ch || is_line_terminator ch

let is_control_char ch =
  let code = Char.code ch in
  code <= 0x1F || code = 0x7F

let is_operator_or_punctuation_start = function
  | '+' | '-' | '*' | '/' | '%' | '&' | '|' | '^' | '~' | '!' | '='
  | '<' | '>' | '.' | ',' | ';' | ':' | '(' | ')' | '{' | '}'
  | '[' | ']' | '@' | '#' | '$' | '?' | '`' -> true
  | _ -> false

let is_radix_prefix_start = function
  | 'b' | 'B' | 'o' | 'O' | 'x' | 'X' -> true
  | _ -> false

let is_string_quote ch = ch = '"'
let is_char_quote ch = ch = '\''

let is_line_comment_start ~current ~next =
  current = '/'
  &&
  match next with
  | Some '/' -> true
  | _ -> false

let is_block_comment_start ~current ~next =
  current = '/'
  &&
  match next with
  | Some '*' -> true
  | _ -> false

let is_comment_start ~current ~next =
  is_line_comment_start ~current ~next || is_block_comment_start ~current ~next
