// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Internal syntax-highlighting editor layer inspired by
/// `cosmic-text/src/edit/syntect.rs`.
pub struct SyntaxTheme {
  name : String
  background : @cosmic.Color
  foreground : @cosmic.Color
  cursor_opt : @cosmic.Color?
  selection_opt : @cosmic.Color?
  keyword : @cosmic.Color
  type_name : @cosmic.Color
  string_lit : @cosmic.Color
  comment : @cosmic.Color
  number : @cosmic.Color
}

///|
pub fn SyntaxTheme::name(self : SyntaxTheme) -> String {
  self.name
}

///|
pub fn SyntaxTheme::background(self : SyntaxTheme) -> @cosmic.Color {
  self.background
}

///|
pub fn SyntaxTheme::foreground(self : SyntaxTheme) -> @cosmic.Color {
  self.foreground
}

///|
pub fn SyntaxTheme::cursor(self : SyntaxTheme) -> @cosmic.Color {
  match self.cursor_opt {
    Some(color) => color
    None => self.foreground
  }
}

///|
pub fn SyntaxTheme::selection(self : SyntaxTheme) -> @cosmic.Color {
  match self.selection_opt {
    Some(color) => color
    None =>
      @cosmic.Color::rgba(
        self.foreground.r(),
        self.foreground.g(),
        self.foreground.b(),
        0x33,
      )
  }
}

///|
fn theme_base16_eighties_dark() -> SyntaxTheme {
  SyntaxTheme::{
    name: "base16-eighties.dark",
    background: @cosmic.Color::rgb(0x2D, 0x2D, 0x2D),
    foreground: @cosmic.Color::rgb(0xD3, 0xD0, 0xC8),
    cursor_opt: Some(@cosmic.Color::rgb(0xD3, 0xD0, 0xC8)),
    selection_opt: Some(@cosmic.Color::rgba(0x51, 0x51, 0x51, 0xCC)),
    keyword: @cosmic.Color::rgb(0xCC, 0x99, 0xCC),
    type_name: @cosmic.Color::rgb(0xF2, 0x77, 0x7A),
    string_lit: @cosmic.Color::rgb(0x99, 0xCC, 0x99),
    comment: @cosmic.Color::rgb(0x74, 0x74, 0x74),
    number: @cosmic.Color::rgb(0xF9, 0x91, 0x57),
  }
}

///|
fn theme_base16_ocean_light() -> SyntaxTheme {
  SyntaxTheme::{
    name: "base16-ocean.light",
    background: @cosmic.Color::rgb(0xEF, 0xF1, 0xF5),
    foreground: @cosmic.Color::rgb(0x4F, 0x5B, 0x66),
    cursor_opt: Some(@cosmic.Color::rgb(0x4F, 0x5B, 0x66)),
    selection_opt: Some(@cosmic.Color::rgba(0xBF, 0xC7, 0xD5, 0xD8)),
    keyword: @cosmic.Color::rgb(0xA7, 0xB8, 0xC8),
    type_name: @cosmic.Color::rgb(0xBF, 0x61, 0x6A),
    string_lit: @cosmic.Color::rgb(0xA3, 0xBE, 0x8C),
    comment: @cosmic.Color::rgb(0xA7, 0xAD, 0xBA),
    number: @cosmic.Color::rgb(0xD0, 0x87, 0x70),
  }
}

///|
pub struct SyntaxSystem {

  fn new() -> SyntaxSystem
}

///|
pub fn SyntaxSystem::new() -> SyntaxSystem {
  SyntaxSystem::{  }
}

///|
fn ascii_lower_char(ch : Char) -> Char {
  let c = ch.to_int()
  if c >= 65 && c <= 90 {
    (c + 32).unsafe_to_char()
  } else {
    ch
  }
}

///|
fn ascii_lower(s : String) -> String {
  let sb = StringBuilder::new(size_hint=s.length())
  for ch in s {
    sb.write_char(ascii_lower_char(ch))
  }
  sb.to_string()
}

///|
pub fn SyntaxSystem::theme(
  _self : SyntaxSystem,
  theme_name : String,
) -> SyntaxTheme? {
  let name = ascii_lower(theme_name)
  if name == "base16-eighties.dark" ||
    name == "base16-ocean.dark" ||
    name == "base16-mocha.dark" ||
    name == "solarized (dark)" {
    Some(theme_base16_eighties_dark())
  } else if name == "base16-ocean.light" ||
    name == "inspiredgithub" ||
    name == "solarized (light)" {
    Some(theme_base16_ocean_light())
  } else {
    None
  }
}

///|
fn normalize_extension(extension : String) -> String {
  let lower = ascii_lower(extension)
  if lower.length() > 0 && lower.code_unit_at(0) == 46 {
    let sb = StringBuilder::new(size_hint=lower.length() - 1)
    sb.write_view(lower[:].view(start_offset=1, end_offset=lower.length()))
    sb.to_string()
  } else {
    lower
  }
}

///|
pub fn SyntaxSystem::syntax_for_extension(
  _self : SyntaxSystem,
  extension : String,
) -> String? {
  let ext = normalize_extension(extension)
  if ext == "rs" || ext == "rlib" {
    Some("rust")
  } else if ext == "py" || ext == "pyi" || ext == "pyw" {
    Some("python")
  } else if ext == "json" {
    Some("json")
  } else if ext == "jsonc" {
    Some("jsonc")
  } else if ext == "json5" {
    Some("json5")
  } else if ext == "toml" {
    Some("toml")
  } else if ext == "yaml" || ext == "yml" {
    Some("yaml")
  } else if ext == "html" || ext == "htm" || ext == "xml" {
    Some("markup")
  } else if ext == "md" ||
    ext == "markdown" ||
    ext == "mdown" ||
    ext == "mkd" ||
    ext == "mkdn" ||
    ext == "mdx" {
    Some("markdown")
  } else if ext == "sql" {
    Some("sql")
  } else if ext == "sh" || ext == "bash" || ext == "zsh" {
    Some("shell")
  } else if ext == "rb" {
    Some("ruby")
  } else if ext == "lua" {
    Some("lua")
  } else if ext == "c" ||
    ext == "h" ||
    ext == "cc" ||
    ext == "hh" ||
    ext == "cpp" ||
    ext == "hpp" ||
    ext == "cxx" ||
    ext == "hxx" ||
    ext == "js" ||
    ext == "ts" ||
    ext == "tsx" ||
    ext == "jsx" ||
    ext == "mjs" ||
    ext == "cjs" ||
    ext == "java" ||
    ext == "go" ||
    ext == "kt" ||
    ext == "kts" ||
    ext == "swift" ||
    ext == "cs" ||
    ext == "php" ||
    ext == "css" ||
    ext == "scss" ||
    ext == "sass" ||
    ext == "less" {
    Some("clike")
  } else {
    None
  }
}

