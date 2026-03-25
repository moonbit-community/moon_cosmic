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
/// Core text attributes ported from `cosmic-text/src/attrs.rs`.

///|
/// Text color (ARGB packed, aligned with upstream).
pub struct Color {
  value : UInt
}

///|
pub impl Eq for Color with equal(self, other) {
  self.value == other.value
}

///|
pub impl Hash for Color with hash_combine(self, hasher) {
  hasher.combine_uint(self.value)
}

///|
pub fn Color::rgba(r : Byte, g : Byte, b : Byte, a : Byte) -> Color {
  let av = a.to_int().reinterpret_as_uint()
  let rv = r.to_int().reinterpret_as_uint()
  let gv = g.to_int().reinterpret_as_uint()
  let bv = b.to_int().reinterpret_as_uint()
  Color::{ value: (av << 24) | (rv << 16) | (gv << 8) | bv }
}

///|
pub fn Color::rgb(r : Byte, g : Byte, b : Byte) -> Color {
  Color::rgba(r, g, b, 0xFF)
}

///|
pub fn Color::r(self : Color) -> Byte {
  ((self.value & 0x00FF0000) >> 16).reinterpret_as_int().to_byte()
}

///|
pub fn Color::g(self : Color) -> Byte {
  ((self.value & 0x0000FF00) >> 8).reinterpret_as_int().to_byte()
}

///|
pub fn Color::b(self : Color) -> Byte {
  (self.value & 0x000000FF).reinterpret_as_int().to_byte()
}

///|
pub fn Color::a(self : Color) -> Byte {
  ((self.value & 0xFF000000) >> 24).reinterpret_as_int().to_byte()
}

///|
pub fn Color::as_rgba(self : Color) -> (Byte, Byte, Byte, Byte) {
  (self.r(), self.g(), self.b(), self.a())
}

///|
/// Font family selector.
///
/// This mirrors the generic families exposed by `cosmic-text` and extends them
/// with the CSS/Bevy generic families required by modern text stacks.
pub(all) enum Family {
  Name(String)
  Serif
  SansSerif
  Cursive
  Fantasy
  Monospace
  SystemUi
  UiSerif
  UiSansSerif
  UiMonospace
  UiRounded
  Emoji
  Math
  FangSong
}

///|
pub impl Eq for Family with equal(self, other) {
  match (self, other) {
    (Name(a), Name(b)) => a == b
    (Serif, Serif) => true
    (SansSerif, SansSerif) => true
    (Cursive, Cursive) => true
    (Fantasy, Fantasy) => true
    (Monospace, Monospace) => true
    (SystemUi, SystemUi) => true
    (UiSerif, UiSerif) => true
    (UiSansSerif, UiSansSerif) => true
    (UiMonospace, UiMonospace) => true
    (UiRounded, UiRounded) => true
    (Emoji, Emoji) => true
    (Math, Math) => true
    (FangSong, FangSong) => true
    _ => false
  }
}

///|
pub impl Hash for Family with hash_combine(self, hasher) {
  match self {
    Name(name) => {
      hasher.combine_int(0)
      hasher.combine_string(name)
    }
    Serif => hasher.combine_int(1)
    SansSerif => hasher.combine_int(2)
    Cursive => hasher.combine_int(3)
    Fantasy => hasher.combine_int(4)
    Monospace => hasher.combine_int(5)
    SystemUi => hasher.combine_int(6)
    UiSerif => hasher.combine_int(7)
    UiSansSerif => hasher.combine_int(8)
    UiMonospace => hasher.combine_int(9)
    UiRounded => hasher.combine_int(10)
    Emoji => hasher.combine_int(11)
    Math => hasher.combine_int(12)
    FangSong => hasher.combine_int(13)
  }
}

