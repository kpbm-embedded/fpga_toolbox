"""Summarise yosys `stat -json` files: LUT / flip-flop / carry / RAM cells per FPGA family.
Usage: python compare.py <dir with stat_<family>.json>"""
import json
import sys
from pathlib import Path

KINDS = {  # cell-name prefixes per resource class (iCE40, ECP5, Gowin, Xilinx 7, generic gates)
    "LUT": ("SB_LUT4", "LUT4", "LUT1", "LUT2", "LUT3", "LUT5", "LUT6", "$_AND_", "$_OR_", "$_XOR_", "$_NOT_", "$_MUX_",
            "$_NAND_", "$_NOR_", "$_XNOR_", "$_ANDNOT_", "$_ORNOT_", "TRELLIS_SLICE", "MUXF"),
    "FF": ("SB_DFF", "TRELLIS_FF", "FD", "DFF", "$_DFF", "$_SDFF", "$_SDFFE", "$_DFFE"),
    "carry": ("SB_CARRY", "CCU2C", "CARRY4", "ALU"),
    "RAM": ("SB_RAM", "DP16KD", "TRELLIS_DPR16X4", "RAM", "SDP", "DPB", "RAMB"),
}


def classify(cells):
    out = {k: 0 for k in KINDS}
    for name, n in cells.items():
        for kind, prefixes in KINDS.items():
            if name.startswith(prefixes):
                out[kind] += n
                break
    return out


rows = []
for f in sorted(Path(sys.argv[1]).glob("stat_*.json")):
    d = json.load(open(f))
    top = d["design"]
    cells = top.get("num_cells_by_type", {})
    rows.append((f.stem[5:], top.get("num_cells", 0), classify(cells)))
print(f"{'family':10} {'cells':>6} {'LUT/gate':>9} {'FF':>5} {'carry':>6} {'RAM':>4}")
for fam, total, c in rows:
    print(f"{fam:10} {total:6} {c['LUT']:9} {c['FF']:5} {c['carry']:6} {c['RAM']:4}")
ok = len(rows) >= 4 and all(c["LUT"] > 0 and c["FF"] > 0 for _, _, c in rows)
print("PASS synth_compare" if ok else "FAIL synth_compare: a family has no LUTs or FFs")
sys.exit(0 if ok else 1)