///|
pub fn SyntaxSystem::plain_text_syntax(_self : SyntaxSystem) -> String {
  "plain"
}

///|
pub(all) enum TokenClass {
  Keyword
  TypeName
  StringLit
  Comment
  Number
}

///|
pub struct LineState {
  block_comment_depth : Int
  markup_comment_open : Bool
  markup_tag_open : Bool
  ruby_block_comment_open : Bool
  lua_long_eq_count_opt : Int?
  lua_long_is_comment : Bool
  string_delim_opt : Char?
  string_is_triple : Bool
  raw_hash_count_opt : Int?
  markdown_fence_char_opt : Char?
  clike_preproc_continuation : Bool
}

///|
pub fn LineState::new() -> LineState {
  LineState::{
    block_comment_depth: 0,
    markup_comment_open: false,
    markup_tag_open: false,
    ruby_block_comment_open: false,
    lua_long_eq_count_opt: None,
    lua_long_is_comment: false,
    string_delim_opt: None,
    string_is_triple: false,
    raw_hash_count_opt: None,
    markdown_fence_char_opt: None,
    clike_preproc_continuation: false,
  }
}

///|
pub impl Eq for LineState with equal(self, other) {
  self.block_comment_depth == other.block_comment_depth &&
  self.markup_comment_open == other.markup_comment_open &&
  self.markup_tag_open == other.markup_tag_open &&
  self.ruby_block_comment_open == other.ruby_block_comment_open &&
  self.lua_long_eq_count_opt == other.lua_long_eq_count_opt &&
  self.lua_long_is_comment == other.lua_long_is_comment &&
  self.string_delim_opt == other.string_delim_opt &&
  self.string_is_triple == other.string_is_triple &&
  self.raw_hash_count_opt == other.raw_hash_count_opt &&
  self.markdown_fence_char_opt == other.markdown_fence_char_opt &&
  self.clike_preproc_continuation == other.clike_preproc_continuation
}

///|
pub struct TokenSpan {
  start : Int
  end : Int
  class : TokenClass
}

///|
pub struct CachedLine {
  text : String
  state_in : LineState
  state_out : LineState
  spans : Array[TokenSpan]
}

///|
pub struct SyntaxEditor {
  editor : @cosmic.Editor
  syntax_system : SyntaxSystem
  syntax_name : String
  theme : SyntaxTheme
  cache : Array[CachedLine]
}

///|
fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=(end - start) * 2)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
fn is_ascii_digit(ch : Char) -> Bool {
  let c = ch.to_int()
  c >= 48 && c <= 57
}

///|
fn is_ascii_alpha(ch : Char) -> Bool {
  let c = ch.to_int()
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
}

///|
fn is_identifier_start(ch : Char) -> Bool {
  is_ascii_alpha(ch) || ch == '_'
}

///|
fn is_identifier_part(ch : Char) -> Bool {
  is_identifier_start(ch) || is_ascii_digit(ch)
}

///|
fn code_unit_offsets(_text : String, chars : Array[Char]) -> Array[Int] {
  let offsets : Array[Int] = []
  let mut pos = 0
  for ch in chars {
    offsets.push(pos)
    pos = pos + ch.utf16_len()
  }
  offsets
}

///|
fn offset_at(text : String, offsets : Array[Int], char_i : Int) -> Int {
  if char_i < 0 {
    0
  } else if char_i >= offsets.length() {
    text.length()
  } else {
    offsets[char_i]
  }
}

///|
fn push_token(
  out : Array[TokenSpan],
  start : Int,
  end : Int,
  class : TokenClass,
) -> Unit {
  if end > start {
    out.push(TokenSpan::{ start, end, class })
  }
}

///|
fn is_rust_keyword(word : String) -> Bool {
  word == "as" ||
  word == "break" ||
  word == "const" ||
  word == "continue" ||
  word == "crate" ||
  word == "else" ||
  word == "enum" ||
  word == "extern" ||
  word == "false" ||
  word == "fn" ||
  word == "for" ||
  word == "if" ||
  word == "impl" ||
  word == "in" ||
  word == "let" ||
  word == "loop" ||
  word == "match" ||
  word == "mod" ||
  word == "move" ||
  word == "mut" ||
  word == "pub" ||
  word == "ref" ||
  word == "return" ||
  word == "self" ||
  word == "Self" ||
  word == "static" ||
  word == "struct" ||
  word == "super" ||
  word == "trait" ||
  word == "true" ||
  word == "type" ||
  word == "unsafe" ||
  word == "use" ||
  word == "where" ||
  word == "while" ||
  word == "async" ||
  word == "await" ||
  word == "dyn"
}

///|
fn is_rust_type(word : String) -> Bool {
  word == "String" ||
  word == "str" ||
  word == "Vec" ||
  word == "Option" ||
  word == "Result" ||
  word == "u8" ||
  word == "u16" ||
  word == "u32" ||
  word == "u64" ||
  word == "u128" ||
  word == "usize" ||
  word == "i8" ||
  word == "i16" ||
  word == "i32" ||
  word == "i64" ||
  word == "i128" ||
  word == "isize" ||
  word == "bool" ||
  word == "char" ||
  word == "f32" ||
  word == "f64"
}

///|
fn is_clike_keyword(word : String) -> Bool {
  word == "if" ||
  word == "else" ||
  word == "switch" ||
  word == "case" ||
  word == "default" ||
  word == "for" ||
  word == "while" ||
  word == "do" ||
  word == "break" ||
  word == "continue" ||
  word == "return" ||
  word == "class" ||
  word == "struct" ||
  word == "enum" ||
  word == "namespace" ||
  word == "using" ||
  word == "public" ||
  word == "private" ||
  word == "protected" ||
  word == "static" ||
  word == "const" ||
  word == "final" ||
  word == "new" ||
  word == "delete" ||
  word == "try" ||
  word == "catch" ||
  word == "throw" ||
  word == "import" ||
  word == "export" ||
  word == "function" ||
  word == "var" ||
  word == "let"
}

///|
fn is_clike_type(word : String) -> Bool {
  word == "void" ||
  word == "char" ||
  word == "short" ||
  word == "int" ||
  word == "long" ||
  word == "float" ||
  word == "double" ||
  word == "bool" ||
  word == "size_t" ||
  word == "string" ||
  word == "String" ||
  word == "Object" ||
  word == "Array" ||
  word == "Map"
}

///|
fn is_python_keyword(word : String) -> Bool {
  word == "and" ||
  word == "as" ||
  word == "assert" ||
  word == "break" ||
  word == "class" ||
  word == "continue" ||
  word == "def" ||
  word == "del" ||
  word == "elif" ||
  word == "else" ||
  word == "except" ||
  word == "False" ||
  word == "finally" ||
  word == "for" ||
  word == "from" ||
  word == "global" ||
  word == "if" ||
  word == "import" ||
  word == "in" ||
  word == "is" ||
  word == "lambda" ||
  word == "None" ||
  word == "nonlocal" ||
  word == "not" ||
  word == "or" ||
  word == "pass" ||
  word == "raise" ||
  word == "return" ||
  word == "True" ||
  word == "try" ||
  word == "while" ||
  word == "with" ||
  word == "yield"
}

