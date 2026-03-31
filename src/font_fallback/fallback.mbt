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
pub(all) enum FallbackProfile {
  Unix
  MacOS
  Windows
  Other
}

///|
#cfg(target="native")
pub fn platform_default_fallback_profile() -> FallbackProfile {
  // Project scope: native path targets macOS fallback behavior by default.
  MacOS
}

///|
#cfg(not(target="native"))
pub fn platform_default_fallback_profile() -> FallbackProfile {
  Other
}

///|
pub fn detect_fallback_profile(
  _family_names : Array[String],
) -> FallbackProfile {
  // Kept for compatibility with old call sites; behavior now matches explicit
  // platform defaults instead of runtime font-name heuristics.
  platform_default_fallback_profile()
}

///|
pub fn forbidden_fallback_family_names(
  profile : FallbackProfile,
) -> Array[String] {
  match profile {
    MacOS => [".LastResort"]
    _ => []
  }
}

///|
pub fn common_fallback_family_names(profile : FallbackProfile) -> Array[String] {
  match profile {
    Unix =>
      [
        "Noto Sans", "DejaVu Sans", "FreeSans", "Noto Sans Mono", "DejaVu Sans Mono",
        "FreeMono", "Noto Sans Symbols", "Noto Sans Symbols2", "Noto Color Emoji",
      ]
    MacOS =>
      [".SF NS", "Menlo", "Apple Color Emoji", "Geneva", "Arial Unicode MS"]
    Windows =>
      ["Segoe UI", "Segoe UI Emoji", "Segoe UI Symbol", "Segoe UI Historic"]
    Other => []
  }
}

///|
fn han_unification_family_names(
  profile : FallbackProfile,
  locale : String,
) -> Array[String] {
  match profile {
    Unix =>
      if locale == "ja" {
        ["Noto Sans CJK JP"]
      } else if locale == "ko" {
        ["Noto Sans CJK KR"]
      } else if locale == "zh-HK" {
        ["Noto Sans CJK HK"]
      } else if locale == "zh-TW" {
        ["Noto Sans CJK TC"]
      } else {
        ["Noto Sans CJK SC"]
      }
    MacOS =>
      if locale == "ja" {
        ["Hiragino Sans"]
      } else if locale == "ko" {
        ["Apple SD Gothic Neo"]
      } else if locale == "zh-HK" {
        ["PingFang HK"]
      } else if locale == "zh-TW" {
        ["PingFang TC"]
      } else {
        ["PingFang SC"]
      }
    Windows =>
      if locale == "ja" {
        ["Yu Gothic"]
      } else if locale == "ko" {
        ["Malgun Gothic"]
      } else if locale == "zh-HK" {
        ["MingLiU_HKSCS"]
      } else if locale == "zh-TW" {
        ["Microsoft JhengHei UI"]
      } else {
        ["Microsoft YaHei UI"]
      }
    Other => []
  }
}

