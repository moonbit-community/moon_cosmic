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
| PARITY-001 | `cosmic-text-reference/src/shape.rs` (`shape_fallback`/`shape_run`) | Advanced shaping backend is not 1:1: upstream uses `harfrust/harfbuzz`, while current implementation is on `moon_swash::shape`; complex-script substitutions/positioning may diverge on edge cases. | `DONE` | Fixed in `src/shape.mbt` by adding HarfBuzz shaping path (`moonbit-community/harfbuzz@0.1.0`) with run-relative cluster mapping and end-range alignment; font source bytes/index are wired via `src/font.mbt`. Validated with `moon fmt && moon check && moon test` (168/168 passed). |
| PARITY-002 | `cosmic-text-reference/src/shape.rs:899-965` | Missing upstream ligature-break guard around linebreak opportunities (punctuation pair probe like `|>`, `!=`, `->`) before splitting segments. | `TODO` | Current code path (`src/segment.mbt` + layout/shape flow) performs UAX#14-style boundary split and trailing-whitespace split, but does not execute the upstream probe shaping check at break boundaries. |
| PARITY-003 | `cosmic-text-reference/src/font/fallback/mod.rs` (`FontFallbackIter`) | Fallback selection pipeline is still simplified versus upstream iterator semantics (script extension timing, per-font iteration behavior, and missing-check flow). | `TODO` | Current logic is mainly in `src/font.mbt` (`font_matches_for_scripts`) and `src/shape.mbt` (`reorder_monospace_fallback_candidates`); parity tests exist, but full iterator-equivalence matrix is not yet ported. |
| PARITY-004 | `cosmic-text-reference/src/font/fallback/{unix,macos,windows}.rs` + target-specific selection | Platform fallback profile selection differs: upstream uses target-specific fallback implementation; current code infers profile heuristically from installed fonts. | `TODO` | Current implementation in `src/font.mbt` (`detect_fallback_profile`) can choose different profile ordering under mixed/custom font environments; needs direct target/explicit-profile alignment. |
| PARITY-005 | `cosmic-text-reference/src/shape.rs` + `unicode_linebreak::linebreaks` behavior surface | No full conformance harness against upstream `unicode_linebreak` vectors; current tests are representative but not exhaustive for all UAX#14 classes. | `BLOCKED_PLATFORM` | Limitation: no direct MoonBit `unicode_linebreak` package in current dependency set for 1:1 API-level parity harness. Out-of-scope workaround: avoid introducing ad-hoc heuristic tables in `moon_cosmic`; keep behavior on `moon_swash` analyzer plus explicit regression cases. |

## Current Work Queue

1. PARITY-002
2. PARITY-003
3. PARITY-004