///|
pub impl Show for Family with output(self, logger) {
  match self {
    Name(name) => {
      logger.write_string("Name(\"")
      logger.write_string(name)
      logger.write_string("\")")
    }
    Serif => logger.write_string("Serif")
    SansSerif => logger.write_string("SansSerif")
    Cursive => logger.write_string("Cursive")
    Fantasy => logger.write_string("Fantasy")
    Monospace => logger.write_string("Monospace")
    SystemUi => logger.write_string("SystemUi")
    UiSerif => logger.write_string("UiSerif")
    UiSansSerif => logger.write_string("UiSansSerif")
    UiMonospace => logger.write_string("UiMonospace")
    UiRounded => logger.write_string("UiRounded")
    Emoji => logger.write_string("Emoji")
    Math => logger.write_string("Math")
    FangSong => logger.write_string("FangSong")
  }
}

///|
/// Font weight (1..=1000). This is a simplified stand-in for `fontdb::Weight`.
pub struct Weight {
  value : Int

  fn new(value : Int) -> Weight
}

///|
/// Metrics, but implementing Eq and Hash using u32 representation of f32.
///
/// This mirrors upstream `cosmic-text` CacheMetrics, enabling per-span metrics
/// overrides (font size / line height) while keeping Attrs hashable.
pub struct CacheMetrics {
  font_size_bits : UInt
  line_height_bits : UInt
}

///|
fn attrs_u32_from_be_bytes(b : Bytes) -> UInt {
  let b0 = if b.get(0) is Some(v) { v } else { 0x00 }
  let b1 = if b.get(1) is Some(v) { v } else { 0x00 }
  let b2 = if b.get(2) is Some(v) { v } else { 0x00 }
  let b3 = if b.get(3) is Some(v) { v } else { 0x00 }
  let u0 = b0.to_int().reinterpret_as_uint()
  let u1 = b1.to_int().reinterpret_as_uint()
  let u2 = b2.to_int().reinterpret_as_uint()
  let u3 = b3.to_int().reinterpret_as_uint()
  (u0 << 24) | (u1 << 16) | (u2 << 8) | u3
}

///|
fn attrs_f32_from_bits(bits : UInt) -> Float {
  Float::reinterpret_from_uint(bits)
}

///|
fn float_to_bits(v : Float) -> UInt {
  attrs_u32_from_be_bytes(Float::to_be_bytes(v))
}

///|
pub fn CacheMetrics::from_metrics(metrics : Metrics) -> CacheMetrics {
  CacheMetrics::{
    font_size_bits: float_to_bits(metrics.font_size),
    line_height_bits: float_to_bits(metrics.line_height),
  }
}

///|
pub fn CacheMetrics::to_metrics(self : CacheMetrics) -> Metrics {
  Metrics::new(
    attrs_f32_from_bits(self.font_size_bits),
    attrs_f32_from_bits(self.line_height_bits),
  )
}

///|
pub fn CacheMetrics::font_size(self : CacheMetrics) -> Float {
  attrs_f32_from_bits(self.font_size_bits)
}

///|
pub fn CacheMetrics::line_height(self : CacheMetrics) -> Float {
  attrs_f32_from_bits(self.line_height_bits)
}

///|
pub impl Eq for CacheMetrics with equal(self, other) {
  self.font_size_bits == other.font_size_bits &&
  self.line_height_bits == other.line_height_bits
}

///|
pub impl Hash for CacheMetrics with hash_combine(self, hasher) {
  hasher.combine_uint(self.font_size_bits)
  hasher.combine_uint(self.line_height_bits)
}

///|
pub impl Show for CacheMetrics with output(self, logger) {
  logger.write_string("CacheMetrics{font_size_bits=")
  logger.write_string(self.font_size_bits.to_string())
  logger.write_string(", line_height_bits=")
  logger.write_string(self.line_height_bits.to_string())
  logger.write_string("}")
}

///|
pub fn Weight::new(value : Int) -> Weight {
  Weight::{ value, }
}

///|
pub fn Weight::normal() -> Weight {
  Weight::new(400)
}

///|
pub fn Weight::bold() -> Weight {
  Weight::new(700)
}

///|
pub fn Weight::value(self : Weight) -> Int {
  self.value
}

///|
pub impl Eq for Weight with equal(self, other) {
  self.value == other.value
}

///|
pub impl Hash for Weight with hash_combine(self, hasher) {
  hasher.combine_int(self.value)
}

///|
pub impl Show for Weight with output(self, logger) {
  logger.write_string(self.value.to_string())
}

///|
pub struct FeatureTag {
  value : UInt

