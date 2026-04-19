val is_ascii_upper : char -> bool
val is_ascii_lower : char -> bool
val is_ascii_letter : char -> bool

val is_digit : char -> bool
val is_binary_digit : char -> bool
val is_octal_digit : char -> bool
val is_decimal_digit : char -> bool
val is_hex_digit : char -> bool

val is_identifier_start : char -> bool
val is_identifier_part : char -> bool

val is_whitespace : char -> bool
val is_line_terminator : char -> bool
val is_horizontal_space : char -> bool
val is_control_char : char -> bool

val is_operator_or_punctuation_start : char -> bool

val is_radix_prefix_start : char -> bool
val is_string_quote : char -> bool
val is_char_quote : char -> bool

val is_comment_start : current:char -> next:char option -> bool
val is_block_comment_start : current:char -> next:char option -> bool
val is_line_comment_start : current:char -> next:char option -> bool
