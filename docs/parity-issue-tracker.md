# Moon Cosmic Parity Issue Tracker

Last updated: 2026-03-30

## Status Legend

- `TODO`: not started
- `IN_PROGRESS`: currently being fixed
- `BLOCKED_PLATFORM`: blocked by platform/public API limitations or external dependency constraints
- `DONE`: fixed and verified locally

## Issues

| ID | Source | Problem | Status | Notes |
| --- | --- | --- | --- | --- |
| PARITY-001 | `cosmic-text-reference/src/shape.rs` (`shape_fallback`/`shape_run`) | Advanced shaping backend is not 1:1: upstream uses `harfrust/harfbuzz`, while current implementation is on `moon_swash::shape`; complex-script substitutions/positioning may diverge on edge cases. | `DONE` | Fixed in `src/shape.mbt` by adding HarfBuzz shaping path (`moonbit-community/harfbuzz@0.1.0`) with run-relative cluster mapping and end-range alignment; font source bytes/index are wired via `src/font.mbt`. Validated with `moon info && moon fmt && moon check && moon test` (177/177 passed). |
| PARITY-002 | `cosmic-text-reference/src/shape.rs:899-965` | Missing upstream ligature-break guard around linebreak opportunities (punctuation pair probe like `|>`, `!=`, `->`) before splitting segments. | `DONE` | Fixed in `src/linebreak/linebreak.mbt` (`is_ligature_guard_pair`, `linebreaks`, `wrap_word_segments`) and routed by `src/segment.mbt`. Validated by updated boundary tests in `src/segment_test.mbt` and full `moon check && moon test` (177/177 passed). |
| PARITY-003 | `cosmic-text-reference/src/font/fallback/mod.rs` (`FontFallbackIter`) | Fallback selection pipeline is still simplified versus upstream iterator semantics (script extension timing, per-font iteration behavior, and missing-check flow). | `IN_PROGRESS` | Fallback tables and profile APIs were extracted to `src/font_fallback/fallback.mbt`; `src/font.mbt` now delegates table lookups and supports explicit profile override, but full iterator-equivalent state machine is not yet ported. |
| PARITY-004 | `cosmic-text-reference/src/font/fallback/{unix,macos,windows}.rs` + target-specific selection | Platform fallback profile selection differs from upstream target-specific compilation split. | `IN_PROGRESS` | Heuristic runtime detection was removed. `src/font_fallback/fallback.mbt` now exposes `platform_default_fallback_profile`, and `src/font.mbt` supports explicit override (`set_fallback_profile`, `clear_fallback_profile`). Remaining gap: native default currently maps to Unix due coarse MoonBit target cfg granularity. |
| PARITY-005 | `cosmic-text-reference/src/shape.rs` + `unicode_linebreak::linebreaks` behavior surface | No full conformance harness against upstream `unicode_linebreak` vectors; current tests are representative but not exhaustive for all UAX#14 classes. | `BLOCKED_PLATFORM` | Limitation: no direct MoonBit `unicode_linebreak` package in current dependency set for 1:1 API-level parity harness. Out-of-scope workaround remains explicit regression cases on `moon_swash` analyzer behavior. |
| PARITY-006 | `cosmic-text-reference/src/edit/vi.rs` | `edit_vi` behavior is still subset-only: no full parser/event model parity (registers/text-objects/search/motion variants) relative to upstream `modit` flow. | `IN_PROGRESS` | `src/edit_vi/vi.mbt` now includes changed/save-point/undo-redo, passthrough, `/` search input + `n/N`, line-find motions `f/F/t/T`, basic register flow (`yy/p`), and text-object operator path (`diw/ciw/yiw`, bracket/quote objects). Validated by expanded `src/edit_vi/vi_test.mbt` and full `moon info && moon fmt && moon check && moon test` (183/183 passed). Remaining gap: full `modit` parser/event parity (multi-register behavior, complete text-object/search variants, and full motion matrix). |
| PARITY-007 | `cosmic-text-reference/src/edit/syntect.rs` | `edit_syntect` currently uses an internal tokenizer, not upstream syntect grammar/state engine parity (scope stack/highlighter behavior). | `BLOCKED_PLATFORM` | Blocked until a usable MoonBit `syntect`/equivalent dependency surface is available; per current decision this item is deferred and no further implementation work will be done before unblocked. Current local layer in `src/edit_syntect/syntect.mbt` remains functional but non-1:1. |
| PARITY-008 | `cosmic-text-reference/src/edit/mod.rs` + `src/edit/editor.rs` integration | Main package compatibility surface for `SyntaxEditor`/`ViEditor` integration differs from upstream trait-based edit layering. | `TODO` | Internal subpackages exist and compile with tests, but root package API wiring still differs from upstream structure. |
| PARITY-009 | MoonBit registry dependency surface | No registry package currently available for direct parity reuse of upstream parser/highlighter engines (`modit`, `syntect`). | `BLOCKED_PLATFORM` | Verified by failed dependency resolution commands: `moon add moonbit-community/modit@0.1.0` and `moon add moonbit-community/syntect@0.1.0` (module not found in registry). Current strategy remains in-repo internal subpackage implementation. |

## Current Work Queue

1. PARITY-006
2. PARITY-003
3. PARITY-008
4. PARITY-004
5. PARITY-009
6. PARITY-007
7. PARITY-005