  fn new(tag : String) -> FeatureTag
}

///|
pub fn FeatureTag::new(tag : String) -> FeatureTag {
  FeatureTag::{ value: @moon_swash.tag_from_str_lossy(tag) }
}

///|
pub fn FeatureTag::from_tag(tag : UInt) -> FeatureTag {
  FeatureTag::{ value: tag }
}

///|
pub fn FeatureTag::as_tag(self : FeatureTag) -> UInt {
  self.value
}

///|
pub impl Eq for FeatureTag with equal(self, other) {
  self.value == other.value
}

///|
pub impl Hash for FeatureTag with hash_combine(self, hasher) {
  hasher.combine_uint(self.value)
}

///|
pub struct Feature {
  tag : FeatureTag
  value : UInt

  fn new(tag : FeatureTag, value : UInt) -> Feature
}

///|
pub fn Feature::new(tag : FeatureTag, value : UInt) -> Feature {
  Feature::{ tag, value }
}

///|
pub fn Feature::tag(self : Feature) -> FeatureTag {
  self.tag
}

///|
pub fn Feature::value(self : Feature) -> UInt {
  self.value
}

///|
pub impl Eq for Feature with equal(self, other) {
  self.tag == other.tag && self.value == other.value
}

///|
pub impl Hash for Feature with hash_combine(self, hasher) {
  self.tag.hash_combine(hasher)
  hasher.combine_uint(self.value)
}

///|
pub struct FontFeatures {
  features : Array[Feature]

  fn new() -> FontFeatures
}

///|
pub fn FontFeatures::new() -> FontFeatures {
  FontFeatures::{ features: [] }
}

///|
pub fn FontFeatures::features(self : FontFeatures) -> Array[Feature] {
  self.features
}

///|
pub fn FontFeatures::set(
  self : FontFeatures,
  tag : FeatureTag,
  value : UInt,
) -> FontFeatures {
  let features = self.features
  features.push(Feature::new(tag, value))
  FontFeatures::{ features, }
}

///|
pub fn FontFeatures::enable(
  self : FontFeatures,
  tag : FeatureTag,
) -> FontFeatures {
  self.set(tag, 1U)
}

///|
pub fn FontFeatures::disable(
  self : FontFeatures,
  tag : FeatureTag,
) -> FontFeatures {
  self.set(tag, 0U)
}

///|
pub impl Eq for FontFeatures with equal(self, other) {
  if self.features.length() != other.features.length() {
    return false
  }
  for i in 0..<self.features.length() {
    if self.features[i] != other.features[i] {
      return false
    }
  }
  true
}

///|
pub impl Hash for FontFeatures with hash_combine(self, hasher) {
  hasher.combine_int(self.features.length())
  for feature in self.features {
    feature.hash_combine(hasher)
  }
}

///|
pub struct LetterSpacing {
  bits : UInt

  fn new(value : Float) -> LetterSpacing
}

///|
fn letter_spacing_is_nan(bits : UInt) -> Bool {
  (bits & 0x7F800000U) == 0x7F800000U && (bits & 0x007FFFFFU) != 0U
}

///|
fn normalize_letter_spacing_bits(value : Float) -> UInt {
  let bits = float_to_bits(value)
  if letter_spacing_is_nan(bits) {
    0x7FC00000U
  } else if bits == 0x80000000U {
    0U
  } else {
    bits
  }
}

///|
pub fn LetterSpacing::new(value : Float) -> LetterSpacing {
  LetterSpacing::{ bits: normalize_letter_spacing_bits(value) }
}

///|
pub fn LetterSpacing::value(self : LetterSpacing) -> Float {
  attrs_f32_from_bits(self.bits)
}

///|
pub impl Eq for LetterSpacing with equal(self, other) {
  self.bits == other.bits
}

///|
pub impl Hash for LetterSpacing with hash_combine(self, hasher) {
  hasher.combine_uint(self.bits)
}

///|
pub(all) enum UnderlineStyle {
  None
  Single
  Double
}

///|
pub impl Eq for UnderlineStyle with equal(self, other) {
  match (self, other) {
    (None, None) => true
    (Single, Single) => true
    (Double, Double) => true
    _ => false
  }
}

