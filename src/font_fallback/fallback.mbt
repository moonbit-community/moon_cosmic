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
    Adlam => ["Noto Sans Adlam", "Noto Sans Adlam Unjoined"]
    Arabic => ["Noto Sans Arabic"]
    Armenian => ["Noto Sans Armenian"]
    Bengali => ["Noto Sans Bengali"]
    Bopomofo => han_unification_family_names(Unix, locale)
    Braille => ["FreeMono"]
    Buhid => ["Noto Sans Buhid"]
    Chakma => ["Noto Sans Chakma"]
    Cherokee => ["Noto Sans Cherokee"]
    Deseret => ["Noto Sans Deseret"]
    Devanagari => ["Noto Sans Devanagari"]
    Ethiopic => ["Noto Sans Ethiopic"]
    Georgian => ["Noto Sans Georgian"]
    Gothic => ["Noto Sans Gothic"]
    Grantha => ["Noto Sans Grantha"]
    Gujarati => ["Noto Sans Gujarati"]
    Gurmukhi => ["Noto Sans Gurmukhi"]
    Han => han_unification_family_names(Unix, locale)
    Hangul => han_unification_family_names(Unix, "ko")
    Hanunoo => ["Noto Sans Hanunoo"]
    Hebrew => ["Noto Sans Hebrew"]
    Hiragana => han_unification_family_names(Unix, "ja")
    Javanese => ["Noto Sans Javanese"]
    Kannada => ["Noto Sans Kannada"]
    Katakana => han_unification_family_names(Unix, "ja")
    Khmer => ["Noto Sans Khmer"]
    Lao => ["Noto Sans Lao"]
    Malayalam => ["Noto Sans Malayalam"]
    Mongolian => ["Noto Sans Mongolian"]
    Myanmar => ["Noto Sans Myanmar"]
    Oriya => ["Noto Sans Oriya"]
    Runic => ["Noto Sans Runic"]
    Sinhala => ["Noto Sans Sinhala"]
    Syriac => ["Noto Sans Syriac"]
    Tagalog => ["Noto Sans Tagalog"]
    Tagbanwa => ["Noto Sans Tagbanwa"]
    TaiLe => ["Noto Sans Tai Le"]
    TaiTham => ["Noto Sans Tai Tham"]
    TaiViet => ["Noto Sans Tai Viet"]
    Tamil => ["Noto Sans Tamil"]
    Telugu => ["Noto Sans Telugu"]
    Thaana => ["Noto Sans Thaana"]
    Thai => ["Noto Sans Thai"]
    Tibetan => ["Noto Serif Tibetan"]
    Tifinagh => ["Noto Sans Tifinagh"]
    Vai => ["Noto Sans Vai"]
    Yi => ["Noto Sans Yi", "Noto Sans CJK SC"]
    _ => []
  }
}

///|
fn script_fallback_family_names_macos(
  script : @moon_swash.Script,
  locale : String,
) -> Array[String] {
  match script {
    Adlam => ["Noto Sans Adlam"]
    Arabic => ["Geeza Pro"]
    Armenian => ["Noto Sans Armenian"]
    Bengali => ["Bangla Sangam MN"]
    Buhid => ["Noto Sans Buhid"]
    CanadianAboriginal => ["Euphemia UCAS"]
    Chakma => ["Noto Sans Chakma"]
    Devanagari => ["Devanagari Sangam MN"]
    Ethiopic => ["Kefa"]
    Gothic => ["Noto Sans Gothic"]
    Grantha => ["Grantha Sangam MN"]
    Gujarati => ["Gujarati Sangam MN"]
    Gurmukhi => ["Gurmukhi Sangam MN"]
    Han => han_unification_family_names(MacOS, locale)
    Hangul => han_unification_family_names(MacOS, "ko")
    Hanunoo => ["Noto Sans Hanunoo"]
    Hebrew => ["Arial"]
    Hiragana => han_unification_family_names(MacOS, "ja")
    Javanese => ["Noto Sans Javanese"]
    Kannada => ["Noto Sans Kannada"]
    Katakana => han_unification_family_names(MacOS, "ja")
    Khmer => ["Khmer Sangam MN"]
    Lao => ["Lao Sangam MN"]
    Malayalam => ["Malayalam Sangam MN"]
    Mongolian => ["Noto Sans Mongolian"]
    Myanmar => ["Noto Sans Myanmar"]
    Oriya => ["Noto Sans Oriya"]
    Sinhala => ["Sinhala Sangam MN"]
    Syriac => ["Noto Sans Syriac"]
    Tagalog => ["Noto Sans Tagalog"]
    Tagbanwa => ["Noto Sans Tagbanwa"]
    TaiLe => ["Noto Sans Tai Le"]
    TaiTham => ["Noto Sans Tai Tham"]
    TaiViet => ["Noto Sans Tai Viet"]
    Tamil => ["InaiMathi"]
    Telugu => ["Telugu Sangam MN"]
    Thaana => ["Noto Sans Thaana"]
    Thai => ["Ayuthaya"]
    Tibetan => ["Kailasa"]
    Tifinagh => ["Noto Sans Tifinagh"]
    Vai => ["Noto Sans Vai"]
    Yi => ["Noto Sans Yi", "PingFang SC"]
    _ => []
  }
}

///|
fn script_fallback_family_names_windows(
  script : @moon_swash.Script,
  locale : String,
) -> Array[String] {
  match script {
    Adlam => ["Ebrima"]
    Bengali => ["Nirmala UI"]
    CanadianAboriginal => ["Gadugi"]
    Chakma => ["Nirmala UI"]
    Cherokee => ["Gadugi"]
    Devanagari => ["Nirmala UI"]
    Ethiopic => ["Ebrima"]
    Gujarati => ["Nirmala UI"]
    Gurmukhi => ["Nirmala UI"]
    Han => han_unification_family_names(Windows, locale)
    Hangul => han_unification_family_names(Windows, "ko")
    Hiragana => han_unification_family_names(Windows, "ja")
    Javanese => ["Javanese Text"]
    Kannada => ["Nirmala UI"]
    Katakana => han_unification_family_names(Windows, "ja")
    Khmer => ["Leelawadee UI"]
    Lao => ["Leelawadee UI"]
    Malayalam => ["Nirmala UI"]
    Mongolian => ["Mongolian Baiti"]
    Myanmar => ["Myanmar Text"]
    Oriya => ["Nirmala UI"]
    Sinhala => ["Nirmala UI"]
    Tamil => ["Nirmala UI"]
    Telugu => ["Nirmala UI"]
    Thaana => ["MV Boli"]
    Thai => ["Leelawadee UI"]
    Tibetan => ["Microsoft Himalaya"]
    Tifinagh => ["Ebrima"]
    Vai => ["Ebrima"]
    Yi => ["Microsoft Yi Baiti"]
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
    Common | Inherited | Latin | Unknown => false
    _ => true
  }
}