///|
fn is_shell_keyword(word : String) -> Bool {
  word == "if" ||
  word == "then" ||
  word == "else" ||
  word == "elif" ||
  word == "fi" ||
  word == "for" ||
  word == "while" ||
  word == "until" ||
  word == "do" ||
  word == "done" ||
  word == "case" ||
  word == "esac" ||
  word == "in" ||
  word == "function" ||
  word == "select"
}

///|
fn is_ruby_keyword(word : String) -> Bool {
  word == "BEGIN" ||
  word == "END" ||
  word == "alias" ||
  word == "and" ||
  word == "begin" ||
  word == "break" ||
  word == "case" ||
  word == "class" ||
  word == "def" ||
  word == "defined?" ||
  word == "do" ||
  word == "else" ||
  word == "elsif" ||
  word == "end" ||
  word == "ensure" ||
  word == "false" ||
  word == "for" ||
  word == "if" ||
  word == "in" ||
  word == "module" ||
  word == "next" ||
  word == "nil" ||
  word == "not" ||
  word == "or" ||
  word == "redo" ||
  word == "rescue" ||
  word == "retry" ||
  word == "return" ||
  word == "self" ||
  word == "super" ||
  word == "then" ||
  word == "true" ||
  word == "undef" ||
  word == "unless" ||
  word == "until" ||
  word == "when" ||
  word == "while" ||
  word == "yield"
}

///|
fn is_lua_keyword(word : String) -> Bool {
  word == "and" ||
  word == "break" ||
  word == "do" ||
  word == "else" ||
  word == "elseif" ||
  word == "end" ||
  word == "false" ||
  word == "for" ||
  word == "function" ||
  word == "goto" ||
  word == "if" ||
  word == "in" ||
  word == "local" ||
  word == "nil" ||
  word == "not" ||
  word == "or" ||
  word == "repeat" ||
  word == "return" ||
  word == "then" ||
  word == "true" ||
  word == "until" ||
  word == "while"
}

///|
fn is_sql_keyword(word : String) -> Bool {
  let lower = ascii_lower(word)
  lower == "select" ||
  lower == "from" ||
  lower == "where" ||
  lower == "group" ||
  lower == "by" ||
  lower == "order" ||
  lower == "having" ||
  lower == "limit" ||
  lower == "offset" ||
  lower == "join" ||
  lower == "inner" ||
  lower == "left" ||
  lower == "right" ||
  lower == "full" ||
  lower == "cross" ||
  lower == "on" ||
  lower == "as" ||
  lower == "insert" ||
  lower == "into" ||
  lower == "values" ||
  lower == "update" ||
  lower == "set" ||
  lower == "delete" ||
  lower == "create" ||
  lower == "table" ||
  lower == "alter" ||
  lower == "drop" ||
  lower == "distinct" ||
  lower == "union" ||
  lower == "all" ||
  lower == "and" ||
  lower == "or" ||
  lower == "not" ||
  lower == "null" ||
  lower == "is" ||
  lower == "between" ||
  lower == "like" ||
  lower == "exists"
}

///|
fn is_sql_type(word : String) -> Bool {
  let lower = ascii_lower(word)
  lower == "int" ||
  lower == "integer" ||
  lower == "bigint" ||
  lower == "smallint" ||
  lower == "text" ||
  lower == "varchar" ||
  lower == "char" ||
  lower == "boolean" ||
  lower == "float" ||
  lower == "double" ||
  lower == "decimal" ||
  lower == "numeric" ||
  lower == "date" ||
  lower == "time" ||
  lower == "timestamp"
}

///|
fn is_yaml_toml_keyword(word : String) -> Bool {
  let lower = ascii_lower(word)
  lower == "true" ||
  lower == "false" ||
  lower == "null" ||
  lower == "yes" ||
  lower == "no" ||
  lower == "on" ||
  lower == "off"
}

///|
fn classify_identifier(word : String, syntax_name : String) -> TokenClass? {
  if syntax_name == "rust" {
    if is_rust_keyword(word) {
      Some(Keyword)
    } else if is_rust_type(word) {
      Some(TypeName)
    } else {
      None
    }
  } else if syntax_name == "clike" {
    if is_clike_keyword(word) {
      Some(Keyword)
    } else if is_clike_type(word) {
      Some(TypeName)
    } else {
      None
    }
  } else if syntax_name == "python" {
    if is_python_keyword(word) {
      Some(Keyword)
    } else {
      None
    }
  } else if syntax_name == "shell" {
    if is_shell_keyword(word) {
      Some(Keyword)
    } else {
      None
    }
  } else if syntax_name == "ruby" {
    if is_ruby_keyword(word) {
      Some(Keyword)
    } else {
      None
    }
  } else if syntax_name == "lua" {
    if is_lua_keyword(word) {
      Some(Keyword)
    } else {
      None
    }
  } else if syntax_name == "sql" {
    if is_sql_keyword(word) {
      Some(Keyword)
    } else if is_sql_type(word) {
      Some(TypeName)
    } else {
      None
    }
  } else if syntax_name == "yaml" || syntax_name == "toml" {
    if is_yaml_toml_keyword(word) {
      Some(Keyword)
    } else {
      None
    }
  } else if syntax_name == "json" ||
    syntax_name == "jsonc" ||
    syntax_name == "json5" {
    if word == "true" || word == "false" || word == "null" {
      Some(Keyword)
    } else {
      None
    }
  } else {
    None
  }
}

///|
fn has_line_comment_prefix(
  syntax_name : String,
  chars : Array[Char],
  i : Int,
) -> Bool {
  if syntax_name == "python" ||
    syntax_name == "shell" ||
    syntax_name == "ruby" ||
    syntax_name == "yaml" ||
    syntax_name == "toml" {
    i < chars.length() && chars[i] == '#'
  } else if syntax_name == "lua" || syntax_name == "sql" {
    i + 1 < chars.length() && chars[i] == '-' && chars[i + 1] == '-'
  } else if syntax_name == "jsonc" || syntax_name == "json5" {
    i + 1 < chars.length() && chars[i] == '/' && chars[i + 1] == '/'
  } else if syntax_name == "rust" || syntax_name == "clike" {
    i + 1 < chars.length() && chars[i] == '/' && chars[i + 1] == '/'
  } else {
    false
  }
}

///|
fn supports_block_comment(syntax_name : String) -> Bool {
  syntax_name == "rust" ||
  syntax_name == "clike" ||
  syntax_name == "sql" ||
  syntax_name == "jsonc" ||
  syntax_name == "json5"
}

