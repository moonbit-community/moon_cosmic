#!/usr/bin/env python3
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Dict, List


ROOT = Path(__file__).resolve().parent.parent
EPS = 1e-4

TAG_SPECS = {
    "CASE": {"str": ["family", "wrap"], "int": [], "float": ["font_size"]},
    "SHAPE": {"str": ["rtl"], "int": ["count"], "float": []},
    "SG": {
        "str": [],
        "int": ["index", "start", "end", "font", "glyph", "meta"],
        "float": ["xa", "ya", "xo", "yo"],
    },
    "LL": {
        "str": [],
        "int": ["line", "count"],
        "float": ["w"],
    },
    "LG": {
        "str": ["img"],
        "int": [
            "line",
            "index",
            "start",
            "end",
            "font",
            "glyph",
            "level",
            "meta",
            "ck_font",
            "ck_gid",
            "ck_size_bits",
            "ck_weight",
            "ck_flags",
        ],
        "float": ["x", "y", "w", "ck_x_bin", "ck_y_bin"],
    },
}


def run_cmd(cmd: List[str]) -> str:
    result = subprocess.run(
        cmd,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        sys.stderr.write(f"command failed: {' '.join(cmd)}\n")
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode)
    return result.stdout


def parse_dump(raw: str) -> Dict[str, Dict[str, List[Dict[str, str]]]]:
    cases: Dict[str, Dict[str, List[Dict[str, str]]]] = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        tag = parts[0]
        if tag not in TAG_SPECS:
            continue
        fields: Dict[str, str] = {}
        for part in parts[1:]:
            if "=" not in part:
                continue
            key, value = part.split("=", 1)
            fields[key] = value
        case_id = fields.get("case")
        if case_id is None:
            continue
        case_store = cases.setdefault(case_id, {})
        tag_store = case_store.setdefault(tag, [])
        tag_store.append(fields)
    return cases


def compare_records(
    case_id: str,
    tag: str,
    lhs: Dict[str, str],
    rhs: Dict[str, str],
    mismatches: List[str],
) -> None:
    spec = TAG_SPECS[tag]
    for key in spec["str"]:
        lv = lhs.get(key)
        rv = rhs.get(key)
        if lv != rv:
            mismatches.append(f"{case_id}.{tag}.{key}: ref={lv!r} moon={rv!r}")
    for key in spec["int"]:
        lv = lhs.get(key)
        rv = rhs.get(key)
        try:
            li = int(lv) if lv is not None else None
            ri = int(rv) if rv is not None else None
        except ValueError:
            mismatches.append(f"{case_id}.{tag}.{key}: parse-int failed ref={lv!r} moon={rv!r}")
            continue
        if li != ri:
            mismatches.append(f"{case_id}.{tag}.{key}: ref={li} moon={ri}")
    for key in spec["float"]:
        lv = lhs.get(key)
        rv = rhs.get(key)
        try:
            lf = float(lv) if lv is not None else None
            rf = float(rv) if rv is not None else None
        except ValueError:
            mismatches.append(
                f"{case_id}.{tag}.{key}: parse-float failed ref={lv!r} moon={rv!r}"
            )
            continue
        if lf is None or rf is None:
            mismatches.append(f"{case_id}.{tag}.{key}: missing value ref={lv!r} moon={rv!r}")
            continue
        if abs(lf - rf) > EPS:
            mismatches.append(f"{case_id}.{tag}.{key}: ref={lf} moon={rf}")
    if tag == "CASE":
        lw = lhs.get("width")
        rw = rhs.get("width")
        if lw is None or rw is None:
            mismatches.append(f"{case_id}.{tag}.width: missing value ref={lw!r} moon={rw!r}")
            return
        if lw == "none" and rw == "none":
            return
        if lw == "none" or rw == "none":
            mismatches.append(f"{case_id}.{tag}.width: ref={lw!r} moon={rw!r}")
            return
        try:
            lf = float(lw)
            rf = float(rw)
        except ValueError:
            mismatches.append(
                f"{case_id}.{tag}.width: parse-float failed ref={lw!r} moon={rw!r}"
            )
            return
        if abs(lf - rf) > EPS:
            mismatches.append(f"{case_id}.{tag}.width: ref={lf} moon={rf}")


def compare(ref: Dict[str, Dict[str, List[Dict[str, str]]]], moon: Dict[str, Dict[str, List[Dict[str, str]]]]) -> List[str]:
    mismatches: List[str] = []

    ref_cases = set(ref.keys())
    moon_cases = set(moon.keys())
    if ref_cases != moon_cases:
        only_ref = sorted(ref_cases - moon_cases)
        only_moon = sorted(moon_cases - ref_cases)
        if only_ref:
            mismatches.append(f"cases only in reference: {only_ref}")
        if only_moon:
            mismatches.append(f"cases only in moon: {only_moon}")

    for case_id in sorted(ref_cases & moon_cases):
        ref_tags = ref[case_id]
        moon_tags = moon[case_id]
        for tag in TAG_SPECS:
            ref_list = ref_tags.get(tag, [])
            moon_list = moon_tags.get(tag, [])
            if len(ref_list) != len(moon_list):
                mismatches.append(
                    f"{case_id}.{tag}: record-count ref={len(ref_list)} moon={len(moon_list)}"
                )
                continue
            for i, (lhs, rhs) in enumerate(zip(ref_list, moon_list)):
                compare_records(case_id, tag, lhs, rhs, mismatches)
                if mismatches and len(mismatches) > 500:
                    mismatches.append("too many mismatches, truncated")
                    return mismatches
    return mismatches


def main() -> int:
    ref_raw = run_cmd(
        [
            "cargo",
            "run",
            "--quiet",
            "--manifest-path",
            str(ROOT / "parity/reference_dump/Cargo.toml"),
        ]
    )
    moon_raw = run_cmd(["moon", "run", "src/parity_dump"])

    ref = parse_dump(ref_raw)
    moon = parse_dump(moon_raw)
    mismatches = compare(ref, moon)

    if mismatches:
        print("parity diff: FOUND mismatches")
        for line in mismatches[:200]:
            print(f"- {line}")
        if len(mismatches) > 200:
            print(f"... ({len(mismatches) - 200} more)")
        return 1

    case_count = len(ref.keys())
    print(f"parity diff: OK ({case_count} cases, eps={EPS})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
