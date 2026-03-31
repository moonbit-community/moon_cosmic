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
fn mk_editor(text : String) -> Editor {
  let attrs_list = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(14.0, 20.0)).set_text(
    text,
    attrs_list,
    Advanced,
  )
  Editor::new(buffer)
}

///|
test "SyntaxSystem resolves themes and file extensions" {
  let syntax_system = SyntaxSystem::new()
  inspect(
    syntax_system.theme("base16-eighties.dark") is Some(_),
    content="true",
  )
  inspect(syntax_system.theme("missing-theme") is None, content="true")
  inspect(syntax_system.syntax_for_extension(".RS"), content="Some(\"rust\")")
  inspect(syntax_system.syntax_for_extension("py"), content="Some(\"python\")")
}

///|
test "SyntaxEditor highlights rust keyword and number spans" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("fn main() {\n  let x = 42\n}\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  let line1 = syntax_editor.editor().buffer().lines()[1]

  // "fn" should be styled as keyword (bold + keyword color).
  let keyword_attrs = line0.attrs_list().get_span(0)
  inspect(keyword_attrs.weight_value(), content="700")
  inspect(
    keyword_attrs.color_opt_value() == Some(theme.keyword),
    content="true",
  )

  // "42" should be highlighted as number.
  let number_attrs = line1.attrs_list().get_span(10)
  inspect(number_attrs.color_opt_value() == Some(theme.number), content="true")
}

///|
test "SyntaxEditor update_theme retints defaults" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("let value = 1\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor1 = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let before = syntax_editor1.foreground_color()
  let updated = syntax_editor1.update_theme("base16-ocean.light")
  inspect(updated.1, content="true")
  let syntax_editor2 = updated.0
  inspect(syntax_editor2.foreground_color() == before, content="false")
}

///|
test "SyntaxEditor syntax switch is lazy until rehighlight" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("fn main() {}\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let switched = syntax_editor0.syntax_by_extension("rs")
  let attrs_before = switched.editor().buffer().lines()[0]
    .attrs_list()
    .get_span(0)
  inspect(attrs_before.weight_value() == Weight::bold(), content="false")
  let attrs_after = switched.rehighlight().editor().buffer().lines()[0]
    .attrs_list()
    .get_span(0)
  inspect(attrs_after.weight_value(), content="700")
}

///|
test "SyntaxEditor handles nested Rust block comments across lines" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("/* a /* b */\nc */ let x = 1\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line1 = syntax_editor.editor().buffer().lines()[1]
  inspect(
    line1.attrs_list().get_span(0).color_opt_value() == Some(theme.comment),
    content="true",
  )
  inspect(
    line1.attrs_list().get_span(5).color_opt_value() == Some(theme.keyword),
    content="true",
  )
}

///|
test "SyntaxEditor tracks Python triple-quoted strings across lines" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("\"\"\"hello\nworld\"\"\"\nx = 1\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("py").rehighlight()
  let theme = syntax_editor.theme()
  let line1 = syntax_editor.editor().buffer().lines()[1]
  let line2 = syntax_editor.editor().buffer().lines()[2]
  inspect(
    line1.attrs_list().get_span(0).color_opt_value() == Some(theme.string_lit),
    content="true",
  )
  inspect(
    line2.attrs_list().get_span(0).color_opt_value() == Some(theme.string_lit),
    content="false",
  )
}

///|
test "SyntaxEditor tracks Rust raw strings across lines" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("let s = r###\"a\nb\"###;\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  let line1 = syntax_editor.editor().buffer().lines()[1]
  inspect(
    line0.attrs_list().get_span(8).color_opt_value() == Some(theme.string_lit),
    content="true",
  )
  inspect(
    line1.attrs_list().get_span(0).color_opt_value() == Some(theme.string_lit),
    content="true",
  )
  inspect(
    line1.attrs_list().get_span(5).color_opt_value() == Some(theme.string_lit),
    content="false",
  )
}

///|
test "SyntaxEditor keeps Rust unclosed plain strings line-local" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("\"abc\nlet x = 1\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line1 = syntax_editor.editor().buffer().lines()[1]
  inspect(
    line1.attrs_list().get_span(0).color_opt_value() == Some(theme.keyword),
    content="true",
  )
}

///|
test "SyntaxEditor highlights Python f-string prefix as string" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("f\"value {x}\"\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("py").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  inspect(
    line0.attrs_list().get_span(0).color_opt_value() == Some(theme.string_lit),
    content="true",
  )
}

///|
test "SyntaxEditor highlights Rust numeric prefixes and suffixes" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("let n = 0xffu8;\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  inspect(
    line0.attrs_list().get_span(8).color_opt_value() == Some(theme.number),
    content="true",
  )
  inspect(
    line0.attrs_list().get_span(14).color_opt_value() == Some(theme.number),
    content="false",
  )
}

///|
test "SyntaxEditor highlights Python scientific notation" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("x = 1e-6\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("py").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  inspect(
    line0.attrs_list().get_span(4).color_opt_value() == Some(theme.number),
    content="true",
  )
  inspect(
    line0.attrs_list().get_span(8).color_opt_value() == Some(theme.number),
    content="false",
  )
}

///|
test "SyntaxEditor updates token attrs lazily after edit actions" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("fn\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor1 = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor1.theme()
  inspect(
    syntax_editor1.editor().buffer().lines()[0]
    .attrs_list()
    .get_span(0)
    .color_opt_value() ==
    Some(theme.keyword),
    content="true",
  )
  let syntax_editor2 = syntax_editor1
    .set_cursor(Cursor::new(0, 0))
    .action(Insert('x'))
  inspect(
    syntax_editor2.editor().buffer().lines()[0]
    .attrs_list()
    .get_span(1)
    .color_opt_value() ==
    Some(theme.keyword),
    content="true",
  )
  inspect(
    syntax_editor2.rehighlight().editor().buffer().lines()[0]
    .attrs_list()
    .get_span(1)
    .color_opt_value() ==
    Some(theme.keyword),
    content="false",
  )
}

///|
test "SyntaxEditor treats Rust lifetimes as non-string tokens" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("fn f<'a>(x: &'a str) {}\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  inspect(
    line0.attrs_list().get_span(5).color_opt_value() == Some(theme.string_lit),
    content="false",
  )
  inspect(
    line0.attrs_list().get_span(14).color_opt_value() == Some(theme.string_lit),
    content="false",
  )
}

///|
test "SyntaxEditor treats Rust char literals as strings" {
  let syntax_system = SyntaxSystem::new()
  let editor = mk_editor("let c = 'x';\n")
  let syntax_editor0 = match
    SyntaxEditor::new(editor, syntax_system, "base16-eighties.dark") {
    Some(s) => s
    None => abort("theme should exist")
  }
  let syntax_editor = syntax_editor0.syntax_by_extension("rs").rehighlight()
  let theme = syntax_editor.theme()
  let line0 = syntax_editor.editor().buffer().lines()[0]
  inspect(
    line0.attrs_list().get_span(8).color_opt_value() == Some(theme.string_lit),
    content="true",
  )
}
