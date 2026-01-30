#!/usr/bin/env python3
"""
Generate a MoonBit *_test.mbt file embedding a TTF as base64.

This is intentionally a tiny build helper for this repo's test suite; it keeps
large base64 blobs out of handwritten edits.
"""

from __future__ import annotations

import base64
import textwrap
from pathlib import Path


LICENSE_HEADER = """// Copyright 2025 International Digital Economy Academy
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
"""


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    font_path = repo / "cosmic-text-reference" / "fonts" / "Inter-Regular.ttf"
    out_path = repo / "src" / "test_fonts_test.mbt"

    b64 = base64.b64encode(font_path.read_bytes()).decode("ascii")
    chunks = textwrap.wrap(b64, 76)

    out: list[str] = []
    out.append(LICENSE_HEADER.rstrip("\n"))
    out.append("")
    out.append("///|")
    out.append("/// Embedded font data for tests (base64).")
    out.append("")
    out.append("fn base64_value(cu : UInt16) -> Int? {")
    out.append("  let c = cu.to_int()")
    out.append("  if c >= 65 && c <= 90 {")
    out.append("    Some(c - 65)")
    out.append("  } else if c >= 97 && c <= 122 {")
    out.append("    Some(c - 97 + 26)")
    out.append("  } else if c >= 48 && c <= 57 {")
    out.append("    Some(c - 48 + 52)")
    out.append("  } else if c == 43 {")
    out.append("    Some(62)")
    out.append("  } else if c == 47 {")
    out.append("    Some(63)")
    out.append("  } else {")
    out.append("    None")
    out.append("  }")
    out.append("}")
    out.append("")
    out.append("fn decode_base64_ascii(s : String) -> Bytes {")
    out.append("  let out : Array[Byte] = []")
    out.append("  let mut buf = 0")
    out.append("  let mut bits = 0")
    out.append("  for i in 0..<s.length() {")
    out.append("    let cu = s.code_unit_at(i)")
    out.append("    let c = cu.to_int()")
    out.append("    // Skip whitespace.")
    out.append("    if c == 10 || c == 13 || c == 32 || c == 9 {")
    out.append("      continue")
    out.append("    }")
    out.append("    // Padding.")
    out.append("    if c == 61 {")
    out.append("      break")
    out.append("    }")
    out.append("    match base64_value(cu) {")
    out.append("      None => continue")
    out.append("      Some(v) => {")
    out.append("        buf = (buf << 6) | v")
    out.append("        bits = bits + 6")
    out.append("        while bits >= 8 {")
    out.append("          bits = bits - 8")
    out.append("          let b = (buf >> bits) & 0xFF")
    out.append("          out.push(b.to_byte())")
    out.append("        }")
    out.append("        // Keep buf from growing unbounded.")
    out.append("        if bits == 0 {")
    out.append("          buf = 0")
    out.append("        } else {")
    out.append("          buf = buf & ((1 << bits) - 1)")
    out.append("        }")
    out.append("      }")
    out.append("    }")
    out.append("  }")
    out.append("  Bytes::from_array(out[:])")
    out.append("}")
    out.append("")
    out.append("fn inter_regular_ttf_b64() -> String {")
    out.append(f"  let sb = StringBuilder::new(size_hint={len(b64)})")
    for ch in chunks:
        out.append(f'  sb.write_string("{ch}")')
    out.append("  sb.to_string()")
    out.append("}")
    out.append("")
    out.append("///|")
    out.append("pub fn test_font_inter_regular_ttf() -> Bytes {")
    out.append("  decode_base64_ascii(inter_regular_ttf_b64())")
    out.append("}")
    out.append("")

    out_path.write_text("\n".join(out), encoding="utf-8")
    print(f"Wrote {out_path} ({out_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
