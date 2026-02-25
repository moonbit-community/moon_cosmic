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

use cosmic_text::{
    fontdb, Attrs, AttrsList, Hinting, ShapeGlyph, ShapeLine, Shaping, SwashCache, Weight, Wrap,
};

#[derive(Clone, Copy)]
struct ParityCase {
    id: &'static str,
    text: &'static str,
    wrap: Wrap,
    width_opt: Option<f32>,
}

fn mk_cases() -> Vec<ParityCase> {
    vec![
        ParityCase {
            id: "ascii_sentence",
            text: "Move the mouse to see the circle follow your cursor.",
            wrap: Wrap::None,
            width_opt: None,
        },
        ParityCase {
            id: "ascii_tabs",
            text: "A\tB\tC",
            wrap: Wrap::None,
            width_opt: None,
        },
        ParityCase {
            id: "mix_hebrew",
            text: "Many computer programs fail to display bidirectional text correctly: שרה",
            wrap: Wrap::None,
            width_opt: None,
        },
        ParityCase {
            id: "mix_arabic",
            text: "I like to render اللغة العربية in Rust!",
            wrap: Wrap::None,
            width_opt: None,
        },
        ParityCase {
            id: "wrap_word_or_glyph",
            text: "Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.",
            wrap: Wrap::WordOrGlyph,
            width_opt: Some(50.0),
        },
        ParityCase {
            id: "wrap_word",
            text: "אב abc def",
            wrap: Wrap::Word,
            width_opt: Some(30.0),
        },
    ]
}

fn bool01(v: bool) -> &'static str {
    if v {
        "1"
    } else {
        "0"
    }
}

fn wrap_name(wrap: Wrap) -> &'static str {
    match wrap {
        Wrap::None => "None",
        Wrap::Glyph => "Glyph",
        Wrap::Word => "Word",
        Wrap::WordOrGlyph => "WordOrGlyph",
    }
}

fn width_name(width_opt: Option<f32>) -> String {
    match width_opt {
        None => "none".to_string(),
        Some(width) => format!("{width:.6}"),
    }
}

fn emit(tag: &str, fields: Vec<(&str, String)>) {
    print!("{tag}");
    for (k, v) in fields {
        print!("\t{k}={v}");
    }
    println!();
}

fn id_index(font_ids: &[fontdb::ID], id: fontdb::ID) -> i32 {
    font_ids
        .iter()
        .position(|&candidate| candidate == id)
        .map(|index| index as i32)
        .unwrap_or(-1)
}

fn flatten_shape<'a>(shape: &'a ShapeLine) -> Vec<&'a ShapeGlyph> {
    let mut glyphs = Vec::new();
    for span in &shape.spans {
        for word in &span.words {
            for glyph in &word.glyphs {
                glyphs.push(glyph);
            }
        }
    }
    glyphs
}

fn utf16_index_for_byte(text: &str, byte_index: usize) -> usize {
    let mut utf16_index = 0usize;
    for (index, ch) in text.char_indices() {
        if index >= byte_index {
            break;
        }
        utf16_index += ch.len_utf16();
    }
    utf16_index
}

fn build_font_system() -> (cosmic_text::FontSystem, Vec<fontdb::ID>) {
    let mut fs =
        cosmic_text::FontSystem::new_with_locale_and_db("en-US".into(), fontdb::Database::new());
    let mut font_ids = Vec::new();
    let font_paths = [
        "cosmic-text-reference/fonts/Inter-Regular.ttf",
        "cosmic-text-reference/fonts/NotoSans-Regular.ttf",
        "cosmic-text-reference/fonts/NotoSansHebrew.ttf",
        "cosmic-text-reference/fonts/NotoSansArabic.ttf",
    ];
    for path in font_paths {
        let data = std::fs::read(path).expect("read font file");
        let face_count_before = fs.db().len();
        fs.db_mut().load_font_data(data);
        for face in fs.db().faces().skip(face_count_before) {
            font_ids.push(face.id);
        }
    }
    (fs, font_ids)
}

