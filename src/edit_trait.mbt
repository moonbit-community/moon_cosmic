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
/// Shared editable surface for `Editor`/`SyntaxEditor`/`ViEditor`.
pub(open) trait Edit {
  editor(Self) -> Editor
  set_editor(Self, Editor) -> Self
  cursor(Self) -> Cursor
  set_cursor(Self, Cursor) -> Self
  selection(Self) -> Selection
  set_selection(Self, Selection) -> Self
  auto_indent(Self) -> Bool
  set_auto_indent(Self, Bool) -> Self
  tab_width(Self) -> Int
  set_tab_width(Self, Int) -> Self
  start_change(Self) -> Self
  finish_change(Self) -> (Self, Change?)
  copy_selection(Self) -> String?
  delete_selection(Self) -> (Self, Bool)
  delete_range(Self, Cursor, Cursor) -> Self
  insert_string(Self, String, AttrsList?) -> Self
  apply_change(Self, Change) -> (Self, Bool)
  cursor_position(Self) -> (Int, Int)?
  action(Self, Action) -> Self
}

///|
pub impl Edit for Editor with editor(self) {
  self
}

///|
pub impl Edit for Editor with set_editor(_self, editor) {
  editor
}

///|
pub impl Edit for Editor with cursor(self) {
  self.cursor()
}

///|
pub impl Edit for Editor with set_cursor(self, cursor) {
  self.set_cursor(cursor)
}

///|
pub impl Edit for Editor with selection(self) {
  self.selection()
}

///|
pub impl Edit for Editor with set_selection(self, selection) {
  self.set_selection(selection)
}

///|
pub impl Edit for Editor with auto_indent(self) {
  self.auto_indent()
}

///|
pub impl Edit for Editor with set_auto_indent(self, auto_indent) {
  self.set_auto_indent(auto_indent)
}

///|
pub impl Edit for Editor with tab_width(self) {
  self.tab_width()
}

///|
pub impl Edit for Editor with set_tab_width(self, tab_width) {
  self.set_tab_width(tab_width)
}

///|
pub impl Edit for Editor with start_change(self) {
  self.start_change()
}

///|
pub impl Edit for Editor with finish_change(self) {
  self.finish_change()
}

///|
pub impl Edit for Editor with copy_selection(self) {
  self.copy_selection()
}

///|
pub impl Edit for Editor with delete_selection(self) {
  self.delete_selection()
}

///|
pub impl Edit for Editor with delete_range(self, start, end) {
  self.delete_range(start, end)
}

///|
pub impl Edit for Editor with insert_string(self, data, attrs_list_opt) {
  self.insert_string(data, attrs_list_opt)
}

///|
pub impl Edit for Editor with apply_change(self, change) {
  self.apply_change(change)
}

///|
pub impl Edit for Editor with cursor_position(self) {
  self.cursor_position()
}

///|
pub impl Edit for Editor with action(self, action) {
  self.action(action)
}

///|
pub impl Edit for SyntaxEditor with editor(self) {
  self.editor()
}

///|
pub impl Edit for SyntaxEditor with set_editor(self, editor) {
  self.set_editor(editor)
}

///|
pub impl Edit for SyntaxEditor with cursor(self) {
  self.cursor()
}

///|
pub impl Edit for SyntaxEditor with set_cursor(self, cursor) {
  self.set_cursor(cursor)
}

///|
pub impl Edit for SyntaxEditor with selection(self) {
  self.selection()
}

///|
pub impl Edit for SyntaxEditor with set_selection(self, selection) {
  self.set_selection(selection)
}

///|
pub impl Edit for SyntaxEditor with auto_indent(self) {
  self.auto_indent()
}

///|
pub impl Edit for SyntaxEditor with set_auto_indent(self, auto_indent) {
  self.set_auto_indent(auto_indent)
}

///|
pub impl Edit for SyntaxEditor with tab_width(self) {
  self.tab_width()
}

///|
pub impl Edit for SyntaxEditor with set_tab_width(self, tab_width) {
  self.set_tab_width(tab_width)
}

///|
pub impl Edit for SyntaxEditor with start_change(self) {
  self.start_change()
}

///|
pub impl Edit for SyntaxEditor with finish_change(self) {
  self.finish_change()
}

///|
pub impl Edit for SyntaxEditor with copy_selection(self) {
  self.copy_selection()
}

///|
pub impl Edit for SyntaxEditor with delete_selection(self) {
  self.delete_selection()
}

///|
pub impl Edit for SyntaxEditor with delete_range(self, start, end) {
  self.delete_range(start, end)
}

///|
pub impl Edit for SyntaxEditor with insert_string(self, data, attrs_list_opt) {
  self.insert_string(data, attrs_list_opt)
}

///|
pub impl Edit for SyntaxEditor with apply_change(self, change) {
  self.apply_change(change)
}

///|
pub impl Edit for SyntaxEditor with cursor_position(self) {
  self.cursor_position()
}

///|
pub impl Edit for SyntaxEditor with action(self, action) {
  self.action(action)
}

///|
pub impl Edit for ViEditor with editor(self) {
  self.editor()
}

///|
pub impl Edit for ViEditor with set_editor(self, editor) {
  self.set_editor(editor)
}

///|
pub impl Edit for ViEditor with cursor(self) {
  self.editor().cursor()
}

///|
pub impl Edit for ViEditor with set_cursor(self, cursor) {
  self.set_editor(self.editor().set_cursor(cursor))
}

///|
pub impl Edit for ViEditor with selection(self) {
  self.editor().selection()
}

///|
pub impl Edit for ViEditor with set_selection(self, selection) {
  self.set_editor(self.editor().set_selection(selection))
}

///|
pub impl Edit for ViEditor with auto_indent(self) {
  self.editor().auto_indent()
}

///|
pub impl Edit for ViEditor with set_auto_indent(self, auto_indent) {
  self.set_editor(self.editor().set_auto_indent(auto_indent))
}

///|
pub impl Edit for ViEditor with tab_width(self) {
  self.editor().tab_width()
}

///|
pub impl Edit for ViEditor with set_tab_width(self, tab_width) {
  self.set_editor(self.editor().set_tab_width(tab_width))
}

///|
pub impl Edit for ViEditor with start_change(self) {
  self.set_editor(self.editor().start_change())
}

///|
pub impl Edit for ViEditor with finish_change(self) {
  let finished = self.editor().finish_change()
  (self.set_editor(finished.0), finished.1)
}

///|
pub impl Edit for ViEditor with copy_selection(self) {
  self.editor().copy_selection()
}

///|
pub impl Edit for ViEditor with delete_selection(self) {
  let deleted = self.editor().delete_selection()
  (self.set_editor(deleted.0), deleted.1)
}

///|
pub impl Edit for ViEditor with delete_range(self, start, end) {
  self.set_editor(self.editor().delete_range(start, end))
}

///|
pub impl Edit for ViEditor with insert_string(self, data, attrs_list_opt) {
  self.set_editor(self.editor().insert_string(data, attrs_list_opt))
}

///|
pub impl Edit for ViEditor with apply_change(self, change) {
  let applied = self.editor().apply_change(change)
  (self.set_editor(applied.0), applied.1)
}

///|
pub impl Edit for ViEditor with cursor_position(self) {
  self.editor().cursor_position()
}

///|
pub impl Edit for ViEditor with action(self, action) {
  self.set_editor(self.editor().action(action))
}