///|
fn supports_nested_block_comment(syntax_name : String) -> Bool {
  syntax_name == "rust"
}

///|
fn is_python_string_prefix_char(ch : Char) -> Bool {
  ch == 'r' ||
  ch == 'R' ||
  ch == 'b' ||
  ch == 'B' ||
  ch == 'f' ||
  ch == 'F' ||
  ch == 'u' ||
  ch == 'U'
}

///|
fn lua_long_bracket_open_count(chars : Array[Char], start : Int) -> Int? {
  let n = chars.length()
  if start >= n || chars[start] != '[' {
    return None
  }
  let mut i = start + 1
  while i < n && chars[i] == '=' {
    i = i + 1
  }
  if i < n && chars[i] == '[' {
    Some(i - (start + 1))
  } else {
    None
  }
}

///|
fn lua_long_bracket_close(
  chars : Array[Char],
  start : Int,
  eq_count : Int,
) -> Bool {
  let n = chars.length()
  if start >= n || chars[start] != ']' {
    return false
  }
  let mut i = start + 1
  let mut j = 0
  while j < eq_count {
    if i >= n || chars[i] != '=' {
      return false
    }
    i = i + 1
    j = j + 1
  }
  i < n && chars[i] == ']'
}

///|
fn rust_char_literal_end(chars : Array[Char], start : Int) -> Int? {
  let n = chars.length()
  if start + 2 >= n || chars[start] != '\'' {
    return None
  }
  let mut j = start + 1
  if chars[j] == '\\' {
    j = j + 1
    if j >= n {
      return None
    }
    if chars[j] == 'u' && j + 1 < n && chars[j + 1] == '{' {
      j = j + 2
      while j < n && chars[j] != '}' {
        j = j + 1
      }
      if j >= n {
        return None
      }
      j = j + 1
    } else if chars[j] == 'x' && j + 2 < n {
      j = j + 3
    } else {
      j = j + 1
    }
  } else {
    j = j + 1
  }
  if j < n && chars[j] == '\'' {
    Some(j + 1)
  } else {
    None
  }
}

///|
fn markdown_first_non_whitespace(chars : Array[Char]) -> Int {
  let n = chars.length()
  let mut i = 0
  while i < n && chars[i].is_whitespace() {
    i = i + 1
  }
  i
}

