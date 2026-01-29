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
/// Minimal shaping port scaffold from `cosmic-text/src/shape.rs`.
///
/// This MVP produces 1 glyph per UTF-16 code unit and does not perform script runs,
/// harfbuzz shaping, BiDi, or font fallback.
pub(all) enum Shaping {
  Basic
  Advanced
}

///|
pub struct ShapeGlyph {
  start : Int
  end : Int
  x_advance : Float
  x_offset : Float
  font_id : Int
  glyph_id : Int
  metadata : Int
}

///|
pub struct ShapeLine {
  rtl : Bool
  glyphs : Array[ShapeGlyph]
}

///|
pub fn ShapeLine::empty() -> ShapeLine {
  ShapeLine::{ rtl: false, glyphs: [] }
}

///|
fn is_tab(code : Int) -> Bool {
  code == 9
}

///|
fn bidi_is_strong_rtl(b : @moon_swash.BidiClass) -> Bool {
  match b {
    R | AL | AN | RLE | RLO | RLI => true
    _ => false
  }
}

///|
fn bidi_is_strong_ltr(b : @moon_swash.BidiClass) -> Bool {
  match b {
    L | LRE | LRO | LRI => true
    _ => false
  }
}

///|
fn detect_base_rtl(text : String) -> Bool {
  // Heuristic: use the first strong directional character.
  for ch in text {
    let props = @moon_swash.CharInfo::from_char(ch).properties()
    let bidi = props.bidi_class()
    if bidi_is_strong_rtl(bidi) {
      return true
    }
    if bidi_is_strong_ltr(bidi) {
      return false
    }
  }
  false
}

///|
fn code_unit_to_uint(code : UInt16) -> UInt {
  code.to_int().reinterpret_as_uint()
}

///|
fn glyph_advance_em(
  font : @moon_swash.FontRef,
  glyph_id : UInt16,
  upem : Double,
) -> Float {
  let gm = font.glyph_metrics([])
  let adv = gm.advance_width(glyph_id) / upem
  Float::from_double(adv)
}

///|
/// Build a shaped line from text and attributes list.
///
/// MVP notes:
/// - 1 code unit -> 1 glyph
/// - `glyph_id` is the code unit value
/// - `x_advance` is measured in "cells": 1.0 for normal chars, `tab_width` for tab.
pub fn ShapeLine::build(
  _self : ShapeLine,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  let rtl = shaping is Advanced && detect_base_rtl(text)
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let code = text.code_unit_at(i).to_int()
    let advance = if is_tab(code) {
      Float::from_double(tab_width.to_double())
    } else {
      1.0F
    }
    let attrs = attrs_list.get_span(i)
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance: advance,
      x_offset: 0.0F,
      font_id: 0,
      glyph_id: code,
      metadata: attrs.metadata(),
    })
  }
  ShapeLine::{ rtl, glyphs }
}

///|
/// Build a shaped line using a FontSystem (best-effort).
///
/// Current behavior is still "Basic shaping" (1 UTF-16 code unit -> 1 glyph),
/// but uses `moon_swash` charmap + glyph metrics so advances are font-derived.
pub fn ShapeLine::build_with_font_system(
  _self : ShapeLine,
  font_system : FontSystem,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  _tab_width : Int,
) -> ShapeLine {
  if shaping is Basic {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      _tab_width,
    )
  }
  let rtl = detect_base_rtl(text)
  let font_id_opt = font_system.resolve(attrs_list.defaults())
  let font_id = match font_id_opt {
    None =>
      return ShapeLine::build(
        ShapeLine::empty(),
        text,
        attrs_list,
        shaping,
        _tab_width,
      )
    Some(id) => id
  }
  let font_opt = font_system.get_font(font_id)
  let font = match font_opt {
    None =>
      return ShapeLine::build(
        ShapeLine::empty(),
        text,
        attrs_list,
        shaping,
        _tab_width,
      )
    Some(f) => f
  }
  let metrics = font.metrics([])
  let upem = metrics.units_per_em.to_int().to_double()
  let cmap = @moon_swash.Charmap::from_font(font)

  // Tabs are shaped as spaces (upstream behavior).
  let space_gid = cmap.map(32U)
  let space_adv = glyph_advance_em(font, space_gid, upem)
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let cu = text.code_unit_at(i)
    let code = cu.to_int()
    let attrs = attrs_list.get_span(i)
    let (glyph_id, x_advance) = if is_tab(code) {
      (space_gid, space_adv)
    } else {
      let gid = cmap.map(code_unit_to_uint(cu))
      let adv = glyph_advance_em(font, gid, upem)
      (gid, adv)
    }
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance,
      x_offset: 0.0F,
      font_id,
      glyph_id: glyph_id.to_int(),
      metadata: attrs.metadata(),
    })
  }
  ShapeLine::{ rtl, glyphs }
}
