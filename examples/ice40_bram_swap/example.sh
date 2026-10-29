#!/usr/bin/env bash
# about: icebram: swap the block-RAM contents of a finished iCE40 bitstream (no re-synthesis or P&R); diff proves only BRAM init changed
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
build() {
  icebram -g -s 1 8 256 >"$out/rom_old.hex"      # random placeholder content (seeded), recognisable by icebram
  yosys -q -l "$out/yosys.log" -p "read_verilog -DROM_HEX=\"$out/rom_old.hex\" top.v; synth_ice40 -top top -json $out/top.json"
  nextpnr-ice40 --up5k --package sg48 --freq 12 --pcf icebreaker.pcf --json "$out/top.json" --asc "$out/top.asc" -l "$out/nextpnr.log" -q
  icepack "$out/top.asc" "$out/top.bin"
  echo "built $out/top.bin with the placeholder ROM"
}
swap() {
  python - "$out/rom_new.hex" <<'PY'
import math, sys
with open(sys.argv[1], "w") as f:   # new content: one sine period, 8 bit
    for i in range(256):
        f.write(f"{int(127.5 + 127.5 * math.sin(2 * math.pi * i / 256)):02x}\n")
PY
  local t0; t0=$(date +%s%N)
  icebram "$out/rom_old.hex" "$out/rom_new.hex" <"$out/top.asc" >"$out/top_new.asc"
  icepack "$out/top_new.asc" "$out/top_new.bin"
  echo "icebram + icepack: $(( ($(date +%s%N) - t0) / 1000000 )) ms (no synthesis, no place and route)"
  # every differing line must lie inside a .ram_data block
  python - "$out/top.asc" "$out/top_new.asc" <<'PY'
import sys
def blocks(path):
    out, sect = [], None
    for line in open(path):
        if line.startswith("."):
            sect = line.split()[0]
        out.append((sect, line))
    return out
a, b = blocks(sys.argv[1]), blocks(sys.argv[2])
assert len(a) == len(b), "line count changed"
diff = [(sa, la, lb) for (sa, la), (_, lb) in zip(a, b) if la != lb]
bad = [d for d in diff if d[0] != ".ram_data"]
print(f"{len(diff)} lines differ, all inside .ram_data blocks" if not bad else f"FAIL: {len(bad)} changes outside BRAM")
sys.exit(1 if bad or not diff else 0)
PY
}
case "$act" in
  build) build ;;
  run|test) build; swap | tee "$out/run.log"; cmp -s "$out/top.bin" "$out/top_new.bin" && exit 1; echo "PASS ice40_bram_swap" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
