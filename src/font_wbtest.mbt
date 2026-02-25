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
test "platform fallback family tables match reference profiles" {
  inspect(
    common_fallback_family_names(Unix),
    content="[\"Noto Sans\", \"DejaVu Sans\", \"FreeSans\", \"Noto Sans Mono\", \"DejaVu Sans Mono\", \"FreeMono\", \"Noto Sans Symbols\", \"Noto Sans Symbols2\", \"Noto Color Emoji\"]",
  )
  inspect(
    common_fallback_family_names(MacOS),
    content="[\".SF NS\", \"Menlo\", \"Apple Color Emoji\", \"Geneva\", \"Arial Unicode MS\"]",
  )
  inspect(
    common_fallback_family_names(Windows),
    content="[\"Segoe UI\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Segoe UI Historic\"]",
  )
  inspect(common_fallback_family_names(Other), content="[]")
  inspect(forbidden_fallback_family_names(Unix), content="[]")
  inspect(forbidden_fallback_family_names(MacOS), content="[\".LastResort\"]")
  inspect(forbidden_fallback_family_names(Windows), content="[]")
  inspect(forbidden_fallback_family_names(Other), content="[]")
}

///|
test "script fallback family tables are profile-specific" {
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", Unix),
    content="[\"Noto Sans Arabic\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", MacOS),
    content="[\"Geeza Pro\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Arabic, "en-US", Windows),
    content="[]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Unix),
    content="[\"Noto Sans CJK TC\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", MacOS),
    content="[\"PingFang TC\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Windows),
    content="[\"Microsoft JhengHei UI\"]",
  )
  inspect(
    script_fallback_family_names(@moon_swash.Script::Han, "zh-TW", Other),
    content="[]",
  )
}
