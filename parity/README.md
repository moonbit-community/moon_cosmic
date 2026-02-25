# Parity Differential Testing

This directory contains a strict logic-level parity diff harness between:

- `cosmic-text-reference` (`parity/reference_dump`)
- `moon_cosmic` (`src/parity_dump`)

Both dump tools use the same synthetic minimal fonts and test cases, then `diff.py` compares:

- shaping records (`SHAPE`, `SG`)
- layout records (`LL`, `LG`)
- physical cache key fields and image existence (`LG.ck_*`, `LG.img`)

## Run

```bash
python3 parity/diff.py
```

The script returns non-zero on mismatch and prints the first diff entries.