///|
fn line_starts_with(chars : Array[Char], start : Int, token : String) -> Bool {
  let token_chars = token.to_array()
  if start < 0 || start + token_chars.length() > chars.length() {
    return false
  }
  let mut i = 0
  while i < token_chars.length() {
    if chars[start + i] != token_chars[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn markdown_fence_char(chars : Array[Char], start : Int) -> Char? {
  if start + 2 >= chars.length() {
    return None
  }
  let c = chars[start]
  if (c == '`' || c == '~') && chars[start + 1] == c && chars[start + 2] == c {
    Some(c)
  } else {
    None
  }
}

///|
fn line_ends_with_backslash(chars : Array[Char]) -> Bool {
  let mut i = chars.length()
  while i > 0 {
    i = i - 1
    if chars[i].is_whitespace() {
      continue
    }
    return chars[i] == '\\'
  }
  false
}

///|
fn tokenize_line(
  text : String,
  syntax_name : String,
  state_in : LineState,
) -> (Array[TokenSpan], LineState) {
  let chars = text.to_array()
  let offsets = code_unit_offsets(text, chars)
  let spans : Array[TokenSpan] = []
  let mut state = state_in
  let mut i = 0
  let n = chars.length()
  let line_first = markdown_first_non_whitespace(chars)

  if syntax_name == "clike" {
    let preproc_line = state.clike_preproc_continuation ||
      (line_first < n && chars[line_first] == '#')
    if preproc_line {
      let continuation = line_ends_with_backslash(chars)
      return (
        if text.length() == 0 {
          []
        } else {
          [
            TokenSpan::{
              start: offset_at(text, offsets, line_first),
              end: text.length(),
              class: Keyword,
            },
          ]
        },
        LineState::{ ..state, clike_preproc_continuation: continuation },
      )
    }
    if state.clike_preproc_continuation {
      state = LineState::{ ..state, clike_preproc_continuation: false }
    }
  } else if state.clike_preproc_continuation {
    state = LineState::{ ..state, clike_preproc_continuation: false }
  }

  if syntax_name == "ruby" {
    if state.ruby_block_comment_open {
      let closes = line_starts_with(chars, line_first, "=end")
      return (
        if text.length() == 0 {
          []
        } else {
          [
            TokenSpan::{
              start: offset_at(text, offsets, line_first),
              end: text.length(),
              class: Comment,
            },
          ]
        },
        LineState::{ ..state, ruby_block_comment_open: !closes },
      )
    }
    if line_starts_with(chars, line_first, "=begin") {
      return (
        if text.length() == 0 {
          []
        } else {
          [
            TokenSpan::{
              start: offset_at(text, offsets, line_first),
              end: text.length(),
              class: Comment,
            },
          ]
        },
        LineState::{ ..state, ruby_block_comment_open: true },
      )
    }
  }

  if syntax_name == "markdown" {
    let first = markdown_first_non_whitespace(chars)
    match state.markdown_fence_char_opt {
      Some(fence) =>
        match markdown_fence_char(chars, first) {
          Some(c) if c == fence =>
            return (
              [
                TokenSpan::{
                  start: offset_at(text, offsets, first),
                  end: text.length(),
                  class: Keyword,
                },
              ],
              LineState::{ ..state, markdown_fence_char_opt: None },
            )
          _ =>
            return (
              if text.length() == 0 {
                []
              } else {
                [TokenSpan::{ start: 0, end: text.length(), class: StringLit }]
              },
              state,
            )
        }
      None => {
        let spans_md : Array[TokenSpan] = []
        let mut next_state = state
        match markdown_fence_char(chars, first) {
          Some(c) => {
            spans_md.push(TokenSpan::{
              start: offset_at(text, offsets, first),
              end: text.length(),
              class: Keyword,
            })
            next_state = LineState::{
              ..next_state,
              markdown_fence_char_opt: Some(c),
            }
            return (spans_md, next_state)
          }
          None => ()
        }
        if first < n && chars[first] == '#' {
          spans_md.push(TokenSpan::{
            start: offset_at(text, offsets, first),
            end: text.length(),
            class: Keyword,
          })
        }
        let mut p = 0
        while p < n {
          if chars[p] == '`' {
            let mut run = 1
            while p + run < n && chars[p + run] == '`' {
              run = run + 1
            }
            let start_i = p
            p = p + run
            let mut closed = false
            while p < n {
              if chars[p] == '`' {
                let mut run2 = 1
                while p + run2 < n && chars[p + run2] == '`' {
                  run2 = run2 + 1
                }
                if run2 == run {
                  p = p + run2
                  closed = true
                  break
                }
                p = p + run2
              } else {
                p = p + 1
              }
            }
            let end_i = if closed { p } else { n }
            spans_md.push(TokenSpan::{
              start: offset_at(text, offsets, start_i),
              end: offset_at(text, offsets, end_i),
              class: StringLit,
            })
            continue
          }
          p = p + 1
        }
        return (spans_md, next_state)
      }
    }
  }

  while i < n {
    match state.raw_hash_count_opt {
      None => ()
      Some(hashes) => {
        let start_i = i
        let mut closed = false
        while i < n {
          if chars[i] == '"' {
            let mut ok = true
            let mut j = 0
            while j < hashes {
              if i + 1 + j >= n || chars[i + 1 + j] != '#' {
                ok = false
                break
              }
              j = j + 1
            }
            if ok {
              i = i + 1 + hashes
              closed = true
              break
            }
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          StringLit,
        )
        if closed {
          state = LineState::{ ..state, raw_hash_count_opt: None }
        }
        continue
      }
    }

    match state.lua_long_eq_count_opt {
      None => ()
      Some(eq_count) => {
        let start_i = i
        let mut closed = false
        while i < n {
          if lua_long_bracket_close(chars, i, eq_count) {
            i = i + eq_count + 2
            closed = true
            break
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          if state.lua_long_is_comment {
            Comment
          } else {
            StringLit
          },
        )
        if closed {
          state = LineState::{
            ..state,
            lua_long_eq_count_opt: None,
            lua_long_is_comment: false,
          }
        }
        continue
      }
    }

    if syntax_name == "markup" && state.markup_comment_open {
      let start_i = i
      let mut closed = false
      while i + 2 < n {
        if chars[i] == '-' && chars[i + 1] == '-' && chars[i + 2] == '>' {
          i = i + 3
          closed = true
          break
        }
        i = i + 1
      }
      if !closed {
        i = n
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        Comment,
      )
      state = LineState::{ ..state, markup_comment_open: !closed }
      continue
    }

    if syntax_name == "markup" && state.markup_tag_open {
      let start_i = i
      let mut closed = false
      while i < n {
        if chars[i] == '>' {
          i = i + 1
          closed = true
          break
        }
        i = i + 1
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        Keyword,
      )
      state = LineState::{ ..state, markup_tag_open: !closed }
      continue
    }

    if state.block_comment_depth > 0 {
      let start_i = i
      let nested = supports_nested_block_comment(syntax_name)
      let mut depth = state.block_comment_depth
      let mut end_i = n
      let mut close_found = false
      while i + 1 < n {
        if nested && chars[i] == '/' && chars[i + 1] == '*' {
          depth = depth + 1
          i = i + 2
          continue
        }
        if chars[i] == '*' && chars[i + 1] == '/' {
          depth = depth - 1
          i = i + 2
          if depth == 0 {
            end_i = i
            close_found = true
            break
          }
          continue
        }
        i = i + 1
      }
      if !close_found {
        i = n
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, end_i),
        Comment,
      )
      if close_found {
        state = LineState::{ ..state, block_comment_depth: 0 }
      } else {
        state = LineState::{ ..state, block_comment_depth: depth }
      }
      continue
    }

    match state.string_delim_opt {
      Some(delim) => {
        let triple = state.string_is_triple
        let start_i = i
        let mut escaped = false
        let mut closed = false
        while i < n {
          let ch = chars[i]
          if triple {
            if i + 2 < n &&
              chars[i] == delim &&
              chars[i + 1] == delim &&
              chars[i + 2] == delim {
              i = i + 3
              closed = true
              break
            }
            i = i + 1
            continue
          }
          if escaped {
            escaped = false
            i = i + 1
            continue
          }
          if ch == '\\' {
            escaped = true
            i = i + 1
            continue
          }
          if ch == delim {
            i = i + 1
            closed = true
            break
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          StringLit,
        )
        if closed {
          state = LineState::{
            ..state,
            string_delim_opt: None,
            string_is_triple: false,
          }
        } else if !triple {
          state = LineState::{
            ..state,
            string_delim_opt: None,
            string_is_triple: false,
          }
        }
        continue
      }
      None => ()
    }

    if syntax_name == "markup" &&
      i + 3 < n &&
      chars[i] == '<' &&
      chars[i + 1] == '!' &&
      chars[i + 2] == '-' &&
      chars[i + 3] == '-' {
      let start_i = i
      i = i + 4
      let mut closed = false
      while i + 2 < n {
        if chars[i] == '-' && chars[i + 1] == '-' && chars[i + 2] == '>' {
          i = i + 3
          closed = true
          break
        }
        i = i + 1
      }
      if !closed {
        i = n
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        Comment,
      )
      if !closed {
        state = LineState::{ ..state, markup_comment_open: true }
      }
      continue
    }

    if syntax_name == "markup" &&
      chars[i] == '<' &&
      i + 1 < n &&
      (
        chars[i + 1] == '/' ||
        chars[i + 1] == '!' ||
        chars[i + 1] == '?' ||
        is_identifier_start(chars[i + 1])
      ) {
      let start_i = i
      i = i + 1
      let mut closed = false
      while i < n {
        if chars[i] == '>' {
          i = i + 1
          closed = true
          break
        }
        i = i + 1
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        Keyword,
      )
      if !closed {
        state = LineState::{ ..state, markup_tag_open: true }
      }
      continue
    }

    if syntax_name == "lua" &&
      i + 2 < n &&
      chars[i] == '-' &&
      chars[i + 1] == '-' &&
      chars[i + 2] == '[' {
      match lua_long_bracket_open_count(chars, i + 2) {
        None => ()
        Some(eq_count) => {
          let start_i = i
          i = i + 4 + eq_count
          let mut closed = false
          while i < n {
            if lua_long_bracket_close(chars, i, eq_count) {
              i = i + eq_count + 2
              closed = true
              break
            }
            i = i + 1
          }
          push_token(
            spans,
            offset_at(text, offsets, start_i),
            offset_at(text, offsets, i),
            Comment,
          )
          if !closed {
            state = LineState::{
              ..state,
              lua_long_eq_count_opt: Some(eq_count),
              lua_long_is_comment: true,
            }
          }
          continue
        }
      }
    }

    if syntax_name == "lua" && chars[i] == '[' {
      match lua_long_bracket_open_count(chars, i) {
        None => ()
        Some(eq_count) => {
          let start_i = i
          i = i + 2 + eq_count
          let mut closed = false
          while i < n {
            if lua_long_bracket_close(chars, i, eq_count) {
              i = i + eq_count + 2
              closed = true
              break
            }
            i = i + 1
          }
          push_token(
            spans,
            offset_at(text, offsets, start_i),
            offset_at(text, offsets, i),
            StringLit,
          )
          if !closed {
            state = LineState::{
              ..state,
              lua_long_eq_count_opt: Some(eq_count),
              lua_long_is_comment: false,
            }
          }
          continue
        }
      }
    }

    if has_line_comment_prefix(syntax_name, chars, i) {
      push_token(spans, offset_at(text, offsets, i), text.length(), Comment)
      break
    }

    if i == line_first &&
      syntax_name == "rust" &&
      chars[i] == '#' &&
      i + 1 < n &&
      (
        chars[i + 1] == '[' ||
        (chars[i + 1] == '!' && i + 2 < n && chars[i + 2] == '[')
      ) {
      push_token(spans, offset_at(text, offsets, i), text.length(), Keyword)
      break
    }

    if supports_block_comment(syntax_name) &&
      i + 1 < n &&
      chars[i] == '/' &&
      chars[i + 1] == '*' {
      let start_i = i
      i = i + 2
      let nested = supports_nested_block_comment(syntax_name)
      let mut depth = 1
      let mut end_i = n
      let mut close_found = false
      while i + 1 < n {
        if nested && chars[i] == '/' && chars[i + 1] == '*' {
          depth = depth + 1
          i = i + 2
          continue
        }
        if chars[i] == '*' && chars[i + 1] == '/' {
          depth = depth - 1
          i = i + 2
          if depth == 0 {
            end_i = i
            close_found = true
            break
          }
          continue
        }
        i = i + 1
      }
      if !close_found {
        i = n
        state = LineState::{ ..state, block_comment_depth: depth }
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, end_i),
        Comment,
      )
      continue
    }

    if syntax_name == "python" && is_python_string_prefix_char(chars[i]) {
      let start_i = i
      let mut j = i
      while j < n && j - start_i < 2 && is_python_string_prefix_char(chars[j]) {
        j = j + 1
      }
      if j < n && (chars[j] == '"' || chars[j] == '\'') {
        let delim = chars[j]
        let triple = j + 2 < n && chars[j + 1] == delim && chars[j + 2] == delim
        if triple {
          i = j + 3
        } else {
          i = j + 1
        }
        let mut escaped = false
        let mut closed = false
        while i < n {
          let ch = chars[i]
          if triple {
            if i + 2 < n &&
              chars[i] == delim &&
              chars[i + 1] == delim &&
              chars[i + 2] == delim {
              i = i + 3
              closed = true
              break
            }
            i = i + 1
            continue
          }
          if escaped {
            escaped = false
            i = i + 1
            continue
          }
          if ch == '\\' {
            escaped = true
            i = i + 1
            continue
          }
          if ch == delim {
            i = i + 1
            closed = true
            break
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          StringLit,
        )
        if !closed {
          let continue_string = triple || escaped
          if continue_string {
            state = LineState::{
              ..state,
              string_delim_opt: Some(delim),
              string_is_triple: triple,
            }
          }
        }
        continue
      }
    }

    if syntax_name == "rust" && chars[i] == 'b' && i + 1 < n {
      if chars[i + 1] == '"' || chars[i + 1] == '\'' {
        let start_i = i
        let delim = chars[i + 1]
        i = i + 2
        let mut escaped = false
        let mut closed = false
        while i < n {
          let ch = chars[i]
          if escaped {
            escaped = false
            i = i + 1
            continue
          }
          if ch == '\\' {
            escaped = true
            i = i + 1
            continue
          }
          if ch == delim {
            i = i + 1
            closed = true
            break
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          StringLit,
        )
        if !closed && escaped {
          state = LineState::{ ..state, string_delim_opt: Some(delim) }
        }
        continue
      }
      if chars[i + 1] == 'r' {
        let start_i = i
        let mut j = i + 2
        while j < n && chars[j] == '#' {
          j = j + 1
        }
        if j < n && chars[j] == '"' {
          let hashes = j - (i + 2)
          i = j + 1
          let mut closed = false
          while i < n {
            if chars[i] == '"' {
              let mut ok = true
              let mut k = 0
              while k < hashes {
                if i + 1 + k >= n || chars[i + 1 + k] != '#' {
                  ok = false
                  break
                }
                k = k + 1
              }
              if ok {
                i = i + 1 + hashes
                closed = true
                break
              }
            }
            i = i + 1
          }
          push_token(
            spans,
            offset_at(text, offsets, start_i),
            offset_at(text, offsets, i),
            StringLit,
          )
          if !closed {
            state = LineState::{ ..state, raw_hash_count_opt: Some(hashes) }
          }
          continue
        }
      }
    }

    if syntax_name == "rust" && chars[i] == 'r' {
      let start_i = i
      let mut j = i + 1
      while j < n && chars[j] == '#' {
        j = j + 1
      }
      if j < n && chars[j] == '"' {
        let hashes = j - (i + 1)
        i = j + 1
        let mut closed = false
        while i < n {
          if chars[i] == '"' {
            let mut ok = true
            let mut k = 0
            while k < hashes {
              if i + 1 + k >= n || chars[i + 1 + k] != '#' {
                ok = false
                break
              }
              k = k + 1
            }
            if ok {
              i = i + 1 + hashes
              closed = true
              break
            }
          }
          i = i + 1
        }
        push_token(
          spans,
          offset_at(text, offsets, start_i),
          offset_at(text, offsets, i),
          StringLit,
        )
        if !closed {
          state = LineState::{ ..state, raw_hash_count_opt: Some(hashes) }
        }
        continue
      }
    }

    if syntax_name == "rust" && chars[i] == '\'' {
      match rust_char_literal_end(chars, i) {
        Some(end_i) => {
          push_token(
            spans,
            offset_at(text, offsets, i),
            offset_at(text, offsets, end_i),
            StringLit,
          )
          i = end_i
          continue
        }
        None =>
          if i + 1 < n && is_identifier_start(chars[i + 1]) {
            // Rust lifetime like `'a` should not be tokenized as a string.
            i = i + 1
            continue
          }
      }
    }

    if chars[i] == '"' || chars[i] == '\'' {
      let delim = chars[i]
      let start_i = i
      let triple = syntax_name == "python" &&
        i + 2 < n &&
        chars[i + 1] == delim &&
        chars[i + 2] == delim
      if triple {
        i = i + 3
      } else {
        i = i + 1
      }
      let mut escaped = false
      let mut closed = false
      while i < n {
        let ch = chars[i]
        if triple {
          if i + 2 < n &&
            chars[i] == delim &&
            chars[i + 1] == delim &&
            chars[i + 2] == delim {
            i = i + 3
            closed = true
            break
          }
          i = i + 1
          continue
        }
        if escaped {
          escaped = false
          i = i + 1
          continue
        }
        if ch == '\\' {
          escaped = true
          i = i + 1
          continue
        }
        if ch == delim {
          i = i + 1
          closed = true
          break
        }
        i = i + 1
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        StringLit,
      )
      if !closed {
        let continue_string = triple || (syntax_name == "python" && escaped)
        if continue_string {
          state = LineState::{
            ..state,
            string_delim_opt: Some(delim),
            string_is_triple: triple,
          }
        }
      }
      continue
    }

    if is_ascii_digit(chars[i]) {
      let start_i = i
      i = i + 1
      let allow_alpha = syntax_name == "rust" ||
        syntax_name == "clike" ||
        syntax_name == "python"
      while i < n {
        let ch = chars[i]
        if is_ascii_digit(ch) ||
          ch == '.' ||
          ch == '_' ||
          (allow_alpha && is_ascii_alpha(ch)) {
          i = i + 1
        } else if allow_alpha &&
          (ch == '+' || ch == '-') &&
          i > start_i &&
          (
            chars[i - 1] == 'e' ||
            chars[i - 1] == 'E' ||
            chars[i - 1] == 'p' ||
            chars[i - 1] == 'P'
          ) {
          i = i + 1
        } else {
          break
        }
      }
      push_token(
        spans,
        offset_at(text, offsets, start_i),
        offset_at(text, offsets, i),
        Number,
      )
      continue
    }

    if is_identifier_start(chars[i]) {
      let start_i = i
      i = i + 1
      while i < n && is_identifier_part(chars[i]) {
        i = i + 1
      }
      let start = offset_at(text, offsets, start_i)
      let end = offset_at(text, offsets, i)
      let word = slice_string(text, start, end)
      match classify_identifier(word, syntax_name) {
        None => ()
        Some(class) => push_token(spans, start, end, class)
      }
      continue
    }

    i = i + 1
  }
  (spans, state)
}

///|
fn attrs_for_token(
  defaults : @cosmic.Attrs,
  theme : SyntaxTheme,
  class : TokenClass,
) -> @cosmic.Attrs {
  match class {
    Keyword => defaults.color(theme.keyword).weight(@cosmic.Weight::bold())
    TypeName => defaults.color(theme.type_name)
    StringLit => defaults.color(theme.string_lit)
    Comment => defaults.color(theme.comment).style(@moon_swash.Style::Italic)
    Number => defaults.color(theme.number)
  }
}

///|
fn push_text_span(
  rich_spans : Array[(String, @cosmic.Attrs)],
  text : String,
  start : Int,
  end : Int,
  attrs : @cosmic.Attrs,
) -> Unit {
  if end > start {
    rich_spans.push((slice_string(text, start, end), attrs))
  }
}

///|
fn append_highlighted_line_spans(
  rich_spans : Array[(String, @cosmic.Attrs)],
  text : String,
  defaults : @cosmic.Attrs,
  theme : SyntaxTheme,
  token_spans : Array[TokenSpan],
) -> Unit {
  let mut cursor = 0
  for span in token_spans {
    let start = span.start
    let end = span.end
    if start > cursor {
      push_text_span(rich_spans, text, cursor, start, defaults)
    }
    push_text_span(
      rich_spans,
      text,
      start,
      end,
      attrs_for_token(defaults, theme, span.class),
    )
    cursor = end
  }
  if cursor < text.length() {
    push_text_span(rich_spans, text, cursor, text.length(), defaults)
  }
}

///|
fn themed_defaults(
  defaults : @cosmic.Attrs,
  theme : SyntaxTheme,
) -> @cosmic.Attrs {
  defaults.color(theme.foreground)
}

///|
fn syntax_apply_theme_defaults(
  editor : @cosmic.Editor,
  theme : SyntaxTheme,
) -> @cosmic.Editor {
  let old_buffer = editor.buffer()
  let old_cursor = editor.cursor()
  let old_selection = editor.selection()
  let old_auto_indent = editor.auto_indent()
  let old_tab_width = editor.tab_width()
  let old_scroll = old_buffer.scroll()
  let lines = old_buffer.lines()
  let rich_spans : Array[(String, @cosmic.Attrs)] = []
  for line in lines {
    let defaults = themed_defaults(line.attrs_list().defaults(), theme)
    rich_spans.push((line.text(), defaults))
    let ending = line.ending().as_str()
    if ending.length() > 0 {
      rich_spans.push((ending, defaults))
    }
  }
  let default_attrs = if lines.length() > 0 {
    themed_defaults(lines[0].attrs_list().defaults(), theme)
  } else {
    themed_defaults(@cosmic.Attrs::new(), theme)
  }
  let new_buffer = old_buffer
    .set_rich_text(rich_spans, default_attrs, @cosmic.Advanced, None)
    .set_scroll(old_scroll)
  @cosmic.Editor::new(new_buffer)
  .set_cursor(old_cursor)
  .set_selection(old_selection)
  .set_auto_indent(old_auto_indent)
  .set_tab_width(old_tab_width)
}

///|
fn rebuild_editor_with_highlight(
  editor : @cosmic.Editor,
  theme : SyntaxTheme,
  syntax_name : String,
  old_cache : Array[CachedLine],
) -> (@cosmic.Editor, Array[CachedLine]) {
  let old_buffer = editor.buffer()
  let old_cursor = editor.cursor()
  let old_selection = editor.selection()
  let old_auto_indent = editor.auto_indent()
  let old_tab_width = editor.tab_width()
  let old_scroll = old_buffer.scroll()
  let lines = old_buffer.lines()
  let rich_spans : Array[(String, @cosmic.Attrs)] = []
  let new_cache : Array[CachedLine] = []
  let mut state = LineState::new()
  for p in lines.iter2() {
    let line_i = p.0
    let line = p.1
    let text = line.text()
    let defaults = themed_defaults(line.attrs_list().defaults(), theme)
    let cache_hit = if line_i < old_cache.length() {
      let cached = old_cache[line_i]
      cached.text == text && cached.state_in == state
    } else {
      false
    }
    let spans_and_state = if cache_hit {
      (old_cache[line_i].spans, old_cache[line_i].state_out)
    } else {
      tokenize_line(text, syntax_name, state)
    }
    let spans = spans_and_state.0
    let state_out = spans_and_state.1
    append_highlighted_line_spans(rich_spans, text, defaults, theme, spans)
    let ending = line.ending().as_str()
    if ending.length() > 0 {
      rich_spans.push((ending, defaults))
    }
    let spans_copy : Array[TokenSpan] = []
    for span in spans {
      spans_copy.push(span)
    }
    new_cache.push(CachedLine::{
      text,
      state_in: state,
      state_out,
      spans: spans_copy,
    })
    state = state_out
  }

  let default_attrs = if lines.length() > 0 {
    themed_defaults(lines[0].attrs_list().defaults(), theme)
  } else {
    themed_defaults(@cosmic.Attrs::new(), theme)
  }
  let new_buffer = old_buffer
    .set_rich_text(rich_spans, default_attrs, @cosmic.Advanced, None)
    .set_scroll(old_scroll)
  let new_editor = @cosmic.Editor::new(new_buffer)
    .set_cursor(old_cursor)
    .set_selection(old_selection)
    .set_auto_indent(old_auto_indent)
    .set_tab_width(old_tab_width)
  (new_editor, new_cache)
}

///|
pub fn SyntaxEditor::new(
  editor : @cosmic.Editor,
  syntax_system : SyntaxSystem,
  theme_name : String,
) -> SyntaxEditor? {
  match syntax_system.theme(theme_name) {
    None => None
    Some(theme) => {
      let syntax_name = syntax_system.plain_text_syntax()
      Some(SyntaxEditor::{
        editor,
        syntax_system,
        syntax_name,
        theme,
        cache: [],
      })
    }
  }
}

///|
pub fn SyntaxEditor::editor(self : SyntaxEditor) -> @cosmic.Editor {
  self.editor
}

///|
pub fn SyntaxEditor::theme(self : SyntaxEditor) -> SyntaxTheme {
  self.theme
}

///|
pub fn SyntaxEditor::syntax_name(self : SyntaxEditor) -> String {
  self.syntax_name
}

///|
pub fn SyntaxEditor::background_color(self : SyntaxEditor) -> @cosmic.Color {
  self.theme.background()
}

///|
pub fn SyntaxEditor::foreground_color(self : SyntaxEditor) -> @cosmic.Color {
  self.theme.foreground()
}

///|
pub fn SyntaxEditor::cursor_color(self : SyntaxEditor) -> @cosmic.Color {
  self.theme.cursor()
}

///|
pub fn SyntaxEditor::selection_color(self : SyntaxEditor) -> @cosmic.Color {
  self.theme.selection()
}

///|
pub fn SyntaxEditor::set_editor(
  self : SyntaxEditor,
  editor : @cosmic.Editor,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor, }
}

///|
pub fn SyntaxEditor::update_theme(
  self : SyntaxEditor,
  theme_name : String,
) -> (SyntaxEditor, Bool) {
  match self.syntax_system.theme(theme_name) {
    None => (self, false)
    Some(theme) =>
      (
        SyntaxEditor::{
          ..self,
          editor: syntax_apply_theme_defaults(self.editor, theme),
          theme,
          cache: [],
        },
        true,
      )
  }
}

///|
pub fn SyntaxEditor::syntax_by_extension(
  self : SyntaxEditor,
  extension : String,
) -> SyntaxEditor {
  let syntax_name = match self.syntax_system.syntax_for_extension(extension) {
    None => self.syntax_system.plain_text_syntax()
    Some(name) => name
  }
  SyntaxEditor::{ ..self, syntax_name, cache: [] }
}

///|
pub fn SyntaxEditor::rehighlight(self : SyntaxEditor) -> SyntaxEditor {
  let (new_editor, cache) = rebuild_editor_with_highlight(
    self.editor,
    self.theme,
    self.syntax_name,
    self.cache,
  )
  SyntaxEditor::{ ..self, editor: new_editor, cache }
}

///|
pub fn SyntaxEditor::action(
  self : SyntaxEditor,
  action : @cosmic.Action,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.action(action) }
}

///|
pub fn SyntaxEditor::cursor(self : SyntaxEditor) -> @cosmic.Cursor {
  self.editor.cursor()
}

///|
pub fn SyntaxEditor::set_cursor(
  self : SyntaxEditor,
  cursor : @cosmic.Cursor,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.set_cursor(cursor) }
}

///|
pub fn SyntaxEditor::selection(self : SyntaxEditor) -> @cosmic.Selection {
  self.editor.selection()
}

///|
pub fn SyntaxEditor::set_selection(
  self : SyntaxEditor,
  selection : @cosmic.Selection,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.set_selection(selection) }
}

///|
pub fn SyntaxEditor::auto_indent(self : SyntaxEditor) -> Bool {
  self.editor.auto_indent()
}

///|
pub fn SyntaxEditor::set_auto_indent(
  self : SyntaxEditor,
  auto_indent : Bool,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.set_auto_indent(auto_indent) }
}

///|
pub fn SyntaxEditor::tab_width(self : SyntaxEditor) -> Int {
  self.editor.tab_width()
}

///|
pub fn SyntaxEditor::set_tab_width(
  self : SyntaxEditor,
  tab_width : Int,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.set_tab_width(tab_width) }
}

