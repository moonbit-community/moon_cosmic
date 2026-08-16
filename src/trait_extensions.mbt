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
pub extend Color with Eq::{not_equal, equal}

///|
pub extend Color with Hash::{hash, hash_combine}

///|
pub extend Family with Eq::{not_equal, equal}

///|
pub extend Family with Hash::{hash, hash_combine}

///|
pub extend Family with Show::{to_string, output}

///|
pub extend CacheMetrics with Eq::{not_equal, equal}

///|
pub extend CacheMetrics with Hash::{hash, hash_combine}

///|
pub extend CacheMetrics with Show::{to_string, output}

///|
pub extend Weight with Eq::{not_equal, equal}

///|
pub extend Weight with Hash::{hash, hash_combine}

///|
pub extend Weight with Show::{to_string, output}

///|
pub extend FeatureTag with Eq::{not_equal, equal}

///|
pub extend FeatureTag with Hash::{hash, hash_combine}

///|
pub extend Feature with Eq::{not_equal, equal}

///|
pub extend Feature with Hash::{hash, hash_combine}

///|
pub extend FontFeatures with Eq::{not_equal, equal}

///|
pub extend FontFeatures with Hash::{hash, hash_combine}

///|
pub extend LetterSpacing with Eq::{not_equal, equal}

///|
pub extend LetterSpacing with Hash::{hash, hash_combine}

///|
pub extend UnderlineStyle with Eq::{not_equal, equal}

///|
pub extend UnderlineStyle with Hash::{hash, hash_combine}

///|
pub extend TextDecoration with Eq::{not_equal, equal}

///|
pub extend TextDecoration with Hash::{hash, hash_combine}

///|
pub extend DecorationMetrics with Eq::{not_equal, equal}

///|
pub extend DecorationMetrics with Hash::{hash, hash_combine}

///|
pub extend GlyphDecorationData with Eq::{not_equal, equal}

///|
pub extend GlyphDecorationData with Hash::{hash, hash_combine}

///|
pub extend Attrs with Eq::{not_equal, equal}

///|
pub extend Attrs with Hash::{hash, hash_combine}

///|
pub extend AttrsSpan with Eq::{not_equal, equal}

///|
pub extend AttrsSpan with Hash::{hash, hash_combine}

///|
pub extend AttrsList with Eq::{not_equal, equal}

///|
pub extend AttrsList with Hash::{hash, hash_combine}

///|
pub extend Affinity with Eq::{not_equal, equal}

///|
pub extend Cursor with Eq::{not_equal, equal}

///|
pub extend LayoutCursor with Eq::{not_equal, equal}

///|
pub extend Motion with Eq::{not_equal, equal}

///|
pub extend Selection with Eq::{not_equal, equal}

///|
pub extend Editor with Edit::{set_editor, editor}

///|
pub extend ViEditor with Edit::{
  start_change,
  copy_selection,
  finish_change,
  action,
  set_auto_indent,
  tab_width,
  selection,
  apply_change,
  cursor,
  set_cursor,
  insert_string,
  set_selection,
  set_tab_width,
  cursor_position,
  auto_indent,
  delete_selection,
  delete_range,
}

///|
pub extend FallbackProfile with Eq::{not_equal, equal}

///|
pub extend FontMatchAttrs with Eq::{not_equal, equal}

///|
pub extend FontMatchAttrs with Hash::{hash, hash_combine}

///|
pub extend SubpixelBin with Eq::{not_equal, equal}

///|
pub extend SubpixelBin with Hash::{hash, hash_combine}

///|
pub extend SubpixelBin with Show::{to_string, output}

///|
pub extend SubpixelBin with @debug.Debug::{to_repr}

///|
pub extend CacheKey with Eq::{not_equal, equal}

///|
pub extend CacheKey with Hash::{hash, hash_combine}

///|
pub extend CacheKey with Show::{to_string, output}

///|
pub extend LegacyRenderer with Renderer::{glyph, rectangle}

///|
pub extend ShapeRunKey with Eq::{not_equal, equal}

///|
pub extend ShapeRunKey with Hash::{hash, hash_combine}

///|
pub extend ShapeRunCache with Show::{to_string, output}

///|
pub extend LineState with Eq::{not_equal, equal}
