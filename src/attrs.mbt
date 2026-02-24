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
/// MVP subset ported from `cosmic-text/src/attrs.rs`.
///
/// NOTE: upstream `Attrs` contains font family/style/weight/features etc.
/// We start with `metadata` only to support BufferLine behavior tests, and will
/// extend it incrementally to match upstream.

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
/// Font family selector (mirrors `fontdb::Family` in cosmic-text).
pub(all) enum Family {
  Name(String)
  Serif
  SansSerif
  Cursive
  Fantasy
  Monospace
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
  }
}

///|
/// Font weight (1..=1000). This is a simplified stand-in for `fontdb::Weight`.
pub struct Weight {
  value : Int
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
pub struct Attrs {
  metadata : Int
  family : Family
  weight : Weight
  stretch : @moon_swash.Stretch
  style : @moon_swash.Style
  metrics_opt : CacheMetrics?
}

///|
pub fn Attrs::new() -> Attrs {
  Attrs::with_metadata(0)
}

///|
pub fn Attrs::with_metadata(metadata : Int) -> Attrs {
  Attrs::{
    metadata,
    family: Family::SansSerif,
    weight: Weight::normal(),
    stretch: @moon_swash.Stretch::normal(),
    style: @moon_swash.Style::Normal,
    metrics_opt: None,
  }
}

///|
pub fn Attrs::metadata(self : Attrs) -> Int {
  self.metadata
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
/// Set Metrics, overriding values in Buffer for this span.
pub fn Attrs::metrics(self : Attrs, metrics : Metrics) -> Attrs {
  Attrs::{ ..self, metrics_opt: Some(CacheMetrics::from_metrics(metrics)) }
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
pub impl Eq for Attrs with equal(self, other) {
  self.metadata == other.metadata &&
  self.family == other.family &&
  self.weight == other.weight &&
  self.stretch == other.stretch &&
  self.style == other.style &&
  self.metrics_opt == other.metrics_opt
}

///|
pub impl Hash for Attrs with hash_combine(self, hasher) {
  hasher.combine_int(self.metadata)
  self.family.hash_combine(hasher)
  self.weight.hash_combine(hasher)
  hasher.combine_int(self.stretch.raw().to_int())
  hasher.combine_string(self.style.to_string())
  match self.metrics_opt {
    Option::None => hasher.combine_int(0)
    Option::Some(cm) => {
      hasher.combine_int(1)
      cm.hash_combine(hasher)
    }
  }
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
pub fn AttrsList::add_span(
  self : AttrsList,
  start : Int,
  end : Int,
  attrs : Attrs,
) -> AttrsList {
  if end <= start {
    return self
  }
  // MVP: keep a sorted array by `start` (stable), no merging yet.
  let spans : Array[AttrsSpan] = []
  let mut inserted = false
  for span in self.spans {
    if !inserted && start < span.start {
      spans.push(AttrsSpan::{ start, end, attrs })
      inserted = true
    }
    spans.push(span)
  }
  if !inserted {
    spans.push(AttrsSpan::{ start, end, attrs })
  }
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
