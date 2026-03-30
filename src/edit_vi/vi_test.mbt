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
fn mk_vi(text : String) -> ViEditor {
  let attrs_list = @cosmic.AttrsList::new(@cosmic.Attrs::new())
  let buffer = @cosmic.Buffer::new(@cosmic.Metrics::new(14.0, 20.0)).set_text(
    text,
    attrs_list,
    @cosmic.Advanced,
  )
  ViEditor::new(@cosmic.Editor::new(buffer))
}

///|
test "ViEditor insert mode edits and escapes to normal" {
  let vi = mk_vi("abc\n")
  let out = vi.feed_string("iX\u{1B}")
  inspect(out.mode() is Normal, content="true")
  inspect(out.editor().buffer().lines()[0].text(), content="Xabc")
}

///|
test "ViEditor dd deletes current line content" {
  let vi = mk_vi("abc\ndef\n")
  let out = vi.feed_string("dd")
  inspect(out.editor().buffer().lines()[0].text(), content="")
  inspect(out.editor().buffer().lines()[1].text(), content="def")
}

///|
test "ViEditor visual motions keep selection active" {
  let vi = mk_vi("abc def\n")
  let out = vi.feed_string("vw")
  inspect(out.mode() is Visual, content="true")
  inspect(
    out.editor().selection() is @cosmic.Selection::Normal(_),
    content="true",
  )
}

///|
test "ViEditor tracks changed state and undo/redo" {
  let vi0 = mk_vi("abc\n").save_point()
  inspect(vi0.changed(), content="false")
  let vi1 = vi0.feed_string("iX\u{1B}")
  inspect(vi1.changed(), content="true")
  inspect(vi1.editor().buffer().lines()[0].text(), content="Xabc")
  let vi2 = vi1.undo()
  inspect(vi2.editor().buffer().lines()[0].text(), content="abc")
  inspect(vi2.changed(), content="false")
  let vi3 = vi2.redo()
  inspect(vi3.editor().buffer().lines()[0].text(), content="Xabc")
}

///|
test "ViEditor supports / search and n/N navigation" {
  let vi0 = mk_vi("alpha beta alpha\n")
  let vi1 = vi0.feed_string("/alpha\n")
  inspect(vi1.editor().cursor().index, content="11")
  let vi2 = vi1.feed_string("N")
  inspect(vi2.editor().cursor().index, content="0")
}

///|
test "ViEditor supports f/F/t/T line-find motions" {
  let vi0 = mk_vi("abc def ghi\n")
  let vi1 = vi0.feed_string("f ")
  inspect(vi1.editor().cursor().index, content="3")
  let vi2 = vi0.feed_string("t ")
  inspect(vi2.editor().cursor().index, content="2")
  let vi3 = vi0.feed_string("$F ")
  inspect(vi3.editor().cursor().index, content="7")
  let vi4 = vi0.feed_string("$T ")
  inspect(vi4.editor().cursor().index, content="8")
}

///|
test "ViEditor supports yy and p register flow" {
  let vi0 = mk_vi("abc\ndef\n")
  let vi1 = vi0.feed_string("yyp")
  inspect(vi1.editor().buffer().lines()[0].text(), content="abc")
  inspect(vi1.editor().buffer().lines()[1].text(), content="abc")
  inspect(vi1.editor().buffer().lines()[2].text(), content="def")
}

///|
test "ViEditor supports diw and ciw text-objects" {
  let vi0 = mk_vi("abc def\n")
  let vi1 = vi0.feed_string("diw")
  inspect(vi1.editor().buffer().lines()[0].text(), content=" def")

  let vi2 = mk_vi("abc def\n").feed_string("ciwX\u{1B}")
  inspect(vi2.editor().buffer().lines()[0].text(), content="X def")
  inspect(vi2.mode() is Normal, content="true")
}

///|
test "ViEditor supports yiw register flow" {
  let vi0 = mk_vi("abc def\n")
  let vi1 = vi0.feed_string("yiwp")
  inspect(vi1.editor().buffer().lines()[0].text(), content="abcabc def")
}

///|
test "ViEditor supports di( text-object" {
  let vi0 = mk_vi("(abc) xyz\n")
  let vi1 = vi0.feed_string("ldi(")
  inspect(vi1.editor().buffer().lines()[0].text(), content="() xyz")
}
