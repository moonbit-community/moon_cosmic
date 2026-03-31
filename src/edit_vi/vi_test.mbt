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
  inspect(out.editor().buffer().lines()[0].text(), content="def")
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
  inspect(vi1.editor().buffer().lines()[0].text(), content="abc abcdef")
}

///|
test "ViEditor supports di( text-object" {
  let vi0 = mk_vi("(abc) xyz\n")
  let vi1 = vi0.feed_string("ldi(")
  inspect(vi1.editor().buffer().lines()[0].text(), content="() xyz")
}

///|
test "ViEditor supports A and I insert-entry motions" {
  let vi1 = mk_vi("abc\n").feed_string("A!\u{1B}")
  inspect(vi1.editor().buffer().lines()[0].text(), content="abc!")
  inspect(vi1.mode() is Normal, content="true")

  let vi2 = mk_vi("abc\n").feed_string("I#\u{1B}")
  inspect(vi2.editor().buffer().lines()[0].text(), content="#abc")
  inspect(vi2.mode() is Normal, content="true")
}

///|
test "ViEditor supports o and O open-line commands" {
  let vi1 = mk_vi("abc\ndef\n").feed_string("joX\u{1B}")
  inspect(vi1.editor().buffer().lines()[0].text(), content="abc")
  inspect(vi1.editor().buffer().lines()[1].text(), content="def")
  inspect(vi1.editor().buffer().lines()[2].text(), content="X")

  let vi2 = mk_vi("abc\ndef\n").feed_string("jOY\u{1B}")
  inspect(vi2.editor().buffer().lines()[0].text(), content="abc")
  inspect(vi2.editor().buffer().lines()[1].text(), content="Y")
  inspect(vi2.editor().buffer().lines()[2].text(), content="def")
}

///|
test "ViEditor supports D C S and u/<C-r>" {
  let vi1 = mk_vi("abc def\n").feed_string("lD")
  inspect(vi1.editor().buffer().lines()[0].text(), content="a")

  let vi2 = mk_vi("abc def\n").feed_string("lCX\u{1B}")
  inspect(vi2.editor().buffer().lines()[0].text(), content="aX")
  inspect(vi2.mode() is Normal, content="true")

  let vi3 = mk_vi("abc\ndef\n").feed_string("Sx\u{1B}")
  inspect(vi3.editor().buffer().lines()[0].text(), content="x")

  let vi4 = mk_vi("abc\n").feed_string("iX\u{1B}u")
  inspect(vi4.editor().buffer().lines()[0].text(), content="abc")
  let vi5 = vi4.feed_string("\u{12}")
  inspect(vi5.editor().buffer().lines()[0].text(), content="Xabc")
}

///|
test "ViEditor supports ^ gg and G motions" {
  let vi1 = mk_vi("  abc\n").feed_string("$^")
  inspect(vi1.editor().cursor().index, content="2")

  let vi2 = mk_vi("a\nb\nc\n").feed_string("G")
  inspect(vi2.editor().cursor().line, content="3")

  let vi3 = mk_vi("a\nb\nc\n").feed_string("Ggg")
  inspect(vi3.editor().cursor().line, content="0")
}

///|
test "ViEditor supports named registers with quote prefix" {
  let out = mk_vi("abc\ndef\n").feed_string("\"ayyj\"ap")
  inspect(out.editor().buffer().lines()[0].text(), content="abc")
  inspect(out.editor().buffer().lines()[1].text(), content="def")
  inspect(out.editor().buffer().lines()[2].text(), content="abc")
}

///|
test "ViEditor supports linewise P put-before" {
  let out = mk_vi("abc\ndef\n").feed_string("yyjP")
  inspect(out.editor().buffer().lines()[0].text(), content="abc")
  inspect(out.editor().buffer().lines()[1].text(), content="abc")
  inspect(out.editor().buffer().lines()[2].text(), content="def")
}

///|
test "ViEditor stores D deletions into unnamed register" {
  let out = mk_vi("abc def\n").feed_string("lDp")
  inspect(out.register_opt, content="Some(\"bc def\")")
  inspect(out.editor().buffer().lines()[0].text(), content="abc def")
}

///|
test "ViEditor supports numeric count for motions and G" {
  let vi1 = mk_vi("a b c d\n").feed_string("2w")
  inspect(vi1.editor().cursor().index, content="3")

  let vi2 = mk_vi("a\nb\nc\nd\n").feed_string("3G")
  inspect(vi2.editor().cursor().line, content="2")
}

///|
test "ViEditor supports numeric count for dd and p" {
  let vi1 = mk_vi("a\nb\nc\nd\n").feed_string("2dd")
  inspect(vi1.editor().buffer().lines()[0].text(), content="c")
  inspect(vi1.register_opt, content="Some(\"a\\nb\\n\")")

  let vi2 = mk_vi("abc\n").feed_string("yiw3p")
  inspect(vi2.editor().buffer().lines()[0].text(), content="abcabcabcabc")
}

///|
test "ViEditor supports backward search with ?" {
  let vi = mk_vi("alpha beta alpha\n").feed_string("$?alpha\n")
  inspect(vi.editor().cursor().index, content="11")
}

///|
test "ViEditor supports ; and , to repeat/reverse find" {
  let vi1 = mk_vi("a b c d\n").feed_string("f ;")
  inspect(vi1.editor().cursor().index, content="3")
  let vi2 = vi1.feed_string(",")
  inspect(vi2.editor().cursor().index, content="1")
}

///|
test "ViEditor supports r R X s commands" {
  let vi1 = mk_vi("abc\n").feed_string("lrZ")
  inspect(vi1.editor().buffer().lines()[0].text(), content="aZc")

  let vi2 = mk_vi("abc\n").feed_string("lRXY\u{1B}")
  inspect(vi2.editor().buffer().lines()[0].text(), content="aXY")

  let vi3 = mk_vi("abc\n").feed_string("lX")
  inspect(vi3.editor().buffer().lines()[0].text(), content="bc")

  let vi4 = mk_vi("abc\n").feed_string("2sZ\u{1B}")
  inspect(vi4.editor().buffer().lines()[0].text(), content="Zc")
}

///|
test "ViEditor supports Y and shift operators" {
  let vi1 = mk_vi("a\nb\nc\n").feed_string("2Yp")
  inspect(vi1.register_opt, content="Some(\"a\\nb\\n\")")
  inspect(vi1.editor().buffer().lines()[0].text(), content="a")
  inspect(vi1.editor().buffer().lines()[1].text(), content="a")
  inspect(vi1.editor().buffer().lines()[2].text(), content="b")
  inspect(vi1.editor().buffer().lines()[3].text(), content="b")

  let vi2 = mk_vi("a\n").feed_string(">>")
  inspect(vi2.editor().buffer().lines()[0].text(), content="        a")
  let vi3 = vi2.feed_string("<<")
  inspect(vi3.editor().buffer().lines()[0].text(), content="a")
}
