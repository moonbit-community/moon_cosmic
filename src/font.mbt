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
/// Minimal font system wrapper for the MoonBit cosmic-text port.
///
/// Upstream `cosmic-text` uses `fontdb` for font discovery. In this MoonBit port
/// we start with an in-memory font list backed by `moon_swash`.
pub struct FontEntry {
  id : Int
  family_name : String
  font : @moon_swash.FontRef
}

///|
pub fn FontEntry::id(self : FontEntry) -> Int {
  self.id
}

///|
pub fn FontEntry::family_name(self : FontEntry) -> String {
  self.family_name
}

///|
pub fn FontEntry::font(self : FontEntry) -> @moon_swash.FontRef {
  self.font
}

///|
pub struct FontSystem {
  locale : String
  fonts : Array[FontEntry]
}

///|
pub fn FontSystem::new() -> FontSystem {
  FontSystem::new_with_locale("en-US")
}

///|
pub fn FontSystem::new_with_locale(locale : String) -> FontSystem {
  FontSystem::{ locale, fonts: [] }
}

///|
pub fn FontSystem::locale(self : FontSystem) -> String {
  self.locale
}

///|
pub fn FontSystem::fonts(self : FontSystem) -> Array[FontEntry] {
  self.fonts
}

///|
fn font_family_name(font : @moon_swash.FontRef, locale : String) -> String {
  let strings = font.localized_strings()
  match strings.find_by_id(@moon_swash.StringId::Family, Some(locale)) {
    Some(s) => s.to_string()
    None =>
      match strings.find_by_id(@moon_swash.StringId::Family, None) {
        Some(s) => s.to_string()
        None => ""
      }
  }
}

///|
/// Load font data (TTF/OTF/TTC bytes) into the system.
///
/// If the bytes do not parse as a font/collection, this is a no-op.
pub fn FontSystem::load_font_data(
  self : FontSystem,
  data : Bytes,
) -> FontSystem {
  match @moon_swash.FontDataRef::new(data) {
    None => self
    Some(data_ref) => {
      let locale = self.locale
      let fonts = self.fonts
      for f in data_ref.fonts() {
        let id = fonts.length()
        let family_name = font_family_name(f, locale)
        fonts.push(FontEntry::{ id, family_name, font: f })
      }
      FontSystem::{ ..self, fonts, }
    }
  }
}

///|
/// Find a font ID that matches the family selector (best-effort).
pub fn FontSystem::select_family(self : FontSystem, family : Family) -> Int? {
  match family {
    Name(name) => {
      for f in self.fonts {
        if f.family_name == name {
          return Some(f.id)
        }
      }
      None
    }
    Monospace => {
      for f in self.fonts {
        let metrics = f.font.metrics([])
        if metrics.is_monospace {
          return Some(f.id)
        }
      }
      None
    }
    _ => None
  }
}

///|
/// Resolve a font ID for the given attrs (best-effort).
pub fn FontSystem::resolve(self : FontSystem, attrs : Attrs) -> Int? {
  match self.select_family(attrs.family_value()) {
    Some(id) => Some(id)
    None => if self.fonts.length() > 0 { Some(0) } else { None }
  }
}

///|
pub fn FontSystem::get_font(
  self : FontSystem,
  font_id : Int,
) -> @moon_swash.FontRef? {
  if font_id < 0 || font_id >= self.fonts.length() {
    return None
  }
  Some(self.fonts[font_id].font)
}
