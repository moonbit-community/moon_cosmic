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
test "BidiParagraphs matches upstream fast path for ASCII (splits on \\n only)" {
  let ps = BidiParagraphs::new("a\nb\r\nc")
  let out = ps.iter().to_array()
  inspect(out, content="[\"a\", \"b\\r\", \"c\"]")
}

///|
test "BidiParagraphs splits on Unicode paragraph separators for non-ASCII text" {
  let ps = BidiParagraphs::new("a\u{2029}b")
  let out = ps.iter().to_array()
  inspect(out, content="[\"a\", \"b\"]")
}