///|
pub impl Hash for UnderlineStyle with hash_combine(self, hasher) {
  match self {
    None => hasher.combine_int(0)
    Single => hasher.combine_int(1)
    Double => hasher.combine_int(2)
  }
}

///|
pub struct TextDecoration {
  underline : UnderlineStyle
  underline_color_opt : Color?
  strikethrough : Bool
  strikethrough_color_opt : Color?
  overline : Bool
  overline_color_opt : Color?

  fn new() -> TextDecoration
}

///|
pub fn TextDecoration::new() -> TextDecoration {
  TextDecoration::{
    underline: UnderlineStyle::None,
    underline_color_opt: None,
    strikethrough: false,
    strikethrough_color_opt: None,
    overline: false,
    overline_color_opt: None,
  }
}

///|
pub fn TextDecoration::has_decoration(self : TextDecoration) -> Bool {
  self.underline != UnderlineStyle::None || self.strikethrough || self.overline
}

///|
pub impl Eq for TextDecoration with equal(self, other) {
  self.underline == other.underline &&
  self.underline_color_opt == other.underline_color_opt &&
  self.strikethrough == other.strikethrough &&
  self.strikethrough_color_opt == other.strikethrough_color_opt &&
  self.overline == other.overline &&
  self.overline_color_opt == other.overline_color_opt
}

///|
pub impl Hash for TextDecoration with hash_combine(self, hasher) {
  self.underline.hash_combine(hasher)
  match self.underline_color_opt {
    None => hasher.combine_int(0)
    Some(color) => {
      hasher.combine_int(1)
      color.hash_combine(hasher)
    }
  }
  hasher.combine_int(if self.strikethrough { 1 } else { 0 })
  match self.strikethrough_color_opt {
    None => hasher.combine_int(0)
    Some(color) => {
      hasher.combine_int(1)
      color.hash_combine(hasher)
    }
  }
  hasher.combine_int(if self.overline { 1 } else { 0 })
  match self.overline_color_opt {
    None => hasher.combine_int(0)
    Some(color) => {
      hasher.combine_int(1)
      color.hash_combine(hasher)
    }
  }
}

///|
pub struct DecorationMetrics {
  offset : Float
  thickness : Float

  fn new(offset : Float, thickness : Float) -> DecorationMetrics
}

///|
pub fn DecorationMetrics::new(
  offset : Float,
  thickness : Float,
) -> DecorationMetrics {
  DecorationMetrics::{ offset, thickness }
}

///|
pub impl Eq for DecorationMetrics with equal(self, other) {
  self.offset == other.offset && self.thickness == other.thickness
}

///|
pub impl Hash for DecorationMetrics with hash_combine(self, hasher) {
  hasher.combine_uint(float_to_bits(self.offset))
  hasher.combine_uint(float_to_bits(self.thickness))
}

///|
pub struct GlyphDecorationData {
  text_decoration : TextDecoration
  underline_metrics : DecorationMetrics
  strikethrough_metrics : DecorationMetrics
  ascent : Float
}

///|
pub impl Eq for GlyphDecorationData with equal(self, other) {
  self.text_decoration == other.text_decoration &&
  self.underline_metrics == other.underline_metrics &&
  self.strikethrough_metrics == other.strikethrough_metrics &&
  self.ascent == other.ascent
}

///|
pub impl Hash for GlyphDecorationData with hash_combine(self, hasher) {
  self.text_decoration.hash_combine(hasher)
  self.underline_metrics.hash_combine(hasher)
  self.strikethrough_metrics.hash_combine(hasher)
  hasher.combine_uint(float_to_bits(self.ascent))
}

///|
pub struct Attrs {
  color_opt : Color?
  metadata : Int
  family : Family
  weight : Weight
  stretch : @moon_swash.Stretch
  style : @moon_swash.Style
  cache_key_flags : CacheKeyFlags
  metrics_opt : CacheMetrics?
  letter_spacing_opt : LetterSpacing?
  font_features : FontFeatures
  text_decoration : TextDecoration

  fn new() -> Attrs
}

///|
pub fn Attrs::new() -> Attrs {
  Attrs::with_metadata(0)
}

