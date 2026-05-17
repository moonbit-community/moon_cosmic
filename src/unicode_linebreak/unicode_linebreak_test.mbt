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
fn ulb_slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=end - start)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
fn ulb_find_code_unit(s : String, code : Int) -> Int? {
  for i in 0..<s.length() {
    if s.code_unit_at(i).to_int() == code {
      return Some(i)
    }
  }
  None
}

///|
fn ulb_find_substring(text : String, pattern : String) -> Int? {
  let plen = pattern.length()
  if plen == 0 || plen > text.length() {
    return None
  }
  let end = text.length() - plen
  for i in 0..<(end + 1) {
    let mut ok = true
    for j in 0..<plen {
      if text.code_unit_at(i + j) != pattern.code_unit_at(j) {
        ok = false
        break
      }
    }
    if ok {
      return Some(i)
    }
  }
  None
}

///|
fn ulb_trim_start_ws(s : String) -> String {
  let mut i = 0
  while i < s.length() {
    let c = s.code_unit_at(i).to_int()
    if c != 32 && c != 9 {
      break
    }
    i = i + 1
  }
  ulb_slice_string(s, i, s.length())
}

///|
fn ulb_split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let mut start = 0
  for i in 0..<s.length() {
    if s.code_unit_at(i).to_int() == 10 {
      let end = if i > start && s.code_unit_at(i - 1).to_int() == 13 {
        i - 1
      } else {
        i
      }
      lines.push(ulb_slice_string(s, start, end))
      start = i + 1
    }
  }
  if start < s.length() {
    lines.push(ulb_slice_string(s, start, s.length()))
  }
  lines
}

///|
fn ulb_tokenize_ws(s : String) -> Array[String] {
  let out : Array[String] = []
  let mut i = 0
  while i < s.length() {
    let c = s.code_unit_at(i).to_int()
    if c == 32 || c == 9 {
      i = i + 1
      continue
    }
    let start = i
    i = i + 1
    while i < s.length() {
      let d = s.code_unit_at(i).to_int()
      if d == 32 || d == 9 {
        break
      }
      i = i + 1
    }
    out.push(ulb_slice_string(s, start, i))
  }
  out
}

///|
fn ulb_hex_digit(c : Int) -> Int? {
  if c >= 48 && c <= 57 {
    Some(c - 48)
  } else if c >= 65 && c <= 70 {
    Some(c - 55)
  } else if c >= 97 && c <= 102 {
    Some(c - 87)
  } else {
    None
  }
}

///|
fn ulb_parse_hex(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  let mut v = 0
  for i in 0..<s.length() {
    let d = match ulb_hex_digit(s.code_unit_at(i).to_int()) {
      None => return None
      Some(x) => x
    }
    v = v * 16 + d
  }
  Some(v)
}

///|
fn ulb_codepoint_to_char(cp : Int) -> Char? {
  if cp < 0 || cp > 0x10FFFF {
    return None
  }
  if cp >= 0xD800 && cp <= 0xDFFF {
    return None
  }
  Some(cp.unsafe_to_char())
}

///|
fn ulb_codepoint_utf16_len(cp : Int) -> Int {
  if cp > 0xFFFF {
    2
  } else {
    1
  }
}

///|
fn ulb_build_text(codepoints : Array[Int]) -> String {
  let sb = StringBuilder::new(size_hint=codepoints.length() * 2)
  for cp in codepoints {
    match ulb_codepoint_to_char(cp) {
      None => abort("invalid codepoint in LineBreakTest.txt")
      Some(ch) => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn ulb_array_eq_int(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
test "unicode_linebreak parity on upstream LineBreakTest vectors" {
  let text = @fs.read_file_to_string("src/unicode_linebreak/LineBreakTest.txt")
  let lines = ulb_split_lines(text)
  let mut checked = 0
  let mut mismatches = 0

  for p in lines.iter2() {
    let line_no = p.0 + 1
    let line = p.1
    if line.length() == 0 {
      continue
    }
    if line.code_unit_at(0).to_int() == 35 {
      continue
    }
    let hash_i = match ulb_find_code_unit(line, 35) {
      None => continue
      Some(v) => v
    }
    let prefix = ulb_slice_string(line, 0, hash_i)
    let comment = ulb_trim_start_ws(
      ulb_slice_string(line, hash_i + 1, line.length()),
    )
    // Match upstream skip set.
    if ulb_find_substring(comment, "[30.22]") is Some(_) ||
      ulb_find_substring(comment, "[999.0]") is Some(_) {
      continue
    }

    let tokens = ulb_tokenize_ws(prefix)
    if tokens.length() < 3 {
      continue
    }
    // First token is the leading boundary marker.
    let mut ti = 1
    let cps : Array[Int] = []
    let expected : Array[Int] = []
    let mut utf16_offset = 0
    while ti + 1 < tokens.length() {
      let cp = match ulb_parse_hex(tokens[ti]) {
        None => abort("invalid hex token at line \{line_no}")
        Some(v) => v
      }
      let marker = tokens[ti + 1]
      ti = ti + 2
      cps.push(cp)
      utf16_offset = utf16_offset + ulb_codepoint_utf16_len(cp)
      if marker == "÷" {
        expected.push(utf16_offset)
      } else if marker == "×" {
        ()
      } else {
        abort("invalid boundary marker at line \{line_no}")
      }
    }

    let case_text = ulb_build_text(cps)
    let actual_pairs = linebreaks(case_text)
    let actual : Array[Int] = []
    for pair in actual_pairs {
      actual.push(pair.0)
    }

    if !ulb_array_eq_int(actual, expected) {
      mismatches = mismatches + 1
      println("unicode_linebreak mismatch line=\{line_no}")
      println("comment: \{comment}")
      println("actual: \{@debug.to_string(actual)}")
      println("expected: \{@debug.to_string(expected)}")
    }
    checked = checked + 1
  }

  // Keep this pinned to ensure we execute the full vector set (minus upstream skip set).
  inspect(checked, content="6424")
  inspect(mismatches, content="0")
}