///|
fn script_fallback_family_names_unix(
  script : @moon_swash.Script,
  locale : String,
) -> Array[String] {
  match script {
    @moon_swash.Script::Adlam => ["Noto Sans Adlam", "Noto Sans Adlam Unjoined"]
    @moon_swash.Script::Arabic => ["Noto Sans Arabic"]
    @moon_swash.Script::Armenian => ["Noto Sans Armenian"]
    @moon_swash.Script::Bengali => ["Noto Sans Bengali"]
    @moon_swash.Script::Bopomofo => han_unification_family_names(Unix, locale)
    @moon_swash.Script::Braille => ["FreeMono"]
    @moon_swash.Script::Buhid => ["Noto Sans Buhid"]
    @moon_swash.Script::Chakma => ["Noto Sans Chakma"]
    @moon_swash.Script::Cherokee => ["Noto Sans Cherokee"]
    @moon_swash.Script::Deseret => ["Noto Sans Deseret"]
    @moon_swash.Script::Devanagari => ["Noto Sans Devanagari"]
    @moon_swash.Script::Ethiopic => ["Noto Sans Ethiopic"]
    @moon_swash.Script::Georgian => ["Noto Sans Georgian"]
    @moon_swash.Script::Gothic => ["Noto Sans Gothic"]
    @moon_swash.Script::Grantha => ["Noto Sans Grantha"]
    @moon_swash.Script::Gujarati => ["Noto Sans Gujarati"]
    @moon_swash.Script::Gurmukhi => ["Noto Sans Gurmukhi"]
    @moon_swash.Script::Han => han_unification_family_names(Unix, locale)
    @moon_swash.Script::Hangul => han_unification_family_names(Unix, "ko")
    @moon_swash.Script::Hanunoo => ["Noto Sans Hanunoo"]
    @moon_swash.Script::Hebrew => ["Noto Sans Hebrew"]
    @moon_swash.Script::Hiragana => han_unification_family_names(Unix, "ja")
    @moon_swash.Script::Javanese => ["Noto Sans Javanese"]
    @moon_swash.Script::Kannada => ["Noto Sans Kannada"]
    @moon_swash.Script::Katakana => han_unification_family_names(Unix, "ja")
    @moon_swash.Script::Khmer => ["Noto Sans Khmer"]
    @moon_swash.Script::Lao => ["Noto Sans Lao"]
    @moon_swash.Script::Malayalam => ["Noto Sans Malayalam"]
    @moon_swash.Script::Mongolian => ["Noto Sans Mongolian"]
    @moon_swash.Script::Myanmar => ["Noto Sans Myanmar"]
    @moon_swash.Script::Oriya => ["Noto Sans Oriya"]
    @moon_swash.Script::Runic => ["Noto Sans Runic"]
    @moon_swash.Script::Sinhala => ["Noto Sans Sinhala"]
    @moon_swash.Script::Syriac => ["Noto Sans Syriac"]
    @moon_swash.Script::Tagalog => ["Noto Sans Tagalog"]
    @moon_swash.Script::Tagbanwa => ["Noto Sans Tagbanwa"]
    @moon_swash.Script::TaiLe => ["Noto Sans Tai Le"]
    @moon_swash.Script::TaiTham => ["Noto Sans Tai Tham"]
    @moon_swash.Script::TaiViet => ["Noto Sans Tai Viet"]
    @moon_swash.Script::Tamil => ["Noto Sans Tamil"]
    @moon_swash.Script::Telugu => ["Noto Sans Telugu"]
    @moon_swash.Script::Thaana => ["Noto Sans Thaana"]
    @moon_swash.Script::Thai => ["Noto Sans Thai"]
    @moon_swash.Script::Tibetan => ["Noto Serif Tibetan"]
    @moon_swash.Script::Tifinagh => ["Noto Sans Tifinagh"]
    @moon_swash.Script::Vai => ["Noto Sans Vai"]
    @moon_swash.Script::Yi => ["Noto Sans Yi", "Noto Sans CJK SC"]
    _ => []
  }
}

///|
fn script_fallback_family_names_macos(
  script : @moon_swash.Script,
  locale : String,
) -> Array[String] {
  match script {
    @moon_swash.Script::Adlam => ["Noto Sans Adlam"]
    @moon_swash.Script::Arabic => ["Geeza Pro"]
    @moon_swash.Script::Armenian => ["Noto Sans Armenian"]
    @moon_swash.Script::Bengali => ["Bangla Sangam MN"]
    @moon_swash.Script::Buhid => ["Noto Sans Buhid"]
    @moon_swash.Script::CanadianAboriginal => ["Euphemia UCAS"]
    @moon_swash.Script::Chakma => ["Noto Sans Chakma"]
    @moon_swash.Script::Devanagari => ["Devanagari Sangam MN"]
    @moon_swash.Script::Ethiopic => ["Kefa"]
    @moon_swash.Script::Gothic => ["Noto Sans Gothic"]
    @moon_swash.Script::Grantha => ["Grantha Sangam MN"]
    @moon_swash.Script::Gujarati => ["Gujarati Sangam MN"]
    @moon_swash.Script::Gurmukhi => ["Gurmukhi Sangam MN"]
    @moon_swash.Script::Han => han_unification_family_names(MacOS, locale)
    @moon_swash.Script::Hangul => han_unification_family_names(MacOS, "ko")
    @moon_swash.Script::Hanunoo => ["Noto Sans Hanunoo"]
    @moon_swash.Script::Hebrew => ["Arial"]
    @moon_swash.Script::Hiragana => han_unification_family_names(MacOS, "ja")
    @moon_swash.Script::Javanese => ["Noto Sans Javanese"]
    @moon_swash.Script::Kannada => ["Noto Sans Kannada"]
    @moon_swash.Script::Katakana => han_unification_family_names(MacOS, "ja")
    @moon_swash.Script::Khmer => ["Khmer Sangam MN"]
    @moon_swash.Script::Lao => ["Lao Sangam MN"]
    @moon_swash.Script::Malayalam => ["Malayalam Sangam MN"]
    @moon_swash.Script::Mongolian => ["Noto Sans Mongolian"]
    @moon_swash.Script::Myanmar => ["Noto Sans Myanmar"]
    @moon_swash.Script::Oriya => ["Noto Sans Oriya"]
    @moon_swash.Script::Sinhala => ["Sinhala Sangam MN"]
    @moon_swash.Script::Syriac => ["Noto Sans Syriac"]
    @moon_swash.Script::Tagalog => ["Noto Sans Tagalog"]
    @moon_swash.Script::Tagbanwa => ["Noto Sans Tagbanwa"]
    @moon_swash.Script::TaiLe => ["Noto Sans Tai Le"]
    @moon_swash.Script::TaiTham => ["Noto Sans Tai Tham"]
    @moon_swash.Script::TaiViet => ["Noto Sans Tai Viet"]
    @moon_swash.Script::Tamil => ["InaiMathi"]
    @moon_swash.Script::Telugu => ["Telugu Sangam MN"]
    @moon_swash.Script::Thaana => ["Noto Sans Thaana"]
    @moon_swash.Script::Thai => ["Ayuthaya"]
    @moon_swash.Script::Tibetan => ["Kailasa"]
    @moon_swash.Script::Tifinagh => ["Noto Sans Tifinagh"]
    @moon_swash.Script::Vai => ["Noto Sans Vai"]
    @moon_swash.Script::Yi => ["Noto Sans Yi", "PingFang SC"]
    _ => []
  }
}