///|
pub fn Attrs::with_metadata(metadata : Int) -> Attrs {
  Attrs::{
    color_opt: None,
    metadata,
    family: Family::SansSerif,
    weight: Weight::normal(),
    stretch: @moon_swash.Stretch::normal(),
    style: @moon_swash.Style::Normal,
    cache_key_flags: 0U,
    metrics_opt: None,
    letter_spacing_opt: None,
    font_features: FontFeatures::new(),
    text_decoration: TextDecoration::new(),
  }
}

///|
pub fn Attrs::metadata(self : Attrs) -> Int {
  self.metadata
}

///|
pub fn Attrs::color(self : Attrs, color : Color) -> Attrs {
  Attrs::{ ..self, color_opt: Some(color) }
}

///|
pub fn Attrs::family(self : Attrs, family : Family) -> Attrs {
  Attrs::{ ..self, family, }
}

///|
pub fn Attrs::weight(self : Attrs, weight : Weight) -> Attrs {
  Attrs::{ ..self, weight, }
}

///|
pub fn Attrs::stretch(self : Attrs, stretch : @moon_swash.Stretch) -> Attrs {
  Attrs::{ ..self, stretch, }
}

///|
pub fn Attrs::style(self : Attrs, style : @moon_swash.Style) -> Attrs {
  Attrs::{ ..self, style, }
}

///|
pub fn Attrs::cache_key_flags(
  self : Attrs,
  cache_key_flags : CacheKeyFlags,
) -> Attrs {
  Attrs::{ ..self, cache_key_flags, }
}

///|
/// Set Metrics, overriding values in Buffer for this span.
pub fn Attrs::metrics(self : Attrs, metrics : Metrics) -> Attrs {
  Attrs::{ ..self, metrics_opt: Some(CacheMetrics::from_metrics(metrics)) }
}

///|
pub fn Attrs::letter_spacing(self : Attrs, letter_spacing : Float) -> Attrs {
  Attrs::{
    ..self,
    letter_spacing_opt: Some(LetterSpacing::new(letter_spacing)),
  }
}

///|
pub fn Attrs::font_features(
  self : Attrs,
  font_features : FontFeatures,
) -> Attrs {
  Attrs::{ ..self, font_features, }
}

///|
pub fn Attrs::text_decoration(
  self : Attrs,
  text_decoration : TextDecoration,
) -> Attrs {
  Attrs::{ ..self, text_decoration, }
}

///|
pub fn Attrs::underline(self : Attrs, style : UnderlineStyle) -> Attrs {
  let td = TextDecoration::{ ..self.text_decoration, underline: style }
  Attrs::{ ..self, text_decoration: td }
}

///|
pub fn Attrs::underline_color(self : Attrs, color : Color) -> Attrs {
  let td = TextDecoration::{
    ..self.text_decoration,
    underline_color_opt: Some(color),
  }
  Attrs::{ ..self, text_decoration: td }
}

///|
pub fn Attrs::strikethrough(self : Attrs) -> Attrs {
  let td = TextDecoration::{ ..self.text_decoration, strikethrough: true }
  Attrs::{ ..self, text_decoration: td }
}

///|
pub fn Attrs::strikethrough_color(self : Attrs, color : Color) -> Attrs {
  let td = TextDecoration::{
    ..self.text_decoration,
    strikethrough_color_opt: Some(color),
  }
  Attrs::{ ..self, text_decoration: td }
}

///|
pub fn Attrs::overline(self : Attrs) -> Attrs {
  let td = TextDecoration::{ ..self.text_decoration, overline: true }
  Attrs::{ ..self, text_decoration: td }
}

///|
pub fn Attrs::overline_color(self : Attrs, color : Color) -> Attrs {
  let td = TextDecoration::{
    ..self.text_decoration,
    overline_color_opt: Some(color),
  }
  Attrs::{ ..self, text_decoration: td }
}

///|
/// Return optional Metrics override.
pub fn Attrs::metrics_opt(self : Attrs) -> Metrics? {
  match self.metrics_opt {
    Option::None => Option::None
    Option::Some(cm) => Option::Some(cm.to_metrics())
  }
}

