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
  background : Color
  foreground : Color
  cursor_opt : Color?
  selection_opt : Color?
  keyword : Color
  type_name : Color
  string_lit : Color
  comment : Color
  number : Color
}

///|
pub fn SyntaxTheme::name(self : SyntaxTheme) -> String {
  self.name
}

///|
pub fn SyntaxTheme::background(self : SyntaxTheme) -> Color {
  self.background
}

///|
pub fn SyntaxTheme::foreground(self : SyntaxTheme) -> Color {
  self.foreground
}

///|
pub fn SyntaxTheme::cursor(self : SyntaxTheme) -> Color {
  match self.cursor_opt {
    Some(color) => color
    None => self.foreground
  }
}

///|
pub fn SyntaxTheme::selection(self : SyntaxTheme) -> Color {
  match self.selection_opt {
    Some(color) => color
    None =>
      Color::rgba(
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
    background: Color::rgb(0x2D, 0x2D, 0x2D),
    foreground: Color::rgb(0xD3, 0xD0, 0xC8),
    cursor_opt: Some(Color::rgb(0xD3, 0xD0, 0xC8)),
    selection_opt: Some(Color::rgba(0x51, 0x51, 0x51, 0xCC)),
    keyword: Color::rgb(0xCC, 0x99, 0xCC),
    type_name: Color::rgb(0xF2, 0x77, 0x7A),
    string_lit: Color::rgb(0x99, 0xCC, 0x99),
    comment: Color::rgb(0x74, 0x74, 0x74),
    number: Color::rgb(0xF9, 0x91, 0x57),
  }
}

///|
fn theme_base16_ocean_light() -> SyntaxTheme {
  SyntaxTheme::{
    name: "base16-ocean.light",
    background: Color::rgb(0xEF, 0xF1, 0xF5),
    foreground: Color::rgb(0x4F, 0x5B, 0x66),
    cursor_opt: Some(Color::rgb(0x4F, 0x5B, 0x66)),
    selection_opt: Some(Color::rgba(0xBF, 0xC7, 0xD5, 0xD8)),
    keyword: Color::rgb(0xA7, 0xB8, 0xC8),
    type_name: Color::rgb(0xBF, 0x61, 0x6A),
    string_lit: Color::rgb(0xA3, 0xBE, 0x8C),
    comment: Color::rgb(0xA7, 0xAD, 0xBA),
    number: Color::rgb(0xD0, 0x87, 0x70),
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
  if name == "base16-eighties.dark" {
    Some(theme_base16_eighties_dark())
  } else if name == "base16-ocean.light" {
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
  if ext == "rs" {
    Some("rust")
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
    ext == "java" ||
    ext == "go" {
    Some("clike")
  } else if ext == "py" {
    Some("python")
  } else if ext == "json" {
    Some("json")
  } else if ext == "md" || ext == "markdown" {
    Some("markdown")
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
  string_delim_opt : Char?
  string_is_triple : Bool
  raw_hash_count_opt : Int?
}

///|
pub fn LineState::new() -> LineState {
  LineState::{
    block_comment_depth: 0,
    string_delim_opt: None,
    string_is_triple: false,
    raw_hash_count_opt: None,
  }
}

///|
pub impl Eq for LineState with equal(self, other) {
  self.block_comment_depth == other.block_comment_depth &&
  self.string_delim_opt == other.string_delim_opt &&
  self.string_is_triple == other.string_is_triple &&
  self.raw_hash_count_opt == other.raw_hash_count_opt
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
  editor : Editor
  syntax_system : SyntaxSystem
  syntax_name : String
  theme : SyntaxTheme
  cache : Array[CachedLine]
}

///|
fn syntax_slice_string(s : String, start : Int, end : Int) -> String {
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
  } else if syntax_name == "json" {
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
  if syntax_name == "python" {
    i < chars.length() && chars[i] == '#'
  } else if syntax_name == "rust" || syntax_name == "clike" {
    i + 1 < chars.length() && chars[i] == '/' && chars[i + 1] == '/'
  } else {
    false
  }
}

///|
fn supports_block_comment(syntax_name : String) -> Bool {
  syntax_name == "rust" || syntax_name == "clike"
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

    if has_line_comment_prefix(syntax_name, chars, i) {
      push_token(spans, offset_at(text, offsets, i), text.length(), Comment)
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
      let word = syntax_slice_string(text, start, end)
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
  defaults : Attrs,
  theme : SyntaxTheme,
  class : TokenClass,
) -> Attrs {
  match class {
    Keyword => defaults.color(theme.keyword).weight(Weight::bold())
    TypeName => defaults.color(theme.type_name)
    StringLit => defaults.color(theme.string_lit)
    Comment => defaults.color(theme.comment).style(@moon_swash.Style::Italic)
    Number => defaults.color(theme.number)
  }
}

///|
fn themed_defaults(defaults : Attrs, theme : SyntaxTheme) -> Attrs {
  defaults.color(theme.foreground)
}

///|
fn copy_token_spans(spans : Array[TokenSpan]) -> Array[TokenSpan] {
  let copied : Array[TokenSpan] = []
  for span in spans {
    copied.push(span)
  }
  copied
}

///|
fn highlighted_attrs_list_for_line(
  defaults : Attrs,
  theme : SyntaxTheme,
  spans : Array[TokenSpan],
) -> AttrsList {
  let mut attrs_list = AttrsList::new(defaults)
  for span in spans {
    let attrs = attrs_for_token(defaults, theme, span.class)
    if attrs != defaults {
      attrs_list = attrs_list.add_span(span.start, span.end, attrs)
    }
  }
  attrs_list
}

///|
fn syntax_highlight_buffer(
  buffer : Buffer,
  theme : SyntaxTheme,
  syntax_name : String,
  old_cache : Array[CachedLine],
  allow_cache : Bool,
) -> (Buffer, Array[CachedLine], Int) {
  let lines = buffer.lines()
  let new_lines : Array[BufferLine] = []
  let new_cache : Array[CachedLine] = []
  let mut state = LineState::new()
  let mut highlighted = 0
  let mut changed = false
  for p in lines.iter2() {
    let line_i = p.0
    let line = p.1
    let text = line.text()
    let defaults = line.attrs_list().defaults()
    let cache_hit = if allow_cache &&
      line_i < old_cache.length() &&
      line.metadata() is Some(_) {
      let cached = old_cache[line_i]
      cached.text == text && cached.state_in == state
    } else {
      false
    }
    let spans_and_state = if cache_hit {
      (old_cache[line_i].spans, old_cache[line_i].state_out)
    } else {
      highlighted = highlighted + 1
      tokenize_line(text, syntax_name, state)
    }
    let spans = spans_and_state.0
    let state_out = spans_and_state.1
    let attrs_list = highlighted_attrs_list_for_line(defaults, theme, spans)
    let set_attrs = line.set_attrs_list(attrs_list)
    let mut updated_line = set_attrs.0
    if set_attrs.1 {
      changed = true
    }
    let metadata_set = match updated_line.metadata() {
      Some(v) => v != line_i
      None => true
    }
    if metadata_set {
      updated_line = updated_line.set_metadata(line_i)
    }
    new_lines.push(updated_line)
    new_cache.push(CachedLine::{
      text,
      state_in: state,
      state_out,
      spans: copy_token_spans(spans),
    })
    state = state_out
  }
  let redraw = buffer.redraw() || changed || highlighted > 0
  (Buffer::{ ..buffer, lines: new_lines, redraw }, new_cache, highlighted)
}

///|
fn syntax_apply_theme_defaults(buffer : Buffer, theme : SyntaxTheme) -> Buffer {
  let lines = buffer.lines()
  let new_lines : Array[BufferLine] = []
  let mut changed = false
  for line in lines {
    let defaults = themed_defaults(line.attrs_list().defaults(), theme)
    let set_line = line.set_attrs_list(AttrsList::new(defaults))
    if set_line.1 {
      changed = true
    }
    new_lines.push(set_line.0)
  }
  Buffer::{ ..buffer, lines: new_lines, redraw: buffer.redraw() || changed }
}

///|
fn syntax_rehighlight_editor(
  editor : Editor,
  theme : SyntaxTheme,
  syntax_name : String,
  old_cache : Array[CachedLine],
  allow_cache : Bool,
) -> (Editor, Array[CachedLine], Int) {
  let highlighted = syntax_highlight_buffer(
    editor.buffer(),
    theme,
    syntax_name,
    old_cache,
    allow_cache,
  )
  (Editor::{ ..editor, buffer: highlighted.0 }, highlighted.1, highlighted.2)
}

///|
pub fn SyntaxEditor::new(
  editor : Editor,
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
pub fn SyntaxEditor::editor(self : SyntaxEditor) -> Editor {
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
pub fn SyntaxEditor::background_color(self : SyntaxEditor) -> Color {
  self.theme.background()
}

///|
pub fn SyntaxEditor::foreground_color(self : SyntaxEditor) -> Color {
  self.theme.foreground()
}

///|
pub fn SyntaxEditor::cursor_color(self : SyntaxEditor) -> Color {
  self.theme.cursor()
}

///|
pub fn SyntaxEditor::selection_color(self : SyntaxEditor) -> Color {
  self.theme.selection()
}

///|
pub fn SyntaxEditor::set_editor(
  self : SyntaxEditor,
  editor : Editor,
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
    Some(theme) => {
      let themed_buffer = syntax_apply_theme_defaults(
        self.editor.buffer(),
        theme,
      )
      let themed_editor = Editor::{ ..self.editor, buffer: themed_buffer }
      (SyntaxEditor::{ ..self, editor: themed_editor, theme, cache: [] }, true)
    }
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
  let highlighted = syntax_rehighlight_editor(
    self.editor,
    self.theme,
    self.syntax_name,
    self.cache,
    true,
  )
  SyntaxEditor::{ ..self, editor: highlighted.0, cache: highlighted.1 }
}

///|
pub fn SyntaxEditor::action(
  self : SyntaxEditor,
  action : Action,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.action(action) }
}

///|
pub fn SyntaxEditor::cursor(self : SyntaxEditor) -> Cursor {
  self.editor.cursor()
}

///|
pub fn SyntaxEditor::set_cursor(
  self : SyntaxEditor,
  cursor : Cursor,
) -> SyntaxEditor {
  SyntaxEditor::{ ..self, editor: self.editor.set_cursor(cursor) }
}

///|
pub fn SyntaxEditor::selection(self : SyntaxEditor) -> Selection {
  self.editor.selection()
}

///|
pub fn SyntaxEditor::set_selection(
  self : SyntaxEditor,
  selection : Selection,
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
) -> (SyntaxEditor, Change?) {
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
  start : Cursor,
  end : Cursor,
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
  attrs_list_opt : AttrsList?,
) -> SyntaxEditor {
  SyntaxEditor::{
    ..self,
    editor: self.editor.start_change().insert_string(data, attrs_list_opt),
  }
}

///|
pub fn SyntaxEditor::apply_change(
  self : SyntaxEditor,
  change : Change,
) -> (SyntaxEditor, Bool) {
  let applied = self.editor.apply_change(change)
  (SyntaxEditor::{ ..self, editor: applied.0 }, applied.1)
}

///|
pub fn SyntaxEditor::cursor_position(self : SyntaxEditor) -> (Int, Int)? {
  self.editor.cursor_position()
}

///|
pub fn[R : Renderer] SyntaxEditor::render(
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
