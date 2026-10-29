#!/usr/bin/env bash
# about: one RTL block (UART, SPI, FIFO, PWM) synthesised by yosys for iCE40, ECP5, Gowin, Xilinx 7 and generic gates: LUT/FF/carry/RAM table, no latches (synthesis only)
set -euo pipefail
act=${1:-test}; out=${EX_OUT:?run through ./fpga-box examples}
export PYTHONDONTWRITEBYTECODE=1
rtl=(../common/rtl/uart_tx.v ../common/rtl/uart_rx.v ../common/rtl/spi_master.v ../common/rtl/sync_fifo.v ../common/rtl/pwm.v periph.v)
declare -A synth=([ice40]="synth_ice40" [ecp5]="synth_ecp5" [gowin]="synth_gowin" [xc7]="synth_xilinx -family xc7" [generic]="synth")
build() {
  local fam
  for fam in "${!synth[@]}"; do
    yosys -q -l "$out/yosys_$fam.log" -p "read_verilog -sv ${rtl[*]}; ${synth[$fam]} -top periph
      select -assert-none t:\$dlatch t:\$_DLATCH_*; tee -q -o $out/stat_$fam.json stat -json" >/dev/null
  done
  echo "synthesised for ${!synth[*]}"
}
case "$act" in
  build) build ;;
  run|test) build; python compare.py "$out" | tee "$out/run.log"; grep -q '^PASS' "$out/run.log" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac
