#!/bin/sh
# Компіляція та запуск симуляції у GHDL, перегляд: gtkwave tb_i2c.vcd
ghdl -a --std=08 ../src/i2c_master.vhd ../src/i2c_slave.vhd ../tb/tb_i2c.vhd
ghdl -e --std=08 tb_i2c
ghdl -r --std=08 tb_i2c --vcd=tb_i2c.vcd
