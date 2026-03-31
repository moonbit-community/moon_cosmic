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
fn mk_edit_trait_editor(text : String) -> Editor {
  let attrs_list = AttrsList::new(Attrs::new())
  let buffer = Buffer::new(Metrics::new(14.0, 20.0)).set_text(
    text,
    attrs_list,
    Advanced,
  )
  Editor::new(buffer)
}

///|
fn[E : Edit] edit_move_right(editor : E) -> E {
  editor.action(Action::Motion(Right))
}

///|
test "Edit trait action works for Editor SyntaxEditor and ViEditor" {
  let editor = mk_edit_trait_editor("ab\n")
  let editor2 = edit_move_right(editor)
  inspect(editor2.cursor().index, content="1")

  let syntax_system = SyntaxSystem::new()
  let syntax_editor0 = match
    SyntaxEditor::new(
      mk_edit_trait_editor("ab\n"),
      syntax_system,
      "base16-eighties.dark",
    ) {
    Some(v) => v
    None => abort("theme should exist")
  }
  let syntax_editor = edit_move_right(syntax_editor0)
  inspect(syntax_editor.cursor().index, content="1")

  let vi_editor = edit_move_right(ViEditor::new(mk_edit_trait_editor("ab\n")))
  inspect(vi_editor.editor().cursor().index, content="1")
}
