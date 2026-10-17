#!/bin/sh
# Синтез (Yosys + GHDL plugin), розміщення/трасування і часовий аналіз (nextpnr) для iCE40-HX8K
for M in i2c_master i2c_slave; do
  yosys -m ghdl -p "ghdl --std=08 ../src/$M.vhd -e $M; synth_ice40 -top $M -json $M.json; tee -o ${M}_ice40_stat.txt stat"
  nextpnr-ice40 --hx8k --package ct256 --json $M.json --pcf-allow-unconstrained --freq 50 --asc $M.asc -l ${M}_pnr.log
  yosys -m ghdl -p "ghdl --std=08 ../src/$M.vhd -e $M; synth_xilinx -family xc7 -top $M; tee -o ${M}_xc7_stat.txt stat"
done