fn dump_case(
    font_system: &mut cosmic_text::FontSystem,
    font_ids: &[fontdb::ID],
    parity_case: ParityCase,
) {
    let attrs = Attrs::new()
        .family(fontdb::Family::Name("Inter"))
        .weight(Weight::NORMAL);
    let attrs = AttrsList::new(&attrs);
    emit(
        "CASE",
        vec![
            ("case", parity_case.id.to_string()),
            ("wrap", wrap_name(parity_case.wrap).to_string()),
            ("width", width_name(parity_case.width_opt)),
        ],
    );

    let shape = ShapeLine::new(
        font_system,
        parity_case.text,
        &attrs,
        Shaping::Advanced,
        8,
    );
    let shape_glyphs = flatten_shape(&shape);
    emit(
        "SHAPE",
        vec![
            ("case", parity_case.id.to_string()),
            ("rtl", bool01(shape.rtl).to_string()),
            ("count", shape_glyphs.len().to_string()),
        ],
    );
    for (glyph_index, glyph) in shape_glyphs.iter().enumerate() {
        let start_utf16 = utf16_index_for_byte(parity_case.text, glyph.start);
        let end_utf16 = utf16_index_for_byte(parity_case.text, glyph.end);
        emit(
            "SG",
            vec![
                ("case", parity_case.id.to_string()),
                ("index", glyph_index.to_string()),
                ("start", start_utf16.to_string()),
                ("end", end_utf16.to_string()),
                ("font", id_index(font_ids, glyph.font_id).to_string()),
                ("glyph", glyph.glyph_id.to_string()),
                ("xa", format!("{:.6}", glyph.x_advance)),
                ("ya", format!("{:.6}", glyph.y_advance)),
                ("xo", format!("{:.6}", glyph.x_offset)),
                ("yo", format!("{:.6}", glyph.y_offset)),
                ("meta", glyph.metadata.to_string()),
            ],
        );
    }

    let layout = shape.layout(
        16.0,
        parity_case.width_opt,
        parity_case.wrap,
        None,
        None,
        Hinting::Disabled,
    );
    let mut swash_cache = SwashCache::new();
    for (line_index, line) in layout.iter().enumerate() {
        emit(
            "LL",
            vec![
                ("case", parity_case.id.to_string()),
                ("line", line_index.to_string()),
                ("w", format!("{:.6}", line.w)),
                ("count", line.glyphs.len().to_string()),
            ],
        );
        for (glyph_index, glyph) in line.glyphs.iter().enumerate() {
            let physical = glyph.physical((0.0, 0.0), 1.0);
            let cache_key = physical.cache_key;
            let has_image = swash_cache
                .get_image_uncached(font_system, physical.cache_key)
                .is_some();
            let start_utf16 = utf16_index_for_byte(parity_case.text, glyph.start);
            let end_utf16 = utf16_index_for_byte(parity_case.text, glyph.end);
            emit(
                "LG",
                vec![
                    ("case", parity_case.id.to_string()),
                    ("line", line_index.to_string()),
                    ("index", glyph_index.to_string()),
                    ("start", start_utf16.to_string()),
                    ("end", end_utf16.to_string()),
                    ("font", id_index(font_ids, glyph.font_id).to_string()),
                    ("glyph", glyph.glyph_id.to_string()),
                    ("x", format!("{:.6}", glyph.x)),
                    ("y", format!("{:.6}", glyph.y)),
                    ("w", format!("{:.6}", glyph.w)),
                    ("level", u8::from(glyph.level).to_string()),
                    ("meta", glyph.metadata.to_string()),
                    ("ck_font", id_index(font_ids, cache_key.font_id).to_string()),
                    ("ck_gid", cache_key.glyph_id.to_string()),
                    ("ck_size_bits", cache_key.font_size_bits.to_string()),
                    ("ck_x_bin", format!("{:.6}", cache_key.x_bin.as_float())),
                    ("ck_y_bin", format!("{:.6}", cache_key.y_bin.as_float())),
                    ("ck_weight", cache_key.font_weight.0.to_string()),
                    ("ck_flags", cache_key.flags.bits().to_string()),
                    ("img", bool01(has_image).to_string()),
                ],
            );
        }
    }
}

fn main() {
    let (mut font_system, font_ids) = build_font_system();
    for parity_case in mk_cases() {
        dump_case(&mut font_system, &font_ids, parity_case);
    }
}