///|
pub fn Attrs::family_value(self : Attrs) -> Family {
  self.family
}

///|
pub fn Attrs::weight_value(self : Attrs) -> Weight {
  self.weight
}

///|
pub fn Attrs::stretch_value(self : Attrs) -> @moon_swash.Stretch {
  self.stretch
}

///|
pub fn Attrs::style_value(self : Attrs) -> @moon_swash.Style {
  self.style
}

///|
pub fn Attrs::color_opt_value(self : Attrs) -> Color? {
  self.color_opt
}

///|
pub fn Attrs::cache_key_flags_value(self : Attrs) -> CacheKeyFlags {
  self.cache_key_flags
}

///|
pub fn Attrs::letter_spacing_opt(self : Attrs) -> Float? {
  match self.letter_spacing_opt {
    None => None
    Some(ls) => Some(ls.value())
  }
}

///|
pub fn Attrs::font_features_value(self : Attrs) -> FontFeatures {
  self.font_features
}

///|
pub fn Attrs::text_decoration_value(self : Attrs) -> TextDecoration {
  self.text_decoration
}

///|
pub fn Attrs::compatible(self : Attrs, other : Attrs) -> Bool {
  self.family == other.family &&
  self.stretch == other.stretch &&
  self.style == other.style &&
  self.weight == other.weight
}

///|
pub impl Eq for Attrs with equal(self, other) {
  self.color_opt == other.color_opt &&
  self.metadata == other.metadata &&
  self.family == other.family &&
  self.weight == other.weight &&
  self.stretch == other.stretch &&
  self.style == other.style &&
  self.cache_key_flags == other.cache_key_flags &&
  self.metrics_opt == other.metrics_opt &&
  self.letter_spacing_opt == other.letter_spacing_opt &&
  self.font_features == other.font_features &&
  self.text_decoration == other.text_decoration
}

///|
pub impl Hash for Attrs with hash_combine(self, hasher) {
  match self.color_opt {
    None => hasher.combine_int(0)
    Some(color) => {
      hasher.combine_int(1)
      color.hash_combine(hasher)
    }
  }
  hasher.combine_int(self.metadata)
  self.family.hash_combine(hasher)
  self.weight.hash_combine(hasher)
  hasher.combine_int(self.stretch.raw().to_int())
  hasher.combine_string(self.style.to_string())
  hasher.combine_uint(self.cache_key_flags)
  match self.metrics_opt {
    Option::None => hasher.combine_int(0)
    Option::Some(cm) => {
      hasher.combine_int(1)
      cm.hash_combine(hasher)
    }
  }
  match self.letter_spacing_opt {
    None => hasher.combine_int(0)
    Some(letter_spacing) => {
      hasher.combine_int(1)
      letter_spacing.hash_combine(hasher)
    }
  }
  self.font_features.hash_combine(hasher)
  self.text_decoration.hash_combine(hasher)
}

///|
pub struct AttrsSpan {
  start : Int
  end : Int
  attrs : Attrs
}

///|
pub impl Eq for AttrsSpan with equal(self, other) {
  self.start == other.start &&
  self.end == other.end &&
  self.attrs == other.attrs
}

///|
pub impl Hash for AttrsSpan with hash_combine(self, hasher) {
  hasher.combine_int(self.start)
  hasher.combine_int(self.end)
  self.attrs.hash_combine(hasher)
}

///|
pub struct AttrsList {
  defaults : Attrs
  spans : Array[AttrsSpan]

  fn new(defaults : Attrs) -> AttrsList
}

///|
pub fn AttrsList::new(defaults : Attrs) -> AttrsList {
  AttrsList::{ defaults, spans: [] }
}

///|
pub fn AttrsList::defaults(self : AttrsList) -> Attrs {
  self.defaults
}

///|
pub fn AttrsList::spans_iter(self : AttrsList) -> Array[AttrsSpan] {
  self.spans
}

///|
pub impl Eq for AttrsList with equal(self, other) {
  if self.defaults != other.defaults ||
    self.spans.length() != other.spans.length() {
    return false
  }
  for i in 0..<self.spans.length() {
    if self.spans[i] != other.spans[i] {
      return false
    }
  }
  true
}

