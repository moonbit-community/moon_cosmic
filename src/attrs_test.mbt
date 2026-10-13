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
test "AttrsList: add_span/get_span" {
  let defaults = @moon_cosmic.Attrs::new()
  let list0 = @moon_cosmic.AttrsList::new(defaults)
  inspect(list0.get_span(0).metadata(), content="0")
  let list1 = list0.add_span(0, 2, @moon_cosmic.Attrs::with_metadata(7))
  inspect(list1.get_span(0).metadata(), content="7")
  inspect(list1.get_span(1).metadata(), content="7")
  inspect(list1.get_span(2).metadata(), content="0")
}

///|
test "AttrsList: split_off shifts right spans" {
  let defaults = @moon_cosmic.Attrs::new()
  let list0 = @moon_cosmic.AttrsList::new(defaults)
    .add_span(1, 4, @moon_cosmic.Attrs::with_metadata(1))
    .add_span(5, 7, @moon_cosmic.Attrs::with_metadata(2))
  let (left, right) = list0.split_off(3)

  // left keeps [1,3)
  inspect(left.get_span(2).metadata(), content="1")
  inspect(left.get_span(3).metadata(), content="0")

  // right gets shifted: original [5,7) becomes [2,4)
  inspect(right.get_span(1).metadata(), content="0")
  inspect(right.get_span(2).metadata(), content="2")
  inspect(right.get_span(3).metadata(), content="2")
  inspect(right.get_span(4).metadata(), content="0")
}

///|
test "AttrsList: add_span overwrites overlap like RangeMap insert" {
  let defaults = @moon_cosmic.Attrs::new()
  let list = @moon_cosmic.AttrsList::new(defaults)
    .add_span(0, 5, @moon_cosmic.Attrs::with_metadata(1))
    .add_span(2, 4, @moon_cosmic.Attrs::with_metadata(2))
  inspect(list.get_span(0).metadata(), content="1")
  inspect(list.get_span(1).metadata(), content="1")
  inspect(list.get_span(2).metadata(), content="2")
  inspect(list.get_span(3).metadata(), content="2")
  inspect(list.get_span(4).metadata(), content="1")
  inspect(list.get_span(5).metadata(), content="0")
}

///|
test "AttrsList: add_span keeps right remainder and merges adjacent equals" {
  let defaults = @moon_cosmic.Attrs::new()
  let a1 = @moon_cosmic.Attrs::with_metadata(1)
  let list = @moon_cosmic.AttrsList::new(defaults)
    .add_span(0, 2, a1)
    .add_span(2, 4, a1)
    .add_span(1, 3, @moon_cosmic.Attrs::with_metadata(2))
  inspect(list.get_span(0).metadata(), content="1")
  inspect(list.get_span(1).metadata(), content="2")
  inspect(list.get_span(2).metadata(), content="2")
  inspect(list.get_span(3).metadata(), content="1")
  inspect(list.get_span(4).metadata(), content="0")
}

///|
test "Family/Weight constructors are usable" {
  ignore(@moon_cosmic.Family::Name("Inter"))
  ignore(@moon_cosmic.Family::Serif)
  ignore(@moon_cosmic.Family::SansSerif)
  ignore(@moon_cosmic.Family::Cursive)
  ignore(@moon_cosmic.Family::Fantasy)
  ignore(@moon_cosmic.Family::Monospace)
  ignore(@moon_cosmic.Family::SystemUi)
  ignore(@moon_cosmic.Family::UiSerif)
  ignore(@moon_cosmic.Family::UiSansSerif)
  ignore(@moon_cosmic.Family::UiMonospace)
  ignore(@moon_cosmic.Family::UiRounded)
  ignore(@moon_cosmic.Family::Emoji)
  ignore(@moon_cosmic.Family::Math)
  ignore(@moon_cosmic.Family::FangSong)
  ignore(@moon_cosmic.Weight::new(500))
  ignore(@moon_cosmic.Weight::normal())
  ignore(@moon_cosmic.Weight::bold())
  let attrs = @moon_cosmic.Attrs::new()
    .stretch(@moon_swash.Stretch::condensed())
    .style(Italic)
  debug_inspect(
    (attrs.stretch_value().is_condensed(), attrs.style_value().to_string()),
    content="(true, \"italic\")",
  )
}

///|
test "Attrs extended fields: color/cache-key/spacing/features/decoration" {
  let features = @moon_cosmic.FontFeatures::new()
    .enable(@moon_cosmic.FeatureTag::new("liga"))
    .set(@moon_cosmic.FeatureTag::new("kern"), 0U)
  let flags = @moon_cosmic.CACHE_KEY_FLAG_FAKE_ITALIC |
    @moon_cosmic.CACHE_KEY_FLAG_DISABLE_HINTING
  let attrs = @moon_cosmic.Attrs::new()
    .color(@moon_cosmic.Color::rgb(1, 2, 3))
    .cache_key_flags(flags)
    .letter_spacing(0.25F)
    .font_features(features)
    .underline(Double)
    .underline_color(@moon_cosmic.Color::rgb(8, 7, 6))
    .strikethrough()
    .overline()

  inspect(attrs.color_opt_value() is Some(_), content="true")
  inspect(attrs.cache_key_flags_value() == flags, content="true")
  inspect(attrs.font_features_value().features().length(), content="2")
  inspect(attrs.text_decoration_value().has_decoration(), content="true")
  inspect(attrs.text_decoration_value().underline == Double, content="true")
  inspect(
    attrs.compatible(
      @moon_cosmic.Attrs::new().color(@moon_cosmic.Color::rgb(255, 0, 0)),
    ),
    content="true",
  )

  match attrs.letter_spacing_opt() {
    Some(v) => inspect(v == 0.25F, content="true")
    None => fail("expected letter spacing")
  }
}