///|
fn script_fallback_family_names_windows(
  script : @moon_swash.Script,
  locale : String,
) -> Array[String] {
  match script {
    @moon_swash.Script::Adlam => ["Ebrima"]
    @moon_swash.Script::Bengali => ["Nirmala UI"]
    @moon_swash.Script::CanadianAboriginal => ["Gadugi"]
    @moon_swash.Script::Chakma => ["Nirmala UI"]
    @moon_swash.Script::Cherokee => ["Gadugi"]
    @moon_swash.Script::Devanagari => ["Nirmala UI"]
    @moon_swash.Script::Ethiopic => ["Ebrima"]
    @moon_swash.Script::Gujarati => ["Nirmala UI"]
    @moon_swash.Script::Gurmukhi => ["Nirmala UI"]
    @moon_swash.Script::Han => han_unification_family_names(Windows, locale)
    @moon_swash.Script::Hangul => han_unification_family_names(Windows, "ko")
    @moon_swash.Script::Hiragana => han_unification_family_names(Windows, "ja")
    @moon_swash.Script::Javanese => ["Javanese Text"]
    @moon_swash.Script::Kannada => ["Nirmala UI"]
    @moon_swash.Script::Katakana => han_unification_family_names(Windows, "ja")
    @moon_swash.Script::Khmer => ["Leelawadee UI"]
    @moon_swash.Script::Lao => ["Leelawadee UI"]
    @moon_swash.Script::Malayalam => ["Nirmala UI"]
    @moon_swash.Script::Mongolian => ["Mongolian Baiti"]
    @moon_swash.Script::Myanmar => ["Myanmar Text"]
    @moon_swash.Script::Oriya => ["Nirmala UI"]
    @moon_swash.Script::Sinhala => ["Nirmala UI"]
    @moon_swash.Script::Tamil => ["Nirmala UI"]
    @moon_swash.Script::Telugu => ["Nirmala UI"]
    @moon_swash.Script::Thaana => ["MV Boli"]
    @moon_swash.Script::Thai => ["Leelawadee UI"]
    @moon_swash.Script::Tibetan => ["Microsoft Himalaya"]
    @moon_swash.Script::Tifinagh => ["Ebrima"]
    @moon_swash.Script::Vai => ["Ebrima"]
    @moon_swash.Script::Yi => ["Microsoft Yi Baiti"]
    _ => []
  }
}

///|
pub fn script_fallback_family_names(
  script : @moon_swash.Script,
  locale : String,
  profile : FallbackProfile,
) -> Array[String] {
  match profile {
    Unix => script_fallback_family_names_unix(script, locale)
    MacOS => script_fallback_family_names_macos(script, locale)
    Windows => script_fallback_family_names_windows(script, locale)
    Other => []
  }
}

///|
pub fn script_uses_fallback_stage(script : @moon_swash.Script) -> Bool {
  match script {
    @moon_swash.Script::Common
    | @moon_swash.Script::Inherited
    | @moon_swash.Script::Latin
    | @moon_swash.Script::Unknown => false
    _ => true
  }
}