///|
pub impl Hash for AttrsList with hash_combine(self, hasher) {
  self.defaults.hash_combine(hasher)
  hasher.combine_int(self.spans.length())
  for s in self.spans {
    s.hash_combine(hasher)
  }
}

///|
fn merge_adjacent_spans(spans : Array[AttrsSpan]) -> Array[AttrsSpan] {
  if spans.length() <= 1 {
    return spans
  }
  let merged : Array[AttrsSpan] = []
  for span in spans {
    if merged.length() == 0 {
      merged.push(span)
      continue
    }
    let last = merged[merged.length() - 1]
    if last.end == span.start && last.attrs == span.attrs {
      merged.set(merged.length() - 1, AttrsSpan::{
        start: last.start,
        end: span.end,
        attrs: last.attrs,
      })
    } else {
      merged.push(span)
    }
  }
  merged
}

///|
pub fn AttrsList::add_span(
  self : AttrsList,
  start : Int,
  end : Int,
  attrs : Attrs,
) -> AttrsList {
  if end <= start {
    return self
  }

  // Align with RangeMap insert semantics:
  // new span overwrites overlapping ranges and preserves non-overlapping pieces.
  let spans0 : Array[AttrsSpan] = []
  let mut inserted = false
  for span in self.spans {
    // Fully before new range.
    if span.end <= start {
      spans0.push(span)
      continue
    }
    // Fully after new range.
    if span.start >= end {
      if !inserted {
        spans0.push(AttrsSpan::{ start, end, attrs })
        inserted = true
      }
      spans0.push(span)
      continue
    }
    // Overlap: keep left remainder.
    if span.start < start {
      spans0.push(AttrsSpan::{
        start: span.start,
        end: start,
        attrs: span.attrs,
      })
    }
    // Overlap with right remainder means this old span crosses `end`.
    if span.end > end {
      if !inserted {
        spans0.push(AttrsSpan::{ start, end, attrs })
        inserted = true
      }
      spans0.push(AttrsSpan::{ start: end, end: span.end, attrs: span.attrs })
    }
  }
  if !inserted {
    spans0.push(AttrsSpan::{ start, end, attrs })
  }
  let spans = merge_adjacent_spans(spans0)
  AttrsList::{ ..self, spans, }
}

///|
pub fn AttrsList::get_span(self : AttrsList, pos : Int) -> Attrs {
  let mut found : Attrs? = None
  for span in self.spans {
    if pos >= span.start && pos < span.end {
      found = Some(span.attrs)
    }
  }
  if found is Some(attrs) {
    attrs
  } else {
    self.defaults
  }
}

///|
fn clamp_nonneg(v : Int) -> Int {
  if v < 0 {
    0
  } else {
    v
  }
}

///|
/// Splits spans at `index` and returns (left, right).
pub fn AttrsList::split_off(
  self : AttrsList,
  index : Int,
) -> (AttrsList, AttrsList) {
  let index = clamp_nonneg(index)
  let left : Array[AttrsSpan] = []
  let right : Array[AttrsSpan] = []
  for span in self.spans {
    if span.end <= index {
      left.push(span)
    } else if span.start >= index {
      right.push(AttrsSpan::{
        start: span.start - index,
        end: span.end - index,
        attrs: span.attrs,
      })
    } else {
      // Span crosses the split point.
      left.push(AttrsSpan::{ start: span.start, end: index, attrs: span.attrs })
      right.push(AttrsSpan::{
        start: 0,
        end: span.end - index,
        attrs: span.attrs,
      })
    }
  }
  (
    AttrsList::{ defaults: self.defaults, spans: left },
    AttrsList::{ defaults: self.defaults, spans: right },
  )
}

///|
pub fn AttrsList::eq(self : AttrsList, other : AttrsList) -> Bool {
  if !self.defaults.equal(other.defaults) {
    return false
  }
  if self.spans.length() != other.spans.length() {
    return false
  }
  let n = self.spans.length()
  for i in 0..<n {
    let a = self.spans[i]
    let b = other.spans[i]
    if a.start != b.start || a.end != b.end || !a.attrs.equal(b.attrs) {
      return false
    }
  }
  true
}