///|
pub fn SyntaxEditor::start_change(self : SyntaxEditor) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.start_change() }
}

///|
pub fn SyntaxEditor::finish_change(
  self : SyntaxEditor,
) -> (SyntaxEditor, @cosmic.Change?) {
  let finished = self.editor.finish_change()
  (SyntaxEditor::{ ..self, editor: finished.0 }, finished.1)
}

///|
pub fn SyntaxEditor::copy_selection(self : SyntaxEditor) -> String? {
  self.editor.copy_selection()
}

///|
pub fn SyntaxEditor::delete_selection(
  self : SyntaxEditor,
) -> (SyntaxEditor, Bool) {
  let deleted = self.editor.delete_selection()
  (SyntaxEditor::{ ..self, editor: deleted.0 }, deleted.1)
}

///|
pub fn SyntaxEditor::delete_range(
  self : SyntaxEditor,
  start : @cosmic.Cursor,
  end : @cosmic.Cursor,
) -> SyntaxEditor {
  SyntaxEditor::{
    ..self,
    editor: self.editor.start_change().delete_range(start, end),
  }
}

///|
pub fn SyntaxEditor::insert_string(
  self : SyntaxEditor,
  data : String,
  attrs_list_opt : @cosmic.AttrsList?,
) -> SyntaxEditor {
  SyntaxEditor::{
    ..self,
    editor: self.editor.start_change().insert_string(data, attrs_list_opt),
  }
}

///|
pub fn SyntaxEditor::apply_change(
  self : SyntaxEditor,
  change : @cosmic.Change,
) -> (SyntaxEditor, Bool) {
  let applied = self.editor.apply_change(change)
  (SyntaxEditor::{ ..self, editor: applied.0 }, applied.1)
}

///|
pub fn SyntaxEditor::cursor_position(self : SyntaxEditor) -> (Int, Int)? {
  self.editor.cursor_position()
}

///|
pub fn[R : @cosmic.Renderer] SyntaxEditor::render(
  self : SyntaxEditor,
  renderer : R,
) -> Unit {
  let size = self.editor.buffer().size()
  match size.0 {
    None => ()
    Some(width) =>
      match size.1 {
        None => ()
        Some(height) =>
          renderer.rectangle(
            0,
            0,
            width.to_double().to_int().reinterpret_as_uint(),
            height.to_double().to_int().reinterpret_as_uint(),
            self.background_color(),
          )
      }
  }
  self.editor.render(
    renderer,
    self.foreground_color(),
    self.cursor_color(),
    self.selection_color(),
    self.foreground_color(),
  )
}
